import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lecturas_historial_screen.dart';

class LecturasPacienteScreen extends StatefulWidget {
  const LecturasPacienteScreen({super.key});

  @override
  State<LecturasPacienteScreen> createState() =>
      _LecturasPacienteScreenState();
}

class _LecturasPacienteScreenState
    extends State<LecturasPacienteScreen> {

  String filtro = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text('Lecturas por paciente'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  filtro = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar paciente...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'No hay pacientes registrados',
                    ),
                  );
                }

                final pacientes = snapshot.data!.docs.where((doc) {

                  if (!doc.id.startsWith('Paciente-')) {
                    return false;
                  }

                  final data =
                      doc.data() as Map<String, dynamic>;

                  final nombre =
                      (data['nombre'] ?? '')
                          .toString()
                          .toLowerCase();

                  return nombre.contains(filtro);

                }).toList();

                if (pacientes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron pacientes',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: pacientes.length,
                  itemBuilder: (context, index) {

                    final data = pacientes[index].data()
                        as Map<String, dynamic>;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                            'assets/${data['fotoUrl']}',
                          ),
                        ),
                        title: Text(
                          data['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          pacientes[index].id,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LecturasHistorialScreen(
                                pacienteId:
                                    pacientes[index].id,
                                nombrePaciente:
                                    data['nombre'] ??
                                        'Paciente',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}