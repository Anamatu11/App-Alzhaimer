import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ MAPA - Dependencias necesarias
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ✅ PERFIL - Pantalla de perfil
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final mqttService = MqttService();
  final MapController _mapController = MapController();
  String nombrePaciente = "Paciente";
  String pacienteId = "";
  DateTime? ultimaLecturaGuardada;
  int _selectedIndex = 0;

  double axActual = 0;
  double ayActual = 0;
  double azActual = 0;

  double gxActual = 0;
  double gyActual = 0;
  double gzActual = 0;

  int pulso = 0;
  int spo2 = 0;
  bool dedo = false;

  double lat = 0;
  double lng = 0;

  String direccion = "Cargando...";
  String ubicacion = "En casa";
  String actividad = "Movimiento";

  final List<int> _irBuffer = [];
  final List<int> _redBuffer = [];
  int _fallTimer = 0;

  @override
  void initState() {
    super.initState();

    _cargarNombrePaciente();

    mqttService.onData = (data) async {
      _procesarDatosMqtt(data);
    };

    mqttService.connect();
  }
////////////////////////////////////////////////////////////
//// FIREBASE - Cargar nombre del paciente basado en el cuidador actual
Future<void> guardarLecturaFirebase() async {
  try {
    if (ultimaLecturaGuardada != null &&
        DateTime.now()
                .difference(ultimaLecturaGuardada!)
                .inSeconds <
            30) {
      return;
    }

    ultimaLecturaGuardada = DateTime.now();

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(pacienteId)
        .collection('lecturas')
        .add({
      'pacienteId': pacienteId,
      'pacienteNombre': nombrePaciente,
      'bpm': pulso,
      'spo2': spo2,
      'actividad': actividad,
      'ax': axActual,
      'ay': ayActual,
      'az': azActual,
      'gx': gxActual,
      'gy': gyActual,
      'gz': gzActual,
      'lat': lat,
      'lng': lng,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("✅ Lectura guardada en Firebase");
  } catch (e) {
    print("❌ Error guardando lectura: $e");
  }
}

//////////////////////////////////////////////////////////
Future<void> _cargarNombrePaciente() async {
  try {
    final correo = FirebaseAuth.instance.currentUser?.email;

    if (correo == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('usuarios').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data['cuidadores'] != null) {
        List cuidadores = data['cuidadores'];

        bool esCuidador = cuidadores.any(
          (c) => c['correo'] == correo,
        );

        if (esCuidador) {
          setState(() {
            nombrePaciente = data['nombre'] ?? 'Paciente';
            pacienteId = doc.id;
          });
           print("Paciente encontrado: $pacienteId");
          return;
        }
      }
    }
  } catch (e) {
    print('Error cargando nombre del paciente: $e');
  }
}


  void _procesarDatosMqtt(dynamic data) {
    if (data == null || data is! Map) return;

    try {
      axActual = double.tryParse(data['ax']?.toString() ?? "0") ?? 0;
      ayActual = double.tryParse(data['ay']?.toString() ?? "0") ?? 0;
      azActual = double.tryParse(data['az']?.toString() ?? "0") ?? 0;

      _calcularPostura(axActual, ayActual, azActual);


      gxActual = double.tryParse(data['gx']?.toString() ?? "0") ?? 0;
      gyActual = double.tryParse(data['gy']?.toString() ?? "0") ?? 0;
      gzActual = double.tryParse(data['gz']?.toString() ?? "0") ?? 0;

    
      int ir = int.tryParse(data['ir']?.toString() ?? "0") ?? 0;
      int red = int.tryParse(data['red']?.toString() ?? "0") ?? 0;

      bool isDedo = false;
      if (data['finger'] != null) {
        if (data['finger'] is bool) {
          isDedo = data['finger'];
        } else if (data['finger'].toString().toLowerCase() == "true") {
          isDedo = true;
        }
      }

      _procesarMax30102(ir, red, isDedo);

      double newLat = double.tryParse(data['lat']?.toString() ?? "0") ?? 0;
      double newLng = double.tryParse(data['lng']?.toString() ?? "0") ?? 0;

      if (newLat != 0 && newLng != 0 && (newLat != lat || newLng != lng)) {
        lat = newLat;
        lng = newLng;

        // ✅ MAPA - Mover la cámara del mapa a la nueva posición GPS
        _mapController.move(LatLng(lat, lng), 15);

        obtenerDireccion();
      } else if (newLat == 0 && newLng == 0) {
        if (direccion != "Buscando señal GPS...") {
          setState(() => direccion = "Buscando señal GPS...");
        }
      }
    } catch (e) {
      print("Error parseando JSON MQTT en HomeScreen: $e");
    }
  }

  void _calcularPostura(double ax, double ay, double az) {
    double magnitudSq = (ax * ax) + (ay * ay) + (az * az);

    if (magnitudSq > 15000) {
      _fallTimer = 90;
      if (actividad != "¡CAÍDA DETECTADA!") {
        setState(() => actividad = "¡CAÍDA DETECTADA!");
      }
      return;
    }

    if (_fallTimer > 0) {
      _fallTimer--;
      return;
    }

    String nuevaActividad = "Movimiento";
    if (ay.abs() > ax.abs() && ay.abs() > az.abs()) {
      nuevaActividad = "De pie / Caminando";
    } else if (ax.abs() > ay.abs() && ax.abs() > az.abs()) {
      nuevaActividad = "Acostado (Lado)";
    } else if (az.abs() > ay.abs() && az.abs() > ax.abs()) {
      nuevaActividad = "Acostado (Boca arriba/abajo)";
    }

    if (nuevaActividad != actividad) {
      setState(() => actividad = nuevaActividad);
    }
  }

  void _procesarMax30102(int ir, int red, bool isDedo) {
    if (!isDedo || ir < 2000) {
      _irBuffer.clear();
      _redBuffer.clear();
      if (dedo != false || pulso != 0) {
        setState(() {
          dedo = false;
          pulso = 0;
          spo2 = 0;
        });
      }
      return;
    }

    if (!dedo) setState(() => dedo = true);

    _irBuffer.add(ir);
    _redBuffer.add(red);

    if (_irBuffer.length > 120) {
      _irBuffer.removeAt(0);
      _redBuffer.removeAt(0);
    }

    if (_irBuffer.length == 120) {
      _calcularBpmYSpO2();
      guardarLecturaFirebase();
    }
  }

  void _calcularBpmYSpO2() {
    List<double> irSuavizado = [];
    for (int i = 2; i < _irBuffer.length - 2; i++) {
      double prom = (_irBuffer[i - 2] +
              _irBuffer[i - 1] +
              _irBuffer[i] +
              _irBuffer[i + 1] +
              _irBuffer[i + 2]) /
          5;
      irSuavizado.add(prom);
    }

    double meanIr = irSuavizado.reduce((a, b) => a + b) / irSuavizado.length;
    double threshold = meanIr + 50;

    int latidos = 0;
    bool subiendo = false;
    for (int i = 0; i < irSuavizado.length; i++) {
      if (irSuavizado[i] > threshold && !subiendo) {
        subiendo = true;
        latidos++;
      } else if (irSuavizado[i] < meanIr) {
        subiendo = false;
      }
    }

    int estimadoBpm = latidos * 15;
    if (estimadoBpm > 0 && estimadoBpm < 60) {
      estimadoBpm = (estimadoBpm * 1.5).toInt();
    }

    int minRed = _redBuffer.reduce((a, b) => a < b ? a : b);
    int maxRed = _redBuffer.reduce((a, b) => a > b ? a : b);

    double dcIr = _irBuffer.reduce((a, b) => a + b) / _irBuffer.length;
    double acIr = (irSuavizado.reduce((a, b) => a > b ? a : b) -
            irSuavizado.reduce((a, b) => a < b ? a : b))
        .toDouble();

    double dcRed = _redBuffer.reduce((a, b) => a + b) / _redBuffer.length;
    double acRed = (maxRed - minRed).toDouble();

    double ratio = 0;
    if (dcIr > 0 && dcRed > 0 && acIr > 0) {
      ratio = (acRed / dcRed) / (acIr / dcIr);
    }

    int estimadoSpO2 = (110 - 25 * ratio).toInt();
    if (estimadoSpO2 > 100) estimadoSpO2 = 100;
    if (estimadoSpO2 < 85 && ratio > 0) {
      estimadoSpO2 = 85 + (estimadoSpO2 % 10);
    }

    if ((estimadoBpm > 40 && estimadoBpm < 220) || pulso == 0) {
      setState(() {
        if (estimadoBpm > 40) pulso = estimadoBpm;
        if (estimadoSpO2 > 60) spo2 = estimadoSpO2;
      });
    }
  }

  Future<void> obtenerDireccion() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;
      setState(() {
        direccion = "${place.street}, ${place.locality}";
      });
    } catch (e) {
      setState(() {
        direccion = "Ubicación no disponible";
      });
    }
  }

  Color _colorPulso() {
    if (pulso < 60) return const Color(0xFF1A237E);
    if (pulso < 100) return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/transparente.png',
              height: 50,
            ),
            const SizedBox(width: 12),
            Image.asset(
              'assets/logoAxis.png',
              height: 32,
            ),
          ],
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Estable",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildInicioScreen()
          : _selectedIndex == 1
              ? _buildAlertasScreen()
              : _buildAjustesScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF1A237E)),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Color(0xFF1A237E)),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Color(0xFF1A237E)),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  // 🏠 PANTALLA DE INICIO
  Widget _buildInicioScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 👤 USUARIO
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: const AssetImage('assets/juanperez.jpg'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombrePaciente,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Paciente",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ❤️ SIGNOS VITALES
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Signos Vitales",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "En tiempo real",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: const Color(0xFF1A237E),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (pulso > 0) ? "$pulso" : "--",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: _colorPulso(),
                                  ),
                                ),
                                const Text("BPM",
                                    style: TextStyle(color: Colors.grey, fontSize: 10)),
                                const SizedBox(height: 8),
                                const Text("Ritmo Cardíaco",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Container(
                              width: 1, height: 100, color: Colors.grey[300]),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: const Color(0xFF1A237E),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (spo2 > 0) ? "$spo2" : "--",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                const Text("% SpO₂",
                                    style: TextStyle(color: Colors.grey, fontSize: 10)),
                                const SizedBox(height: 8),
                                const Text("Oxígeno en Sangre",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: const Color(0xFF1A237E).withOpacity(0.7), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dedo
                                    ? "Midiendo correctamente"
                                    : "Lectura inestable — coloca el dedo en el sensor",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF1A237E).withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 📍 UBICACIÓN
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ubicación",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Última actualización: ahora",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.home, color: Color(0xFF1A237E), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ubicacion,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  direccion,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ MAPA
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: const MapOptions(
                      initialCenter: LatLng(4.6097, -74.0817),
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: "com.example.parche_iot_app",
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🚶 ACTIVIDAD
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_run,
                              color: Color(0xFF1A237E), size: 24),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Actividad",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actividad,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🔔 PANTALLA DE ALERTAS
  Widget _buildAlertasScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Alertas",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Aquí aparecerán los alertas del modelo de IA",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ⚙️ PANTALLA DE AJUSTES / PERFIL
  Widget _buildAjustesScreen() {
    return const ProfileScreen();
  }

}
