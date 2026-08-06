import 'package:flutter/material.dart';
import 'usuarios_screen.dart';
import 'pacientes_screen.dart';
import 'login_screen.dart';
import 'lecturas_screen.dart';
import 'dart:async';


class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // PACIENTES
            Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.person_add,
                  color: Color(0xFF1A237E),
                ),
                title: const Text(
                  "Pacientes",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  "Crear y editar pacientes",
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PacientesScreen(),
                    ),
                  );
                },
              ),
            ),

            // LECTURAS
           _buildCard(
              icon: Icons.monitor_heart,
              title: "Lecturas",
              subtitle: "Consultar datos biométricos",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LecturasScreen(),
                  ),
                );
              },
            ),

             // USUARIOS
            Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.manage_accounts,
                  color: Color(0xFF1A237E),
                  size: 30,
                ),
                title: const Text(
                  "Usuarios",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Crear cuentas para cuidadores",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UsuariosScreen(),
                    ),
                  );
                },
              ),
            ),

            // ALERTAS
            _buildCard(
              icon: Icons.psychology_outlined,
              title: 'Análisis de riesgo',
              subtitle: 'Consultar evaluación técnica del modelo MERD',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnalisisRiesgoScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // CERRAR SESIÓN
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.shade300,
                  width: 1.2,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.red.shade400,
                ),

                title: Text(
                  "Cerrar sesión",
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.red.shade400,
                  size: 18,
                ),

                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF1A237E),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.arrow_forward_ios,
        ),
        onTap: onTap,
      ),
    );
  }
}
// ============================================================
// 🧠 PANTALLA DE ANÁLISIS DE RIESGO - ADMINISTRADOR
// ============================================================

class AnalisisRiesgoScreen extends StatefulWidget {
  const AnalisisRiesgoScreen({super.key});

  @override
  State<AnalisisRiesgoScreen> createState() =>
      _AnalisisRiesgoScreenState();
}

