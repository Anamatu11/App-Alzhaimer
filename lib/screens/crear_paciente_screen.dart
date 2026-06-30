import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

  class CrearPacienteScreen extends StatefulWidget {
    const CrearPacienteScreen({super.key});

    @override
    State<CrearPacienteScreen> createState() =>
        _CrearPacienteScreenState();
  }

  class _CrearPacienteScreenState
      extends State<CrearPacienteScreen> {

    final TextEditingController nombreController =
        TextEditingController();

    final TextEditingController latController =
        TextEditingController();

    final TextEditingController lngController =
        TextEditingController();

    final TextEditingController radioController =
        TextEditingController();
        
    final TextEditingController fotoController =
      TextEditingController();
    @override

    void dispose() {

      nombreController.dispose();
      latController.dispose();
      lngController.dispose();
      radioController.dispose();
      fotoController.dispose();
      super.dispose();
    }
  /////// Esta función nos asegura que nunca tendrás que escribir el ID manualmente.
    Future<String> generarIdPaciente() async {

      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();

      int mayor = 0;

      for (var doc in snapshot.docs) {

        if (doc.id.startsWith('Paciente-')) {

          final numero = int.tryParse(
            doc.id.replaceAll('Paciente-', ''),
          );

          if (numero != null && numero > mayor) {
            mayor = numero;
          }
        }
      }

      final siguiente = mayor + 1;

      return 'Paciente-${siguiente.toString().padLeft(3, '0')}';

    }
/////////////////////////////////////////////////////////

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),

        appBar: AppBar(
          title: const Text("Crear paciente"),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),

////// Pantalla de crear paciente con campos de nombre, latitud, longitud y radio, y un boton de guardar que guarde en firestore
      body: Padding(
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
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Nombre de la foto',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: fotoController,
                    decoration: InputDecoration(
                      hintText: 'Ej: juanperez.jpg',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),


                  const Text(
                    'Estado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Chip(
                    avatar: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(
                      color: Colors.green.shade300,
                    ),
                    label: Text(
                      'Activo',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
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
                        Icons.location_on_outlined,
                        color: Color(0xFF1A237E),
                        size: 28,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Configuración de geocerca',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: latController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Latitud hogar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: lngController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Longitud hogar',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: radioController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Radio seguro (m)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
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
            height: 58,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
/////////// lógica para guardar el paciente en firestore
              onPressed: () async {
                if (nombreController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese el nombre del paciente.'),
                    ),
                  );
                  return;
                }

                if (fotoController.text.trim().isEmpty) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese el nombre de la foto.'),
                    ),
                  );

                  return;

                }
                try {
                  final idPaciente = await generarIdPaciente();

                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(idPaciente)
                      .set({

                    'nombre': nombreController.text.trim(),
                    'fotoUrl': fotoController.text.trim(),
                    'lat_hogar':
                        double.tryParse(latController.text) ?? 0,
                    'lng_hogar':
                        double.tryParse(lngController.text) ?? 0,
                    'radio_seguro':
                        double.tryParse(radioController.text) ?? 100,
                    'estado': 'activo',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),

                  });

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(

                    const SnackBar(
                      content: Text('Paciente creado correctamente'),
                    ),

                  );

                  Navigator.pop(context);

                } catch (e) {

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(

                    SnackBar(
                      content: Text(e.toString()),
                    ),
                  );
                }
              },
///////////////////////////////////////////////////////
              icon: const Icon(Icons.save),
              label: const Text(
                "Crear paciente",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

        ],
      ),
    ),


////////////////////////////////////////////////////////////////////
      );
    }
  }   