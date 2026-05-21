import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear documento de usuario
  Future<void> createUserDocument(User user) async {
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
      throw Exception('Error creando documento de usuario: $e');
    }
  }

  // Obtener datos del usuario
  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      throw Exception('Error obteniendo datos: $e');
    }
  }

  // Actualizar nombre del usuario
  Future<void> updateUserName(String uid, String nombre) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'nombre': nombre,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error actualizando nombre: $e');
    }
  }

  // Actualizar URL de foto de perfil
  Future<void> updateProfileImageUrl(String uid, String fotoUrl) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'fotoUrl': fotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error actualizando foto: $e');
    }
  }

  // Agregar cuidador
  // Estructura esperada: {'nombre': '...', 'parentesco': '...', 'celular': '...'}
  Future<void> addCaregiver(String uid, Map<String, String> cuidador) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'cuidadores': FieldValue.arrayUnion([cuidador]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error agregando cuidador: $e');
    }
  }

  // Eliminar cuidador
  Future<void> removeCaregiver(String uid, Map<String, String> cuidador) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'cuidadores': FieldValue.arrayRemove([cuidador]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error eliminando cuidador: $e');
    }
  }

  // Stream de datos del usuario (para actualizaciones en tiempo real)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _firestore.collection('usuarios').doc(uid).snapshots();
  }
}
