import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agregar_cuidador_screen.dart';
import 'editar_cuidador_screen.dart';
import '../services/firestore_service.dart';

class GestionarCuidadoresScreen extends StatefulWidget {
  final String nombrePaciente;
  final String idPaciente;

  const GestionarCuidadoresScreen({
    super.key,
    required this.nombrePaciente,
    required this.idPaciente,
  });

  @override
  State<GestionarCuidadoresScreen> createState() =>
      _GestionarCuidadoresScreenState();
}

class _GestionarCuidadoresScreenState
    extends State<GestionarCuidadoresScreen> {

  final TextEditingController buscarController =
      TextEditingController();

  String textoBusqueda = "";
  late final Stream<DocumentSnapshot> _pacienteStream;

  @override
  void initState() {
    super.initState();

    _pacienteStream = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.idPaciente)
        .snapshots();
}
  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text('Gestionar cuidadores'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

////////////////////////////////////////////////////////////////////////////////////
     body: StreamBuilder<DocumentSnapshot>(
      stream: _pacienteStream,
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

        final cuidadores =
            List<Map<String, dynamic>>.from(
          data['cuidadores'] ?? [],
        );

        final activos = cuidadores.where(
          (c) => c['estado'] == 'activo',
        ).length;

        final inactivos = cuidadores.length - activos;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
///////////////////////////////////////////////////////////////////////////////////////////////
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Cuidadores de ${widget.nombrePaciente}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AgregarCuidadorScreen(
                        idPaciente: widget.idPaciente,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text(
                  'Agregar cuidador',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: buscarController,

              onChanged: (value) {

                setState(() {

                  textoBusqueda = value.toLowerCase();

                });

              },

               decoration: InputDecoration(
                hintText: 'Buscar cuidador...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cuidadores.length} cuidadores registrados',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$activos activos · $inactivos inactivos',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
///////////////////////////////////////////////////////////////////////////////////////////////
            ...cuidadores
            .where((cuidador) {

              final nombre = (cuidador['nombre'] ?? '')
                  .toString()
                  .toLowerCase();

              return nombre.contains(textoBusqueda);

            })
            .map((cuidador) {

              return Card(
                color: Colors.white,
                elevation: 3,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [

                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF1A237E),
                            child: Text(
                              (cuidador['nombre'] ?? 'C')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              cuidador['nombre'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Chip(
                            backgroundColor:
                                (cuidador['estado'] ?? 'activo') == 'activo'
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                            label: Text(
                              (cuidador['estado'] ?? 'activo') == 'activo'
                                  ? 'Activo'
                                  : 'Inactivo',
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Icon(Icons.family_restroom,
                              color: Color(0xFF1A237E), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cuidador['parentesco'] ?? '',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(Icons.email,
                              color: Color(0xFF1A237E), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cuidador['correo'] ?? '',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(Icons.phone,
                              color: Color(0xFF1A237E), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cuidador['celular'] ?? '',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [

                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarCuidadorScreen(
                                      idPaciente: widget.idPaciente,
                                      cuidador: cuidador,
                                    ),
                                  ),
                                );

                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (cuidador['estado'] ?? 'activo') == 'activo'
                                        ? Colors.red
                                        : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                             onPressed: () async {

                                try {

                                  await FirestoreService().cambiarEstadoCuidador(
                                    widget.idPaciente,
                                    cuidador,
                                  );

                                } catch (e) {

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(

                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        e.toString().replaceAll("Exception: ", ""),
                                      ),
                                    ),

                                  );

                                }

                              },
                              icon: Icon(
                                (cuidador['estado'] ?? 'activo') == 'activo'
                                    ? Icons.block
                                    : Icons.check_circle,
                              ),
                              label: Text(
                                (cuidador['estado'] ?? 'activo') == 'activo'
                                    ? 'Deshabilitar'
                                    : 'Habilitar',
                              ),
                            ),
                          ),

                        ],
                      ),

                    ],
                  ),
                ),
              );

            }).toList(),

          ],
        );
      },
    ),

///////////////////////////////////////////////////////////////
    );
  }
}