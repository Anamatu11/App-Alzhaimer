import 'package:flutter/material.dart';
import 'lecturas_paciente_screen.dart';
import 'dataset_general_screen.dart';

class LecturasScreen extends StatelessWidget {
  const LecturasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),

      appBar: AppBar(
        title: const Text('Lecturas'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // POR PACIENTE
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Color(0xFF1A237E),
              ),
              title: const Text(
                'Por paciente',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Consultar lecturas individuales',
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LecturasPacienteScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
            // DATASET GENERAL
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.table_chart,
                  color: Color(0xFF1A237E),
                ),
                title: const Text(
                  'Dataset general',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Exportar dataset completo para IA',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DatasetGeneralScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

