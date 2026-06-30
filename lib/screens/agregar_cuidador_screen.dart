import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AgregarCuidadorScreen extends StatefulWidget {

  final String idPaciente;

  const AgregarCuidadorScreen({
    super.key,
    required this.idPaciente,
  });

  @override
  State<AgregarCuidadorScreen> createState() =>
      _AgregarCuidadorScreenState();
}

class _AgregarCuidadorScreenState
    extends State<AgregarCuidadorScreen> {

  final nombreController = TextEditingController();
  final parentescoController = TextEditingController();
  final correoController = TextEditingController();
  final celularController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text("Agregar cuidador"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),

        child: ListView(

          children: [

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre completo",
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: parentescoController,
              decoration: const InputDecoration(
                labelText: "Parentesco",
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: "Correo",
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: celularController,
              decoration: const InputDecoration(
                labelText: "Celular",
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(

              height: 55,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),

               onPressed: () async {

                final cuidador = {
                  'nombre': nombreController.text,
                  'parentesco': parentescoController.text,
                  'correo': correoController.text,
                  'celular': celularController.text,
                  'estado': 'activo',
                };

                await firestoreService.addCaregiver(
                  widget.idPaciente,
                  cuidador,
                );

                // Consultar nuevamente el paciente para saber
                // cómo quedó guardado el último cuidador
                final doc = await firestoreService
                    .getUserData(widget.idPaciente);

                final cuidadores = List<Map<String, dynamic>>.from(
                  doc['cuidadores'] ?? [],
                );

                final ultimo = cuidadores.last;

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ultimo['estado'] == 'activo'
                        ? Colors.green
                        : Colors.orange,
                    content: Text(
                      ultimo['estado'] == 'activo'
                          ? '✅ Cuidador agregado correctamente.'
                          : '⚠ Ya existen 3 cuidadores activos. El nuevo cuidador fue agregado como INACTIVO.',
                    ),
                  ),
                );

              },

                child: const Text(
                  "Guardar cuidador",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ),

            )

          ],

        ),

      ),

    );

  }

}