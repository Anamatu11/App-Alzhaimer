import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class EditarCuidadorScreen extends StatefulWidget {
  final String idPaciente;
  final Map<String, dynamic> cuidador;

  const EditarCuidadorScreen({
    super.key,
    required this.idPaciente,
    required this.cuidador,
  });

  @override
  State<EditarCuidadorScreen> createState() =>
      _EditarCuidadorScreenState();
}

class _EditarCuidadorScreenState
    extends State<EditarCuidadorScreen> {

  late TextEditingController nombreController;
  late TextEditingController parentescoController;
  late TextEditingController correoController;
  late TextEditingController celularController;

  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(
      text: widget.cuidador['nombre'],
    );

    parentescoController = TextEditingController(
      text: widget.cuidador['parentesco'],
    );

    correoController = TextEditingController(
      text: widget.cuidador['correo'],
    );

    celularController = TextEditingController(
      text: widget.cuidador['celular'],
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    parentescoController.dispose();
    correoController.dispose();
    celularController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text("Editar cuidador"),
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

              final cuidadorNuevo = {

                'nombre': nombreController.text.trim(),
                'parentesco': parentescoController.text.trim(),
                'correo': correoController.text.trim(),
                'celular': celularController.text.trim(),
              };

              await firestoreService.updateCaregiver(

                widget.idPaciente,
                widget.cuidador,
                cuidadorNuevo,

              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(

                const SnackBar(
                  content: Text(
                    'Cuidador actualizado correctamente',
                  ),

                ),

              );

              Navigator.pop(context);

            },

                child: const Text(
                  "Guardar cambios",
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