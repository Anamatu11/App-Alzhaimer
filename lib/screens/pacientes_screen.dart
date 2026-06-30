import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'paciente_detalle_screen.dart';
import 'crear_paciente_screen.dart';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  String filtro = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text('Pacientes'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearPacienteScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 30),
                  label: const Text(
                    "Crear paciente",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),


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

                return Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${pacientes.length} pacientes registrados',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: pacientes.length,
                        itemBuilder: (context, index) {

                          final data = pacientes[index].data()
                              as Map<String, dynamic>;

                          return Card(
                            color: Colors.white,
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundImage: AssetImage(
                                  'assets/${data['fotoUrl']}',
                                ),
                              ),

                              title: Text(
                                data['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                                    builder: (_) => PacienteDetalleScreen(
                                      nombre: data['nombre'] ?? 'Sin nombre',
                                      idPaciente: pacientes[index].id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
