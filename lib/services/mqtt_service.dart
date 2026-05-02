import 'dart:convert';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  Function(dynamic)? onData;

  bool _isConnecting = false;

  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    String clientId = 'flutter_parche_${Random().nextInt(999999)}';

    client = MqttServerClient('broker.hivemq.com', clientId);
    client.port = 1883;
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    client.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .keepAliveFor(30)
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      print('🔌 Conectando a MQTT con ID: $clientId');
      await client.connect();

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ Conectado a MQTT');
        _isConnecting = false;

        client.subscribe('parche/paciente1/datos', MqttQos.atLeastOnce);

        client.updates!.listen(_onMessageReceived);
      } else {
        _isConnecting = false;
        _scheduleReconnect();
      }
    } catch (e) {
      print('❌ Error MQTT: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> events) {
    final recMess = events[0].payload as MqttPublishMessage;

    final payload =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print("📨 Mensaje recibido: $payload");

    try {
      final rawData = jsonDecode(payload) as Map<String, dynamic>;

      // Enviar el JSON tal cual a la pantalla para que ella haga los cálculos
      onData?.call(rawData);
    } catch (e) {
      print("❌ Error JSON: $e");
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      connect();
    });
  }

  void disconnect() {
    client.disconnect();
  }

  bool isConnected() {
    return client.connectionStatus?.state == MqttConnectionState.connected;
  }
}
