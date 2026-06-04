import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  String? currentUserName = '';
  String? profileImageUrl = '';
  List<Map<String, dynamic>> cuidadores = [];
  bool isLoading = true;
  bool isUploading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
  try {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String? emailUsuario = currentUser.email;

    // Buscar el paciente asociado al correo del cuidador
    QuerySnapshot pacientesSnapshot =
        await _firestore.collection('usuarios').get();

    Map<String, dynamic>? userData;

    for (var doc in pacientesSnapshot.docs) {
      Map<String, dynamic> data =
          doc.data() as Map<String, dynamic>;

      if (data['cuidadores'] != null &&
          data['cuidadores'] is List) {

        List<dynamic> listaCuidadores =
            data['cuidadores'];

        bool tieneAcceso =
            listaCuidadores.any((cuidador) {
          return cuidador['correo'] == emailUsuario;
        });

        if (tieneAcceso) {
          userData = data;
          break;
        }
      }
    }

    if (userData != null) {
      final Map<String, dynamic> data = userData;
      print('📱 DEBUG: Datos del paciente: $data');
      print(
          '📱 DEBUG: Cuidadores encontrados: ${data['cuidadores']}');

      setState(() {
        currentUserName =
            data['nombre'] ?? 'Paciente';

        profileImageUrl =
            data['fotoUrl'] ?? '';

        if (data['cuidadores'] != null &&
            data['cuidadores'] is List &&
            (data['cuidadores'] as List)
                .isNotEmpty) {

          print(
              '📱 DEBUG: Cuidadores detectados, cantidad: ${(data['cuidadores'] as List).length}');

          cuidadores =
              List<Map<String, dynamic>>.from(
            (data['cuidadores'] as List)
                .map((c) {
              return {
                'nombre': c['nombre'] ?? '',
                'parentesco':
                    c['parentesco'] ?? '',
                'celular':
                    c['celular'] ?? '',
              };
            }),
          );

          print(
              '📱 DEBUG: Cuidadores procesados: $cuidadores');

        } else {
          print(
              '📱 DEBUG: No hay cuidadores o campo vacío');

          cuidadores = [];
        }
      });

    } else {

      print(
          '📱 DEBUG: No se encontró paciente asociado al correo');

      setState(() {
        currentUserName =
            currentUser.email ?? 'Usuario';

        profileImageUrl = '';
        cuidadores = [];

        errorMessage =
            'No existe ningún paciente asociado a este cuidador.';
      });
    }

  } catch (e) {

    print('❌ ERROR cargando datos: $e');

    setState(() {
      errorMessage =
          'Error al cargar datos: ${e.toString()}';
    });

  } finally {

    setState(() {
      isLoading = false;
    });

  }
}





















  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      setState(() {
        isUploading = true;
      });

      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      File imageFile = File(pickedFile.path);

      // Subir a Firebase Storage
      Reference ref = _storage
          .ref()
          .child('usuarios/${currentUser.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();

      // Actualizar Firestore con la URL
      await _firestore.collection('usuarios').doc(currentUser.uid).update({
        'fotoUrl': downloadUrl,
      });

      setState(() {
        profileImageUrl = downloadUrl;
        isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto actualizada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUploading = false;
        errorMessage = 'Error al subir foto: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content:
              const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _auth.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 📋 TARJETA PRINCIPAL DE PERFIL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 📸 FOTO DE PERFIL CON ÍCONO DE CÁMARA
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              // Foto principal
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: (profileImageUrl != null &&
                                          profileImageUrl!.isNotEmpty &&
                                          profileImageUrl!.startsWith('http'))
                                      ? NetworkImage(profileImageUrl!)
                                      : const AssetImage(
                                              'assets/juanperez.jpg')
                                          as ImageProvider,
                                  onBackgroundImageError: (exception, stackTrace) {
                                    // Si falla cargar la imagen, usa la imagen por defecto
                                    setState(() {
                                      profileImageUrl = '';
                                    });
                                  },
                                ),
                              ),

                              // Botón de cámara
                              GestureDetector(
                                onTap: isUploading ? null : _pickAndUploadImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            const Color(0xFF7C3AED)
                                                .withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: isUploading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 👤 NOMBRE
                          Text(
                            currentUserName ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 📝 DESCRIPCIÓN
                          Text(
                            'Gestiona tu información y la de tus cuidadores',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Mostrar errores si existen
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (errorMessage.isNotEmpty) const SizedBox(height: 28),

                  // SECCIÓN CUIDADORES
                  if (cuidadores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.supervised_user_circle,
                                color: const Color(0xFF1A237E),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Cuidadores con acceso',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Las siguientes personas tienen acceso a la información y notificaciones de ${currentUserName ?? 'la cuenta'}.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Lista de cuidadores
                          ..._buildCuidadoresList(),
                        ],
                      ),
                    )
                  else if (!isLoading && errorMessage.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay cuidadores agregados',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agrega cuidadores en Firebase',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // 🔐 BOTÓN CERRAR SESIÓN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: _logout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFF1A237E).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando perfil...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCuidadoresList() {
    return cuidadores.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> cuidador = entry.value;

      return Container(
        margin: EdgeInsets.only(
          bottom: index == cuidadores.length - 1 ? 0 : 12,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del cuidador
            Text(
              cuidador['nombre'] ?? 'Sin nombre',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 8),

            // Parentesco
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: const Color(0xFF7C3AED).withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Parentesco: ${cuidador['parentesco'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Teléfono
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: Colors.green.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  cuidador['celular'] ?? 'Sin teléfono',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
