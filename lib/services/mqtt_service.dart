import 'dart:convert';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  Function(Map<String, dynamic>)? onData;
  
  // Variable para controlar reconexiones
  bool _isConnecting = false;

  Future<void> connect() async {
    // Evitar múltiples intentos simultáneos
    if (_isConnecting) return;
    _isConnecting = true;
    
    // 🔹 ID ÚNICO para evitar "identifierRejected"
    String clientId = 'flutter_parche_${Random().nextInt(999999)}';
    
    client = MqttServerClient('broker.hivemq.com', clientId);
    client.port = 1883;
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    client.autoReconnect = true;  // Reconexión automática
    
    // Configurar mensaje de conexión
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()  // Limpiar sesión anterior
        .keepAliveFor(30)
        .withWillQos(MqttQos.atMostOnce);
    
    client.connectionMessage = connMessage;

    try {
      print('🔌 Conectando a MQTT con ID: $clientId');
      await client.connect();
      
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ Conectado a MQTT');
        _isConnecting = false;
        
        // Suscribirse al topic
        client.subscribe('parche/paciente1/datos', MqttQos.atLeastOnce);
        print('📡 Suscrito a: parche/paciente1/datos');
        
        // Escuchar mensajes
        client.updates!.listen(_onMessageReceived);
        
      } else {
        print('❌ Error conexión MQTT: ${client.connectionStatus!.state}');
        _isConnecting = false;
        _scheduleReconnect();
      }
    } catch (e) {
      print('❌ Error de conexión MQTT: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }
  
  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> events) {
    final MqttPublishMessage recMess = events[0].payload as MqttPublishMessage;
    final String payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message);

    print("📨 Mensaje recibido: $payload");

    try {
      final Map<String, dynamic> rawData = jsonDecode(payload);
      
      // 🔹 Adaptar datos del ESP8266 al formato que espera la UI
      final Map<String, dynamic> processedData = {
        // Campos que ya vienen del ESP8266
        'ax': rawData['ax'] ?? 0.0,
        'ay': rawData['ay'] ?? 0.0,
        'az': rawData['az'] ?? 0.0,
        'ir': rawData['ir'] ?? 0,
        'finger': rawData['finger'] ?? false,
        'lat': rawData['lat'] ?? 0.0,
        'lng': rawData['lng'] ?? 0.0,
        'satellites': rawData['satellites'] ?? 0,
        
        // Campos adaptados para la UI (pulso y spo2)
        'pulso': rawData['ir'] ?? 0,  // Temporalmente usa IR
        'spo2': (rawData['finger'] == true) ? 98 : 0,  // Temporal
      };
      
      if (onData != null) {
        onData!(processedData);
      }
    } catch (e) {
      print("❌ Error al parsear JSON: $e");
      print("   Payload recibido: $payload");
    }
  }
  
  void _scheduleReconnect() {
    print('⏳ Reintentando conexión en 5 segundos...');
    Future.delayed(const Duration(seconds: 5), () {
      connect();
    });
  }
  
  void disconnect() {
    client.disconnect();
  }
  
  // 🔹 Método para verificar estado de conexión
  bool isConnected() {
    return client.connectionStatus?.state == MqttConnectionState.connected;
  }
}