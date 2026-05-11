import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _passwordFocusNode = FocusNode();

  String errorMessage = "";
  bool isLoading = false;
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _scrollController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorMessage = "Usuario no encontrado";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Contraseña incorrecta";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Correo inválido";
        } else {
          errorMessage = e.message ?? "Error desconocido";
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error inesperado";
      });
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ CAMBIO CLAVE: habilitado para que el teclado empuje el contenido
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFAFBFC),

      body: SafeArea(
        child: Column(
          children: [
            // ✅ Contenido scrolleable que ocupa el espacio disponible
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                // ✅ padding bottom para que el footer no tape nada
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Logo principal
                    Image.asset(
                      'assets/transparente.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 20),

                    // Logo AXIS
                    Image.asset(
                      'assets/logoAxis.png',
                      width: 120,
                      height: 50,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 16),

                    // Eslogan
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "Monitoreo inteligente y prevención temprana",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF546E7A),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Contenedor principal
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Título
                          const Text(
                            "Bienvenido",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A237E),
                              letterSpacing: 0.3,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtítulo
                          const Text(
                            "Inicia sesión para continuar",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF78909C),
                              letterSpacing: 0.1,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Campo usuario
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: emailController,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF263238),
                              ),
                              // ✅ Al confirmar en email, salta al campo contraseña
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_passwordFocusNode);
                              },
                              decoration: InputDecoration(
                                labelText: "Usuario",
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF90A4AE),
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 12),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF1A237E),
                                    size: 22,
                                  ),
                                ),
                                prefixIconConstraints:
                                    const BoxConstraints(maxHeight: 24),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1A237E),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Campo contraseña
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: passwordController,
                              // ✅ FocusNode para detectar cuando se activa y hacer scroll
                              focusNode: _passwordFocusNode,
                              obscureText: hidePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => isLoading ? null : login(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF263238),
                              ),
                              decoration: InputDecoration(
                                labelText: "Contraseña",
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF90A4AE),
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 12),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF1A237E),
                                    size: 22,
                                  ),
                                ),
                                prefixIconConstraints:
                                    const BoxConstraints(maxHeight: 24),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Icon(
                                      hidePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF1A237E),
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1A237E),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ),

                          // Mensaje error
                          if (errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEF5350),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: Color(0xFFC62828),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Botón login
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                disabledBackgroundColor:
                                    const Color(0xFF1A237E).withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                shadowColor:
                                    const Color(0xFF1A237E).withOpacity(0.3),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Iniciar sesión",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          // ✅ Espacio extra al final para que el botón no quede pegado
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ FOOTER FIJO fuera del scroll — siempre visible pero no tapa los campos
            SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 100),
                    painter: WavePainter(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      "By Ana Tulande y Erick Muñoz",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WAVES
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint darkWavePaint = Paint()
      ..color = const Color(0xFF0D1B5E)
      ..style = PaintingStyle.fill;

    final Paint lightWavePaint = Paint()
      ..color = const Color(0xFF1A3A7A).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Onda oscura
    final Path darkWavePath = Path();
    darkWavePath.moveTo(0, size.height * 0.45);
    darkWavePath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.45,
    );
    darkWavePath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.65,
      size.width,
      size.height * 0.45,
    );
    darkWavePath.lineTo(size.width, size.height);
    darkWavePath.lineTo(0, size.height);
    darkWavePath.close();
    canvas.drawPath(darkWavePath, darkWavePaint);

    // Onda clara
    final Path lightWavePath = Path();
    lightWavePath.moveTo(0, size.height * 0.60);
    lightWavePath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.45,
      size.width * 0.5,
      size.height * 0.60,
    );
    lightWavePath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.75,
      size.width,
      size.height * 0.55,
    );
    lightWavePath.lineTo(size.width, size.height);
    lightWavePath.lineTo(0, size.height);
    lightWavePath.close();
    canvas.drawPath(lightWavePath, lightWavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}