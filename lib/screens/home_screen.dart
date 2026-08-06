import 'dart:async';
import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// MAPA - Dependencias necesarias
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// PERFIL - Pantalla de perfil
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
  String fotoUrl = "";
  DateTime? ultimaLecturaGuardada;
  int _selectedIndex = 0;

 // 🔔 DEMOSTRACIÓN DE RIESGO MERD
  String _nivelRiesgoDemo = "Bajo";
  
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

  DateTime? _ultimoMensajeMqtt;
  Timer? _estadoConexionTimer;
  bool dispositivoConectado = false;

  @override
  void initState() {
    super.initState();

    _cargarNombrePaciente();

    mqttService.onData = (data) async {
      _ultimoMensajeMqtt = DateTime.now();
      _actualizarEstadoConexion();
      _procesarDatosMqtt(data);
    };

    mqttService.connect();

    _estadoConexionTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _actualizarEstadoConexion();
    });
  }

  @override
  void dispose() {
    _estadoConexionTimer?.cancel();
    super.dispose();
  }

  void _actualizarEstadoConexion() {
    bool nuevoEstado;

    if (_ultimoMensajeMqtt == null) {
      nuevoEstado = false;
    } else {
      final segundos =
          DateTime.now().difference(_ultimoMensajeMqtt!).inSeconds;
      nuevoEstado = segundos <= 15;
    }

    if (nuevoEstado != dispositivoConectado) {
      setState(() => dispositivoConectado = nuevoEstado);
    }
  }
////////////////////////////////////////////////////////////
//// FIREBASE - Cargar nombre del paciente basado en el cuidador actual
Future<void> guardarLecturaFirebase() async {
  try {
    if (ultimaLecturaGuardada != null &&
        DateTime.now()
                .difference(ultimaLecturaGuardada!)
                .inSeconds < 15) {
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

    debugPrint("✅ Lectura guardada en Firebase");
  } catch (e) {
    debugPrint("❌ Error guardando lectura: $e");
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
            fotoUrl = data['fotoUrl'] ?? '';
          });
           debugPrint("Paciente encontrado: $pacienteId");
          return;
        }
      }
    }
  } catch (e) {
    debugPrint('Error cargando nombre del paciente: $e');
  }
}


  void _procesarDatosMqtt(dynamic data) {
    if (data == null || data is! Map) return;

    try {

    debugPrint("📨 MQTT recibido: $data");

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
      guardarLecturaFirebase();
    } catch (e) {
      debugPrint("Error parseando JSON MQTT en HomeScreen: $e");
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

      setState(() {
        dedo = false;
      });

      return;
    }

    if (!dedo) {
      setState(() {
        dedo = true;
      });
    }

    _irBuffer.add(ir);
    _redBuffer.add(red);

    if (_irBuffer.length > 120) {
      _irBuffer.removeAt(0);
      _redBuffer.removeAt(0);
    }

    if (_irBuffer.length == 120) {
      _calcularBpmYSpO2();
    }
  }

