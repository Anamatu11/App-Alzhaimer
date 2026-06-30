
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarPacienteScreen extends StatefulWidget {
  final String nombrePaciente;
  final String idPaciente;

  const EditarPacienteScreen({
    super.key,
    required this.nombrePaciente,
    required this.idPaciente,
  });

  @override
  State<EditarPacienteScreen> createState() => _EditarPacienteScreenState();
}

class _EditarPacienteScreenState extends State<EditarPacienteScreen> {
  TextEditingController? nombreController;
  TextEditingController? latController;
  TextEditingController? lngController;
  TextEditingController? radioController;

  @override
  void dispose() {
    nombreController?.dispose();
    latController?.dispose();
    lngController?.dispose();
    radioController?.dispose();
    super.dispose();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text('Editar paciente'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.idPaciente)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('Paciente no encontrado'),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;
              nombreController ??=
              TextEditingController(text: data['nombre'] ?? '');

          latController ??=
              TextEditingController(
                text: data['lat_hogar'].toString(),
              );

          lngController ??=
              TextEditingController(
                text: data['lng_hogar'].toString(),
              );

          radioController ??=
              TextEditingController(
                text: data['radio_seguro'].toString(),
              );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [

                // INFORMACIÓN GENERAL
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Row(
                          children: [

                            Icon(
                              Icons.person_outline,
                              color: Color(0xFF1A237E),
                              size: 28,
                            ),

                            SizedBox(width: 10),

                            Text(
                              'Información general',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),

                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Nombre del paciente',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            hintText: 'Nombre del paciente',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF1A237E),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Estado',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () async {

                            final nuevoEstado =
                                (data['estado'] ?? 'activo') == 'activo'
                                    ? 'inactivo'
                                    : 'activo';

                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(widget.idPaciente)
                                .update({
                              'estado': nuevoEstado,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                          },
                          child: Chip(
                            avatar: Icon(
                              (data['estado'] ?? 'activo') == 'activo'
                                  ? Icons.check_circle
                                  : Icons.block,
                              color: (data['estado'] ?? 'activo') == 'activo'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            backgroundColor:
                                (data['estado'] ?? 'activo') == 'activo'
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                            side: BorderSide(
                              color: (data['estado'] ?? 'activo') == 'activo'
                                  ? Colors.green.shade300
                                  : Colors.red.shade300,
                            ),
                            label: Text(
                              (data['estado'] ?? 'activo') == 'activo'
                                  ? 'Activo'
                                  : 'Inactivo',
                              style: TextStyle(
                                color: (data['estado'] ?? 'activo') == 'activo'
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

               // GEOCERCA
                Card(
                  elevation: 3,
                  shadowColor: Colors.black12,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Row(
                          children: [

                            Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF1A237E),
                              size: 28,
                            ),

                            SizedBox(width: 10),

                            Text(
                              'Geocerca',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),

                          ],
                        ),

                        const SizedBox(height: 22),

                        TextFormField(
                          controller: latController,
                          decoration: InputDecoration(
                            labelText: 'Latitud hogar',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF1A237E),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: lngController,
                          decoration: InputDecoration(
                            labelText: 'Longitud hogar',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF1A237E),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: radioController,
                          decoration: InputDecoration(
                            labelText: 'Radio seguro (metros)',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFF1A237E),
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      try {

                        await FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(widget.idPaciente)
                            .update({

                          'nombre': nombreController!.text.trim(),

                          'lat_hogar': double.parse(
                            latController!.text.trim(),
                          ),

                          'lng_hogar': double.parse(
                            lngController!.text.trim(),
                          ),

                          'radio_seguro': double.parse(
                            radioController!.text.trim(),
                          ),

                          'updatedAt': FieldValue.serverTimestamp(),

                        });

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(

                          const SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              'Paciente actualizado correctamente',
                            ),
                          ),

                        );

                        await Future.delayed(
                          const Duration(milliseconds: 900),
                        );

                        if (!context.mounted) return;

                        Navigator.pop(context);

                      } catch (e) {

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(

                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              'Error al actualizar: $e',
                            ),
                          ),

                        );

                      }

                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Guardar cambios',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
