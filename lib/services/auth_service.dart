import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Valida que los campos no estén vacíos
  String? validateEmptyFields(String email, String password) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return "Debes completar todos los campos.";
    }
    return null;
  }

  /// Valida el formato del correo electrónico
  String? validateEmailFormat(String email) {
    // Validación simple pero efectiva para correos
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return "Ingresa un correo electrónico válido.";
    }
    
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return "Ingresa un correo electrónico válido.";
    }
    
    if (!parts[1].contains('.')) {
      return "Ingresa un correo electrónico válido.";
    }
    
    return null;
  }

  /// Realiza el login de forma segura
  /// Retorna un Map con {'success': bool, 'message': String?, 'user': User?}
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Validar campos vacíos
      final emptyFieldsError = validateEmptyFields(email, password);
      if (emptyFieldsError != null) {
        return {
          'success': false,
          'message': emptyFieldsError,
          'user': null,
        };
      }

      // Validar formato de correo
      final emailFormatError = validateEmailFormat(email);
      if (emailFormatError != null) {
        return {
          'success': false,
          'message': emailFormatError,
          'user': null,
        };
      }

      // Intentar login
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Crear documento de usuario si no existe
      await _createUserDocumentIfNotExists(userCredential.user!);

      return {
        'success': true,
        'message': null,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      // Manejar todas las excepciones de autenticación de forma segura
      // No revelar si el usuario existe o no, ni detalles de la contraseña
      return {
        'success': false,
        'message': _handleAuthException(e),
        'user': null,
      };
    } catch (e) {
      // Detectar si es un error de conexión
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException') ||
          e.toString().contains('No host specified') ||
          e.toString().contains('Connection refused')) {
        return {
          'success': false,
          'message': "No fue posible conectar con el servidor. Intenta nuevamente.",
          'user': null,
        };
      }

      // Error inesperado genérico
      return {
        'success': false,
        'message': "Ocurrió un error inesperado. Inténtalo más tarde.",
        'user': null,
      };
    }
  }

  /// Maneja las excepciones de Firebase Auth de forma segura
  /// Devuelve mensajes genéricos sin revelar información sensible
  String _handleAuthException(FirebaseAuthException e) {
    // Mapeo seguro de códigos de error a mensajes genéricos
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
      case 'user-disabled':
      case 'invalid-credential':
        // No revelar si el usuario existe o si la contraseña es incorrecta
        return "Credenciales inválidas. Verifica tus datos e intenta nuevamente.";

      case 'too-many-requests':
        return "Demasiados intentos de inicio de sesión. Intenta más tarde.";

      case 'network-request-failed':
      case 'operation-not-allowed':
        return "No fue posible conectar con el servidor. Intenta nuevamente.";

      default:
        // Para cualquier otro error, mostrar mensaje genérico
        return "Credenciales inválidas. Verifica tus datos e intenta nuevamente.";
    }
  }

  /// Crea documento de usuario en Firestore si no existe
  Future<void> _createUserDocumentIfNotExists(User user) async {
    try {
      final userDoc = _firestore.collection('usuarios').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'nombre': user.displayName ?? 'Usuario',
          'fotoUrl': '',
          'cuidadores': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log interno, pero no detener el login
      print('Error creando documento de usuario: $e');
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  /// Obtiene el usuario actual
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