/////////////////////////////////////////////////////////////////
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
    ///////////// se calcula el umbral dinámico para detección de picos basado en la amplitud de la señal
    double maxIr = irSuavizado.reduce((a, b) => a > b ? a : b);
    double minIr = irSuavizado.reduce((a, b) => a < b ? a : b);
    double amplitud = maxIr - minIr;
    double threshold = meanIr + (amplitud * 0.25);


   int latidos = 0;

    for (int i = 1; i < irSuavizado.length - 1; i++) {
      if (irSuavizado[i] > threshold &&
          irSuavizado[i] > irSuavizado[i - 1] &&
          irSuavizado[i] > irSuavizado[i + 1]) {
        latidos++;
      }
    }

    debugPrint("Latidos detectados: $latidos");

    int estimadoBpm = latidos * 22;
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

    /////////////////////////
    int estimadoSpO2 = (104 - (17 * ratio)).round();
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
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dispositivoConectado
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFFDEAEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            dispositivoConectado ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dispositivoConectado ? "Parche Conectado" : "Parche Desconectado",
                      style: TextStyle(
                        color: dispositivoConectado
                            ? const Color(0xFF1E7E34)
                            : const Color(0xFFB00020),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
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
                      backgroundImage:
                          fotoUrl.isNotEmpty
                              ? AssetImage('assets/$fotoUrl')
                              : null,
                      child: fotoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
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

// ============================================================
// 🔔 PANTALLA DE ALERTAS - CUIDADOR
// ============================================================

Widget _buildAlertasScreen() {
  final String nivel = _nivelRiesgoDemo;

  Color colorRiesgo;
  IconData iconoRiesgo;
  String tituloRiesgo;
  String descripcionRiesgo;

  // ==========================================================
  // 🟢 RIESGO BAJO
  // ==========================================================

  if (nivel == "Bajo") {
    colorRiesgo = Colors.green;
    iconoRiesgo = Icons.check_circle_outline;

    tituloRiesgo = "Riesgo bajo";

    descripcionRiesgo =
        "No se ha detectado un nivel de riesgo que requiera atención en este momento.";
  }

  // ==========================================================
  // 🟠 RIESGO MEDIO
  // ==========================================================

  else if (nivel == "Medio") {
    colorRiesgo = Colors.orange;
    iconoRiesgo = Icons.warning_amber_rounded;

    tituloRiesgo = "Riesgo medio";

    descripcionRiesgo =
        "Se ha detectado un nivel de riesgo medio de desorientación espacial. Se recomienda prestar atención al estado y comportamiento reciente del paciente.";
  }

  // ==========================================================
  // 🔴 RIESGO ALTO
  // ==========================================================

  else {
    colorRiesgo = Colors.red;
    iconoRiesgo = Icons.warning_rounded;

    tituloRiesgo = "Riesgo alto";

    descripcionRiesgo =
        "Se ha detectado un nivel de riesgo alto de desorientación espacial. Se recomienda verificar el estado y la ubicación del paciente.";
  }

  return SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // ==================================================
          // TÍTULO
          // ==================================================

          const Text(
            "Alertas",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "Estado del riesgo de desorientación espacial",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 18),

          // ==================================================
          // MODO DEMOSTRACIÓN
          // ==================================================

          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 4,
            ),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(14),

              border: Border.all(
                color: const Color(0xFF1A237E)
                    .withOpacity(0.15),
              ),
            ),

            child: Row(
              children: [

                const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF1A237E),
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    "Modo demostración",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _nivelRiesgoDemo,

                    items: const [

                      DropdownMenuItem(
                        value: "Bajo",
                        child: Text(
                          "🟢 Bajo",
                        ),
                      ),

                      DropdownMenuItem(
                        value: "Medio",
                        child: Text(
                          "🟠 Medio",
                        ),
                      ),

                      DropdownMenuItem(
                        value: "Alto",
                        child: Text(
                          "🔴 Alto",
                        ),
                      ),
                    ],

                    onChanged: (valor) {

                      if (valor == null) {
                        return;
                      }

                      setState(() {
                        _nivelRiesgoDemo = valor;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            "El selector permite visualizar los tres escenarios definidos por MERD.",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 22),

          // ==================================================
          // TARJETA PRINCIPAL DE RIESGO
          // ==================================================

          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(18),

              border: Border.all(
                color:
                    colorRiesgo.withOpacity(0.35),
                width: 1.2,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.06),

                  blurRadius: 8,

                  offset:
                      const Offset(0, 3),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(
                  children: [

                    Container(
                      width: 52,
                      height: 52,

                      decoration:
                          BoxDecoration(
                        color:
                            colorRiesgo
                                .withOpacity(0.12),

                        shape:
                            BoxShape.circle,
                      ),

                      child: Icon(
                        iconoRiesgo,

                        color:
                            colorRiesgo,

                        size: 31,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          const Text(
                            "Nivel de riesgo",

                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            tituloRiesgo,

                            style: TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight.bold,

                              color:
                                  colorRiesgo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  descripcionRiesgo,

                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================
          // RESUMEN DE LAS 3 DIMENSIONES MERD
          // ==================================================

          const Text(
            "Resumen de señales",

            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // FISIOLÓGICA
          // ==================================================

          _tarjetaDimensionRiesgo(
            icono:
                Icons.favorite_outline,

            titulo:
                "Fisiológica",

            estado:
                nivel == "Bajo"
                    ? "Dentro de parámetros"
                    : nivel == "Medio"
                        ? "Cambios detectados"
                        : "Señales alteradas",

            color:
                nivel == "Bajo"
                    ? Colors.green
                    : colorRiesgo,
          ),

          const SizedBox(height: 10),

          // ==================================================
          // MOVIMIENTO
          // ==================================================

          _tarjetaDimensionRiesgo(
            icono:
                Icons.directions_run,

            titulo:
                "Movimiento",

            estado:
                nivel == "Bajo"
                    ? "Sin alteraciones relevantes"
                    : nivel == "Medio"
                        ? "Cambios en el comportamiento"
                        : "Comportamiento alterado",

            color:
                nivel == "Bajo"
                    ? Colors.green
                    : colorRiesgo,
          ),

          const SizedBox(height: 10),

          // ==================================================
          // ESPACIAL
          // ==================================================

          _tarjetaDimensionRiesgo(
            icono:
                Icons.location_on_outlined,

            titulo:
                "Espacial",

            estado:
                nivel == "Bajo"
                    ? "Sin alteraciones relevantes"
                    : nivel == "Medio"
                        ? "Cambios en la ubicación"
                        : "Situación espacial de riesgo",

            color:
                nivel == "Bajo"
                    ? Colors.green
                    : colorRiesgo,
          ),

          const SizedBox(height: 24),

          // ==================================================
          // EVOLUCIÓN RECIENTE
          // ==================================================

          const Text(
            "Evolución reciente",

            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _construirEvolucionRiesgo(),

          const SizedBox(height: 24),

          // ==================================================
          // EXPLICACIÓN DEL RESULTADO
          // ==================================================

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(18),

            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF1A237E)
                      .withOpacity(0.05),

              borderRadius:
                  BorderRadius.circular(16),

              border: Border.all(
                color:
                    const Color(0xFF1A237E)
                        .withOpacity(0.15),
              ),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Icon(
                  Icons.psychology_outlined,

                  color:
                      Color(0xFF1A237E),

                  size: 27,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "¿Cómo se obtiene el resultado?",

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,

                          color:
                              Color(0xFF1A237E),
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        "El nivel de riesgo se obtiene mediante la integración de las dimensiones fisiológica, de movimiento y espacial definidas en el modelo MERD.",

                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // VER UBICACIÓN
          // SOLO PARA RIESGO ALTO
          // ==================================================

          if (nivel == "Alto") ...[

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 50,

              child:
                  ElevatedButton.icon(

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF1A237E),

                  foregroundColor:
                      Colors.white,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                icon: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                ),

                label: const Text(
                  "Ver ubicación",

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                onPressed: () {

                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
            ),
          ],

          const SizedBox(height: 25),
        ],
      ),
    ),
  );
}


// ============================================================
// 🧠 EVOLUCIÓN MERD - DEMOSTRACIÓN
// ============================================================

Widget _construirEvolucionRiesgo() {
  final DateTime ahora = DateTime.now();

  final Color colorActual =
      _nivelRiesgoDemo == "Bajo"
          ? Colors.green
          : _nivelRiesgoDemo == "Medio"
              ? Colors.orange
              : Colors.red;

  // ==========================================================
  // SIMULACIÓN DE EVALUACIONES
  //
  // Cada resultado está separado por 5 minutos.
  //
  // IMPORTANTE:
  // Estos valores son únicamente para demostración.
  // Posteriormente serán reemplazados por los resultados
  // reales almacenados en Firestore.
  // ==========================================================

  final List<Map<String, dynamic>> historial = [

    {
      "hora":
          ahora.subtract(
        const Duration(minutes: 20),
      ),

      "nivel": "Bajo",

      "color": Colors.green,
    },

    {
      "hora":
          ahora.subtract(
        const Duration(minutes: 15),
      ),

      "nivel": "Bajo",

      "color": Colors.green,
    },

    {
      "hora":
          ahora.subtract(
        const Duration(minutes: 10),
      ),

      "nivel": "Medio",

      "color": Colors.orange,
    },

    {
      "hora":
          ahora.subtract(
        const Duration(minutes: 5),
      ),

      "nivel": "Medio",

      "color": Colors.orange,
    },

    {
      "hora": ahora,

      "nivel": _nivelRiesgoDemo,

      "color": colorActual,
    },
  ];

  return Container(
    width: double.infinity,

    padding:
        const EdgeInsets.all(16),

    decoration: BoxDecoration(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(16),

      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.05),

          blurRadius: 7,

          offset:
              const Offset(0, 2),
        ),
      ],
    ),

    child: Column(
      children: [

        // ======================================================
        // ENCABEZADO
        // ======================================================

        Row(
          children: const [

            Icon(
              Icons.timeline,

              color:
                  Color(0xFF1A237E),

              size: 22,
            ),

            SizedBox(width: 8),

            Expanded(
              child: Text(
                "Historial reciente",

                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ======================================================
        // HISTORIAL
        // ======================================================

        ...historial.map(
          (registro) {

            final DateTime hora =
                registro["hora"]
                    as DateTime;

            final String nivel =
                registro["nivel"]
                    as String;

            final Color color =
                registro["color"]
                    as Color;

            final String horaTexto =
                "${hora.hour.toString().padLeft(2, '0')}:"
                "${hora.minute.toString().padLeft(2, '0')}:"
                "${hora.second.toString().padLeft(2, '0')}";

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),

              child: Row(
                children: [

                  // ------------------------------------------------
                  // PUNTO DE RIESGO
                  // ------------------------------------------------

                  Container(
                    width: 11,
                    height: 11,

                    decoration:
                        BoxDecoration(
                      color: color,

                      shape:
                          BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ------------------------------------------------
                  // HORA
                  // ------------------------------------------------

                  SizedBox(
                    width: 65,

                    child: Text(
                      horaTexto,

                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ------------------------------------------------
                  // LÍNEA
                  // ------------------------------------------------

                  Expanded(
                    child: Container(
                      height: 1,

                      color:
                          Colors.grey.shade200,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ------------------------------------------------
                  // NIVEL
                  // ------------------------------------------------

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          color.withOpacity(
                        0.10,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: Text(
                      nivel,

                      style:
                          TextStyle(
                        fontSize: 11,

                        fontWeight:
                            FontWeight.bold,

                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}


// ============================================================
// TARJETA DE DIMENSIÓN MERD
// ============================================================

Widget _tarjetaDimensionRiesgo({
  required IconData icono,
  required String titulo,
  required String estado,
  required Color color,
}) {

  return Container(
    width: double.infinity,

    padding:
        const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),

    decoration:
        BoxDecoration(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(14),

      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withOpacity(0.04),

          blurRadius: 6,

          offset:
              const Offset(0, 2),
        ),
      ],
    ),

    child: Row(
      children: [

        Container(
          width: 42,
          height: 42,

          decoration:
              BoxDecoration(
            color:
                color.withOpacity(0.10),

            shape:
                BoxShape.circle,
          ),

          child: Icon(
            icono,

            color: color,

            size: 23,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                titulo,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,

                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                estado,

                style: TextStyle(
                  fontSize: 12,

                  color: color,
                ),
              ),
            ],
          ),
        ),

        Icon(
          color == Colors.green
              ? Icons.check_circle
              : Icons.warning_amber_rounded,

          color: color,

          size: 21,
        ),
      ],
    ),
  );
}


// ============================================================
// INDICADOR DE EVOLUCIÓN
// ============================================================

Widget _indicadorEvolucion(
  String texto,
  Color color,
) {

  return Column(
    children: [

      Container(
        width: 12,
        height: 12,

        decoration:
            BoxDecoration(
          color: color,

          shape:
              BoxShape.circle,
        ),
      ),

      const SizedBox(height: 6),

      Text(
        texto,

        style: TextStyle(
          fontSize: 11,

          fontWeight:
              FontWeight.bold,

          color: color,
        ),
      ),
    ],
  );
}

  // ⚙️ PANTALLA DE AJUSTES / PERFIL
  Widget _buildAjustesScreen() {
    return const ProfileScreen();
  }

}
