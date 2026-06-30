import 'package:flutter/material.dart';
import 'pacientes_screen.dart';
import 'login_screen.dart';
import 'lecturas_screen.dart';

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

            // ALERTAS
            _buildCard(
              icon: Icons.notifications_active,
              title: "Alertas",
              subtitle: "Ver alertas generadas por el sistema",
              onTap: () {},
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