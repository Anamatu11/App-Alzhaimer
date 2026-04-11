import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final mqttService = MqttService();

  int pulso = 0;
  int spo2 = 0;
  bool dedo = false;

  double lat = 0;
  double lng = 0;

  String direccion = "Cargando...";
  String ubicacion = "En casa";
  String actividad = "Movimiento";

  int desorientacion = 30;

  @override
  void initState() {
    super.initState();

    mqttService.onData = (data) async {
      print("DATOS MQTT: $data"); // DEBUG

      setState(() {
        /// ✅ MOSTRAR SIEMPRE LOS DATOS REALES
        pulso = int.tryParse(data['pulso'].toString()) ?? 0;
        spo2 = int.tryParse(data['spo2'].toString()) ?? 0;

        /// ⚠️ SOLO INDICADOR
        dedo = data['dedo'] ?? false;

        lat = data['lat'] ?? 0;
        lng = data['lng'] ?? 0;
        actividad = data['actividad'] ?? "Movimiento";
        desorientacion = data['desorientacion'] ?? 30;
      });

      if (lat != 0 && lng != 0) {
        obtenerDireccion();
      }
    };

    mqttService.connect();
  }

  Future<void> obtenerDireccion() async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(lat, lng);

      final place = placemarks.first;

      setState(() {
        direccion = "${place.street}, ${place.locality}";
      });
    } catch (e) {
      direccion = "Ubicación no disponible";
    }
  }

  /// 🎨 COLOR DINÁMICO DEL PULSO
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            /// ❤️ PULSO
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
                              width: 1,
                              height: 80,
                              color: Colors.grey[300],
                            ),

                            /// 🫁 SPO2
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

                        /// 🧠 ESTADO
                        Text(
                          dedo
                              ? "Midiendo correctamente"
                              : "Lectura inestable",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.home,
                            color: Colors.green, size: 28),
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
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w500),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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