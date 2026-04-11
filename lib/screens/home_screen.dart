import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
import '../widgets/data_card.dart';
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
  double lat = 0;
  double lng = 0;
  String direccion = "Cargando...";

  @override
  void initState() {
    super.initState();

    mqttService.onData = (data) async {
      setState(() {
        pulso = data['pulso'] ?? 0;
        spo2 = data['spo2'] ?? 0;
        lat = data['lat'] ?? 0;
        lng = data['lng'] ?? 0;
      });

      obtenerDireccion();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parche IoT")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  DataCard(
                    title: "Pulso",
                    value: "$pulso bpm",
                    icon: Icons.favorite,
                  ),
                  DataCard(
                    title: "SpO2",
                    value: "$spo2 %",
                    icon: Icons.bloodtype,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text("Ubicación"),
                subtitle: Text(direccion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}