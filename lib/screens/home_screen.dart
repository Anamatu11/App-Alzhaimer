import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import 'package:geocoding/geocoding.dart';

// ✅ MAPA - Dependencias necesarias
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final mqttService = MqttService();

  // ✅ MAPA - Controlador para mover el mapa en tiempo real
  final MapController _mapController = MapController();

  int pulso = 0;
  int spo2 = 0;
  bool dedo = false;

  double lat = 0;
  double lng = 0;

  String direccion = "Cargando...";
  String ubicacion = "En casa";
  String actividad = "Movimiento";

  int desorientacion = 30;

  final List<int> _irBuffer = [];
  final List<int> _redBuffer = [];
  int _fallTimer = 0;

  @override
  void initState() {
    super.initState();

    mqttService.onData = (data) async {
      _procesarDatosMqtt(data);
    };

    mqttService.connect();
  }

  void _procesarDatosMqtt(dynamic data) {
    if (data == null || data is! Map) return;

    try {
      double ax = double.tryParse(data['ax']?.toString() ?? "0") ?? 0;
      double ay = double.tryParse(data['ay']?.toString() ?? "0") ?? 0;
      double az = double.tryParse(data['az']?.toString() ?? "0") ?? 0;

      _calcularPostura(ax, ay, az);

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
    if (pulso < 60) return Colors.blue;
    if (pulso < 100) return Colors.green;
    return Colors.red;
  }

  String _getDesorientacionLevel() {
    if (desorientacion < 30) return "Baja";
    if (desorientacion < 60) return "Media";
    return "Alta";
  }

  Color _getDesorientacionColor() {
    if (desorientacion < 30) return Colors.green;
    if (desorientacion < 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Parche IoT"),
        elevation: 0,
      ),
      body: SafeArea(
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
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Juan Pérez",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Estable",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Signos Vitales",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Sensor MAX30102",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    (pulso > 0) ? "$pulso" : "--",
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: _colorPulso(),
                                    ),
                                  ),
                                  const Text("BPM",
                                      style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  const Text("Ritmo Cardíaco"),
                                ],
                              ),
                            ),
                            Container(
                                width: 1, height: 80, color: Colors.grey[300]),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    (spo2 > 0) ? "$spo2" : "--",
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const Text("% SpO₂",
                                      style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  const Text("Oxígeno en Sangre"),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dedo ? "Midiendo correctamente" : "Lectura inestable",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.home, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ubicacion,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                direccion,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ MAPA - Widget del mapa en tiempo real
                SizedBox(
                  height: 250,
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

                /// 🚶 MOVIMIENTO
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.directions_walk,
                              color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          actividad,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 🧠 ANÁLISIS COGNITIVO
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Análisis Cognitivo",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Desorientación: ${_getDesorientacionLevel()}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getDesorientacionColor(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: desorientacion / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              AlwaysStoppedAnimation(_getDesorientacionColor()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
