import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final TextEditingController buscarController = TextEditingController();

  String filtro = "";

  String formatearFecha(dynamic fecha) {
    if (fecha == null) return "-";

    if (fecha is Timestamp) {
      return DateFormat("dd/MM/yyyy").format(fecha.toDate());
    }

    return "-";
  }

  Map<String, dynamic> _extraerDatosUsuario(Map<String, dynamic> datos) {
    final cuidadoresRaw = datos["cuidadores"];

    final cuidadores = cuidadoresRaw is Map
        ? Map<String, dynamic>.from(cuidadoresRaw)
        : <String, dynamic>{};

    // Intenta primero el campo anidado (cuidadores.campo).
    // Si no existe o viene vacío, cae al campo plano en el documento
    // (por si algunos registros aún no tienen el campo anidado).
    String valor(String campo) {
      final anidado = cuidadores[campo];
      if (anidado != null && anidado.toString().isNotEmpty) {
        return anidado.toString();
      }

      final plano = datos[campo];
      return (plano ?? "").toString();
    }

    return {
      "email": valor("email"),
      "nombre": valor("nombre"),
      "uid": valor("uid"),
      "createdAt": datos["createdAt"],
      "updatedAt": datos["updatedAt"],
    };
  }

  void _mostrarDetalleUsuario(
    BuildContext context,
    Map<String, dynamic> usuario,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Información del usuario",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Divider(),

              Text(
                "Correo: ${usuario["email"].toString().isEmpty ? "-" : usuario["email"]}",
              ),

              const SizedBox(height: 8),

              Text(
                "Nombre: ${usuario["nombre"].toString().isEmpty ? "-" : usuario["nombre"]}",
              ),

              const SizedBox(height: 8),

              Text(
                "UID: ${usuario["uid"].toString().isEmpty ? "-" : usuario["uid"]}",
              ),

              const SizedBox(height: 8),

              Text(
                "Fecha creación: ${formatearFecha(usuario["createdAt"])}",
              ),

              const SizedBox(height: 8),

              Text(
                "Último acceso: ${formatearFecha(usuario["updatedAt"])}",
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  // Usa una app secundaria de Firebase solo para crear la cuenta nueva.
  // Esto evita que createUserWithEmailAndPassword cierre la sesión del
  // Administrador que está usando la app (comportamiento por defecto
  // de FirebaseAuth: te deja autenticado como el usuario recién creado).
  Future<FirebaseApp> _obtenerAppSecundaria() async {
    const nombreApp = "AgregarUsuarioApp";

    final existente = Firebase.apps.where((app) => app.name == nombreApp);

    if (existente.isNotEmpty) {
      return existente.first;
    }

    return Firebase.initializeApp(
      name: nombreApp,
      options: Firebase.app().options,
    );
  }

  Future<void> _crearUsuario({
    required String email,
    required String nombre,
    required String password,
  }) async {
    final appSecundaria = await _obtenerAppSecundaria();
    final authSecundaria = FirebaseAuth.instanceFor(app: appSecundaria);

    try {
      final credenciales = await authSecundaria.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credenciales.user!.uid;

      try {
        await credenciales.user?.updateDisplayName(nombre);
      } catch (_) {
        // No es crítico si falla; el nombre igual queda guardado en Firestore.
      }

      await FirebaseFirestore.instance.collection("usuarios").doc(uid).set({
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "cuidadores": {
          "email": email,
          "nombre": nombre,
          "uid": uid,
        },
      });
    } finally {
      await authSecundaria.signOut();
      await appSecundaria.delete();
    }
  }

  String _mensajeError(FirebaseAuthException error) {
    switch (error.code) {
      case "email-already-in-use":
        return "Ese correo ya está registrado.";
      case "invalid-email":
        return "El correo electrónico no es válido.";
      case "weak-password":
        return "La contraseña es muy débil (mínimo 6 caracteres).";
      default:
        return "No se pudo crear el usuario: ${error.message}";
    }
  }

  void _mostrarFormularioAgregarUsuario(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final nombreController = TextEditingController();
    final passwordController = TextEditingController();

    bool cargando = false;
    bool ocultarPassword = true;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (contextModal) {
        return StatefulBuilder(
          builder: (contextModal, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(contextModal).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Agregar usuario",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    if (error != null) ...[
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                    ],

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Correo electrónico",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final texto = value?.trim() ?? "";
                        if (texto.isEmpty) return "El correo es obligatorio.";
                        if (!texto.contains("@") || !texto.contains(".")) {
                          return "El correo no es válido.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: "Nombre",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? "").trim().isEmpty) {
                          return "El nombre es obligatorio.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: passwordController,
                      obscureText: ocultarPassword,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setModalState(() {
                              ocultarPassword = !ocultarPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? "").length < 6) {
                          return "Mínimo 6 caracteres.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A237E),
                              side: const BorderSide(
                                color: Color(0xFF1A237E),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onPressed: cargando
                                ? null
                                : () {
                                    FocusScope.of(contextModal).unfocus();
                                    Navigator.of(contextModal).pop();
                                  },
                            child: const Text("Cancelar"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onPressed: cargando
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setModalState(() {
                                      cargando = true;
                                      error = null;
                                    });

                                    try {
                                      await _crearUsuario(
                                        email: emailController.text.trim(),
                                        nombre: nombreController.text.trim(),
                                        password: passwordController.text,
                                      );

                                      // Se le quita el foco a los campos de
                                      // texto antes de cerrar el modal, para
                                      // evitar el error "_dependents.isEmpty"
                                      // que ocurre si se destruye un campo
                                      // mientras aún tiene el teclado abierto.
                                      if (contextModal.mounted) {
                                        FocusScope.of(contextModal).unfocus();
                                      }

                                      if (contextModal.mounted) {
                                        Navigator.of(contextModal).pop();
                                      }

                                      // Se avisa en la pantalla de fondo
                                      // (no en el modal, que ya se cerró).
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Usuario creado exitosamente.",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      setModalState(() {
                                        cargando = false;
                                        error = _mensajeError(e);
                                      });
                                    } catch (e) {
                                      setModalState(() {
                                        cargando = false;
                                        error = "Ocurrió un error inesperado.";
                                      });
                                    }
                                  },
                            child: cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Guardar",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      emailController.dispose();
      nombreController.dispose();
      passwordController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Gestión de usuarios"),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A237E),
        tooltip: "Agregar usuario",
        onPressed: () => _mostrarFormularioAgregarUsuario(context),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: buscarController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre, correo o UID",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  filtro = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("usuarios")
                    .snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text("No existen usuarios registrados."),
                    );
                  }

                  final usuarios = snapshot.data!.docs
                      .where((doc) => !doc.id.startsWith("Paciente-"))
                      .map((doc) {
                        final datos = doc.data() as Map<String, dynamic>;
                        return _extraerDatosUsuario(datos);
                      })
                      .where((usuario) {
                        final email =
                            usuario["email"].toString().toLowerCase();
                        final nombre =
                            usuario["nombre"].toString().toLowerCase();
                        final uid = usuario["uid"].toString().toLowerCase();

                        return email.contains(filtro) ||
                            nombre.contains(filtro) ||
                            uid.contains(filtro);
                      })
                      .toList();

                  if (usuarios.isEmpty) {
                    return const Center(
                      child: Text("No se encontraron usuarios."),
                    );
                  }

                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,

                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: DataTable(
                          showCheckboxColumn: false,
                          columnSpacing: 32,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          dataTextStyle: const TextStyle(
                            color: Colors.black87,
                          ),

                          columns: const [
                            DataColumn(
                              label: Text("Correo electrónico"),
                            ),
                            DataColumn(
                              label: Text("Nombre"),
                            ),
                            DataColumn(
                              label: Text("UID usuario"),
                            ),
                            DataColumn(
                              label: Text("Fecha creación"),
                            ),
                            DataColumn(
                              label: Text("Último acceso"),
                            ),
                          ],

                          rows: usuarios.map((usuario) {
                            return DataRow(
                              onSelectChanged: (_) => _mostrarDetalleUsuario(
                                context,
                                usuario,
                              ),
                              cells: [
                                DataCell(
                                  Text(
                                    usuario["email"].toString().isEmpty
                                        ? "-"
                                        : usuario["email"].toString(),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    usuario["nombre"].toString().isEmpty
                                        ? "-"
                                        : usuario["nombre"].toString(),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    usuario["uid"].toString().isEmpty
                                        ? "-"
                                        : usuario["uid"].toString(),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatearFecha(usuario["createdAt"]),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    formatearFecha(usuario["updatedAt"]),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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