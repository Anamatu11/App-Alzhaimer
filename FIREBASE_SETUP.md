# 📱 Guía de Configuración de Firebase

## 1. Estructura de Datos en Firestore

Tu aplicación espera la siguiente estructura en Firebase Firestore:

### Colección: `usuarios`

Cada usuario debe tener un documento con su UID (ID único de Firebase Auth) que contenga:

```json
{
  "uid": "abc123xyz...",
  "email": "usuario@email.com",
  "nombre": "Juan Pérez",
  "fotoUrl": "https://firebasestorage.googleapis.com/...",
  "cuidadores": [
    {
      "nombre": "María González",
      "parentesco": "Hija",
      "celular": "3012345678"
    },
    {
      "nombre": "Carlos López",
      "parentesco": "Nieto",
      "celular": "3019876543"
    }
  ],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## 2. Cómo Configurar tus Datos en Firebase Console

### Paso 1: Ir a Firestore Database
1. Abre [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto "App-Alzhaimer"
3. Ve a **Firestore Database** en el menú izquierdo

### Paso 2: Crear la Colección "usuarios"
1. Haz clic en **"Create collection"**
2. Nombre: `usuarios`
3. Haz clic en **Next**

### Paso 3: Agregar tu Documento de Usuario
1. En **Document ID**, pega tu UID de Firebase
   - Puedes encontrarlo en **Authentication** > Tu usuario > **User UID**
2. Agregua los campos:

| Campo | Tipo | Valor |
|-------|------|-------|
| `uid` | String | Tu UID |
| `email` | String | tu@email.com |
| `nombre` | String | Tu nombre |
| `fotoUrl` | String | (dejar vacío por ahora) |
| `cuidadores` | Array | (array vacío []) |
| `createdAt` | Timestamp | (selecciona la fecha actual) |
| `updatedAt` | Timestamp | (selecciona la fecha actual) |

### Paso 4: Agregar Cuidadores
1. Abre tu documento de usuario
2. En el campo `cuidadores`, haz clic en **Add element**
3. Selecciona **Map** y añade:

```
{
  "nombre": "María González",
  "parentesco": "Hija",
  "telefono": "3012345678"
}
```

4. Repite para cada cuidador

## 3. Cargar Foto de Perfil

### Opción A: Desde la App
1. En la pantalla de Perfil (Ajustes)
2. Haz clic en el botón de **cámara** en la foto de perfil
3. Selecciona una foto de tu galería
4. La app subirá automáticamente a Firebase Storage y actualizará Firestore

### Opción B: Desde Firebase Console
1. Ve a **Storage**
2. Crea esta estructura: `usuarios/[TU_UID]/profile_imagen.jpg`
3. Sube tu imagen
4. En Firestore, actualiza el campo `fotoUrl` con la URL pública de la imagen

## 4. Estructura Completa Ejemplo

```yaml
Colección: usuarios
├── Document: "abc123xyz..." (tu UID)
│   ├── uid: "abc123xyz..."
│   ├── email: "juan@email.com"
│   ├── nombre: "Juan Pérez"
│   ├── fotoUrl: "" (vacío al inicio)
│   ├── cuidadores: Array
│   │   ├── [0] Map
│   │   │   ├── nombre: "María González"
│   │   │   ├── parentesco: "Hija"
│   │   │   └── celular: "3012345678"
│   │   └── [1] Map
│   │       ├── nombre: "Carlos López"
│   │       ├── parentesco: "Nieto"
│   │       └── celular: "3019876543"
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
```

## 5. Solucionar Problemas

### Error: "No object exists at the desired reference"
- Significa que intenta cargar una foto que no existe
- **Solución**: Asegúrate de que `fotoUrl` esté vacío o sea una URL válida

### No aparecen los datos del usuario
- Verifica que el UID coincida exactamente con tu UID de Firebase Auth
- Comprueba que hayas guardado los cambios en Firestore
- Recarga la app

### No aparecen los cuidadores
- Asegúrate de que `cuidadores` es un Array (no un objeto)
- Verifica que cada cuidador tenga los 3 campos: nombre, parentesco, celular

## 6. Seguridad en Firestore (Reglas)

Ve a **Firestore** > **Rules** y usa estas reglas básicas:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /usuarios/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
  }
}
```

Esto asegura que cada usuario solo pueda ver/editar sus propios datos.

---

## 7. Contacto y Soporte

Si tienes problemas:
1. Verifica la consola de Firebase para errores
2. Revisa que los tipos de datos sean correctos
3. Comprueba que tu app esté conectada al proyecto Firebase correcto

¡Listo! Tu app está configurada. 🎉
