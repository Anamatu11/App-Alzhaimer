import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<void> addCaregiver(
    String uid,
    Map<String, dynamic> cuidador,
  ) async {
    try {
      final doc =
          await _firestore.collection('usuarios').doc(uid).get();

      final data = doc.data() as Map<String, dynamic>;

      final cuidadores =
          List<Map<String, dynamic>>.from(
        data['cuidadores'] ?? [],
      );

      // Contar activos
      final activos = cuidadores.where(
        (c) => c['estado'] == 'activo',
      ).length;

      // Si ya existen 3 activos, guardar el nuevo como inactivo
      final estadoNuevo =
          activos >= 3 ? 'inactivo' : 'activo';

      await _firestore.collection('usuarios').doc(uid).update({
        'cuidadores': FieldValue.arrayUnion([
          {
            'nombre': cuidador['nombre'],
            'parentesco': cuidador['parentesco'],
            'correo': cuidador['correo'],
            'celular': cuidador['celular'],
            'estado': estadoNuevo,
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error agregando cuidador: $e');
    }
  }

  // Eliminar cuidador
  Future<void> removeCaregiver(String uid, Map<String, dynamic> cuidador) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'cuidadores': FieldValue.arrayRemove([cuidador]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error eliminando cuidador: $e');
    }
  }
//
  Future<void> cambiarEstadoCuidador(
    String uid,
    Map<String, dynamic> cuidador,
  ) async {
    try {
      final doc =
          await _firestore.collection('usuarios').doc(uid).get();

      final data = doc.data() as Map<String, dynamic>;

      final cuidadores =
          List<Map<String, dynamic>>.from(
        data['cuidadores'] ?? [],
      );

      // Contar cuidadores activos
      final activos = cuidadores.where(
        (c) => c['estado'] == 'activo',
      ).length;

      // Si está inactivo y ya existen 3 activos, no permitir activarlo
      if (cuidador['estado'] == 'inactivo' && activos >= 3) {
        throw Exception(
          'Ya existen 3 cuidadores activos.',
        );
      }

      final nuevos = cuidadores.map((c) {
        if (c['correo'] == cuidador['correo']) {
          return {
            ...c,
            'estado':
                c['estado'] == 'activo'
                    ? 'inactivo'
                    : 'activo',
          };
        }
        return c;
      }).toList();

      await _firestore.collection('usuarios').doc(uid).update({
        'cuidadores': nuevos,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

////////////////////////////////////////////////////////////////
    Future<void> updateCaregiver(
      String uid,
      Map<String, dynamic> cuidadorAnterior,
      Map<String, dynamic> cuidadorNuevo,
    ) async {

      try {

        final doc =
            await _firestore.collection('usuarios').doc(uid).get();

        final data = doc.data() as Map<String, dynamic>;

        List<Map<String, dynamic>> cuidadores =
            List<Map<String, dynamic>>.from(
          data['cuidadores'] ?? [],
        );

        final index = cuidadores.indexWhere(
          (c) => c['correo'] == cuidadorAnterior['correo'],
        );

        if (index == -1) {
          throw Exception('No se encontró el cuidador.');
        }

        // Conservamos el estado 
        cuidadorNuevo['estado'] = cuidadores[index]['estado'];

        cuidadores[index] = cuidadorNuevo;
        print("ANTES:");
        print(cuidadores[index]);

        print("DESPUÉS:");
        print(cuidadorNuevo);

        await _firestore.collection('usuarios').doc(uid).update({

          'cuidadores': cuidadores,

          'updatedAt': FieldValue.serverTimestamp(),

        });

      } catch (e) {

        throw Exception('Error actualizando cuidador: $e');

      }

    }


  // Stream de datos del usuario (para actualizaciones en tiempo real)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _firestore.collection('usuarios').doc(uid).snapshots();
  }
}