class _AnalisisRiesgoScreenState
    extends State<AnalisisRiesgoScreen> {

  // ==========================================================
  // DATOS DE DEMOSTRACIÓN
  // ==========================================================

  String nivelRiesgoDemo = "Medio";

  String pacienteDemoSeleccionado = "Paciente-001";

  // ==========================================================
  // 🕐 HORA ACTUAL DEL DISPOSITIVO
  // ==========================================================

  DateTime _horaActual = DateTime.now();

  Timer? _timerHora;

  // ==========================================================
  // 🔧 SENSOR EN FALLA - MODO DEMOSTRACIÓN
  // ==========================================================

  // Este fallo es independiente del nivel de riesgo.
  // Se utiliza únicamente para demostrar el estado del dispositivo.
  String sensorDemoSinDatos = "MPU6050";

  final List<Map<String, String>> pacientesDemo = [
    {
      "id": "Paciente-001",
      "nombre": "Juan Pérez",
    },
    {
      "id": "Paciente-002",
      "nombre": "Paciente de prueba 002",
    },
    {
      "id": "Paciente-003",
      "nombre": "Paciente de prueba 003",
    },
    {
      "id": "Paciente-004",
      "nombre": "Paciente de prueba 004",
    },
    {
      "id": "Paciente-005",
      "nombre": "Paciente de prueba 005",
    },
    {
      "id": "Paciente-006",
      "nombre": "Paciente de prueba 006",
    },
    {
      "id": "Paciente-007",
      "nombre": "Paciente de prueba 007",
    },
    {
      "id": "Paciente-008",
      "nombre": "Paciente de prueba 008",
    },
    {
      "id": "Paciente-009",
      "nombre": "Paciente de prueba 009",
    },
  ];

  @override
  void initState() {
    super.initState();

    _timerHora = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _horaActual = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _timerHora?.cancel();
    super.dispose();
  }

  // ==========================================================
  // 🕐 FORMATEAR HORA (hh:mm:ss)
  // ==========================================================
  // Usado tanto en "Actualizado hh:mm:ss" como en el historial
  // de "Evolución del comportamiento", para que ambas partes
  // se actualicen a partir del mismo reloj en tiempo real.
  // ==========================================================

  String _formatearHora(DateTime hora) {
    return "${hora.hour.toString().padLeft(2, '0')}:"
        "${hora.minute.toString().padLeft(2, '0')}:"
        "${hora.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Análisis de riesgo",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _buildContenido(),
    );
  }

  // ==========================================================
  // CONTENIDO PRINCIPAL
  // ==========================================================

  Widget _buildContenido() {
    final String nivel = nivelRiesgoDemo;

    Color colorRiesgo;
    IconData iconoRiesgo;

    if (nivel == "Bajo") {
      colorRiesgo = Colors.green;
      iconoRiesgo = Icons.check_circle_outline;
    } else if (nivel == "Medio") {
      colorRiesgo = Colors.orange;
      iconoRiesgo = Icons.warning_amber_rounded;
    } else {
      colorRiesgo = Colors.red;
      iconoRiesgo = Icons.warning_rounded;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // DESCRIPCIÓN
            // ==================================================

            const Text(
              "Supervisión técnica de la evaluación MERD",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PACIENTE EVALUADO
            // ==================================================

            const Text(
              "Paciente evaluado",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 9),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(14),

                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),

              child:
                  DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      pacienteDemoSeleccionado,

                  isExpanded: true,

                  dropdownColor:
                      Colors.white,

                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF1A237E),
                  ),

                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),

                  items:
                      pacientesDemo.map(
                    (paciente) {
                      return DropdownMenuItem<String>(
                        value:
                            paciente["id"],

                        child: Text(
                          "${paciente["id"]} — "
                          "${paciente["nombre"]}",

                          style:
                              const TextStyle(
                            color:
                                Colors.black87,
                          ),
                        ),
                      );
                    },
                  ).toList(),

                  onChanged: (valor) {
                    if (valor == null) {
                      return;
                    }

                    setState(() {
                      pacienteDemoSeleccionado =
                          valor;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ==================================================
            // SELECTOR DE DEMOSTRACIÓN
            // ==================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 4,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(14),

                border: Border.all(
                  color: Colors.grey.shade200,
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
                      "Escenario de demostración",
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  DropdownButtonHideUnderline(
                    child:
                        DropdownButton<String>(
                      value:
                          nivelRiesgoDemo,

                      dropdownColor:
                          Colors.white,

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
                          nivelRiesgoDemo =
                              valor;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // EVALUACIÓN MERD
            // ==================================================

            const Text(
              "Evaluación MERD",
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(16),

                border: Border.all(
                  color:
                      colorRiesgo.withOpacity(
                    0.30,
                  ),
                ),
              ),

              child: Row(
                children: [

                  Container(
                    width: 50,
                    height: 50,

                    decoration:
                        BoxDecoration(
                      color:
                          colorRiesgo
                              .withOpacity(
                        0.10,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child: Icon(
                      iconoRiesgo,

                      color:
                          colorRiesgo,

                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Nivel actual",

                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        "Riesgo $nivel",

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
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // ESTADO DEL DISPOSITIVO
            // ==================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Estado del dispositivo",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Actualizado ${_formatearHora(_horaActual)}",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Column(
                children: [

                  _sensorAdmin(
                    Icons.favorite_outline,
                    "MAX30102",
                    "Datos fisiológicos",
                  ),

                  const SizedBox(height: 12),

                  _sensorAdmin(
                    Icons.directions_run,
                    "MPU6050",
                    "Datos de movimiento",
                  ),

                  const SizedBox(height: 12),

                  _sensorAdmin(
                    Icons.location_on_outlined,
                    "GPS",
                    "Datos de ubicación",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // HUELLA MULTIDIMENSIONAL
            // ==================================================

            const Text(
              "Huella multidimensional",

              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(18),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Column(
                children: [

                  _dimensionAdmin(
                    icono:
                        Icons.favorite_outline,

                    titulo:
                        "Fisiológica",

                    estado:
                        "Dentro de parámetros",

                    color:
                        Colors.green,

                    progreso:
                        0.25,
                  ),

                  const SizedBox(height: 18),

                  _dimensionAdmin(
                    icono:
                        Icons.directions_run,

                    titulo:
                        "Movimiento",

                    estado:
                        nivel == "Bajo"
                            ? "Sin alteraciones relevantes"
                            : "Señales de alteración",

                    color:
                        nivel == "Bajo"
                            ? Colors.green
                            : colorRiesgo,

                    progreso:
                        nivel == "Bajo"
                            ? 0.30
                            : nivel == "Medio"
                                ? 0.65
                                : 0.90,
                  ),

                  const SizedBox(height: 18),

                  _dimensionAdmin(
                    icono:
                        Icons.location_on_outlined,

                    titulo:
                        "Espacial",

                    estado:
                        nivel == "Bajo"
                            ? "Sin alteraciones relevantes"
                            : "Señales de alteración",

                    color:
                        nivel == "Bajo"
                            ? Colors.green
                            : colorRiesgo,

                    progreso:
                        nivel == "Bajo"
                            ? 0.25
                            : nivel == "Medio"
                                ? 0.60
                                : 0.88,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // EVOLUCIÓN
            // ==================================================

            const Text(
              "Evolución del comportamiento",

              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(18),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Column(
                children: [

                  _filaEvolucionAdmin(
                    "Bajo",
                    _formatearHora(
                      _horaActual.subtract(
                        const Duration(minutes: 15),
                      ),
                    ),
                    Colors.green,
                  ),

                  const SizedBox(height: 10),

                  _filaEvolucionAdmin(
                    "Bajo",
                    _formatearHora(
                      _horaActual.subtract(
                        const Duration(minutes: 10),
                      ),
                    ),
                    Colors.green,
                  ),

                  const SizedBox(height: 10),

                  _filaEvolucionAdmin(
                    "Medio",
                    _formatearHora(
                      _horaActual.subtract(
                        const Duration(minutes: 5),
                      ),
                    ),
                    Colors.orange,
                  ),

                  const SizedBox(height: 10),

                  _filaEvolucionAdmin(
                    nivel,
                    _formatearHora(_horaActual),
                    colorRiesgo,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // INTERPRETACIÓN MERD
            // ==================================================

            const Text(
              "Interpretación MERD",

              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(18),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(16),

                border: Border.all(
                  color:
                      const Color(
                    0xFF1A237E,
                  ).withOpacity(0.12),
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
                    child: Text(
                      _interpretacionMERD(
                        nivel,
                      ),

                      style:
                          const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color:
                            Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SENSOR
  // ==========================================================

  Widget _sensorAdmin(
    IconData icono,
    String nombre,
    String descripcion,
  ) {
    return Row(
      children: [

        Container(
          width: 36,
          height: 36,

          decoration:
              BoxDecoration(
            color:
                Colors.green.withOpacity(
              0.10,
            ),

            shape:
                BoxShape.circle,
          ),

          child: Icon(
            icono,
            color: Colors.green,
            size: 20,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                nombre,

                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              Text(
                descripcion,

                style:
                    const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const Text(
          "Datos recibidos",

          style: TextStyle(
            fontSize: 11,
            color: Colors.green,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // DIMENSIÓN MERD
  // ==========================================================

  Widget _dimensionAdmin({
    required IconData icono,
    required String titulo,
    required String estado,
    required Color color,
    required double progreso,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Row(
          children: [

            Icon(
              icono,
              color: color,
              size: 21,
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Text(
                titulo,

                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Text(
              estado,

              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(10),

          child:
              LinearProgressIndicator(
            value: progreso,

            minHeight: 8,

            backgroundColor:
                Colors.grey.shade200,

            valueColor:
                AlwaysStoppedAnimation<Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // EVOLUCIÓN
  // ==========================================================

  Widget _filaEvolucionAdmin(
    String nivel,
    String hora,
    Color color,
  ) {
    return Row(
      children: [

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

        Expanded(
          child: Text(
            "Riesgo $nivel",

            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        Text(
          hora,

          style:
              const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // INTERPRETACIÓN MERD
  // ==========================================================

  String _interpretacionMERD(
    String nivel,
  ) {
    if (nivel == "Bajo") {
      return "La evaluación presenta un comportamiento estable en las dimensiones fisiológica, de movimiento y espacial. La integración de las señales disponibles corresponde a un nivel de riesgo bajo.";
    }

    if (nivel == "Medio") {
      return "La evaluación presenta señales que requieren seguimiento en las dimensiones de movimiento y/o espacial. La integración multidimensional corresponde a un nivel de riesgo medio.";
    }

    return "La evaluación presenta señales relevantes en las dimensiones de movimiento y/o espacial. La integración de las señales disponibles corresponde a un nivel de riesgo alto y requiere revisión prioritaria.";
  }
}