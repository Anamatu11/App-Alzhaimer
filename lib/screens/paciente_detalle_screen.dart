import 'package:flutter/material.dart';
import 'gestionar_cuidadores_screen.dart';
import 'editar_paciente_screen.dart';


class PacienteDetalleScreen extends StatelessWidget {
  final String nombre;
  final String idPaciente;

  const PacienteDetalleScreen({
    super.key,
    required this.nombre,
    required this.idPaciente,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: Text(nombre),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
/////////////////////////////////////////////////////////
       Card(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: const Icon(
              Icons.edit,
              color: Color(0xFF1A237E),
              size: 28,
            ),
            title: const Text(
              'Editar paciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF1A237E),
              size: 18,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarPacienteScreen(
                    nombrePaciente: nombre,
                    idPaciente: idPaciente,
                  ),
                ),
              );
            },
          ),
        ),
////////////////////////////////////////////////////////////////////////////////
           Card(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black12,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.people,
                color: Color(0xFF1A237E),
                size: 28,
              ),
              title: const Text(
                'Gestionar cuidadores',
                style: TextStyle(
                  fontSize: 18,fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF1A237E),
                size: 18,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GestionarCuidadoresScreen(
                      nombrePaciente: nombre,
                      idPaciente: idPaciente,
                    ),
                  ),
                );
              },
            ),
          ),
////////////////////////////////////////////////////////////////////////////////
          ],
        ),
      ),
    );
  }
}