// ignore_for_file: unused_import
import 'package:flutter/foundation.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

/// Servicio para gestionar operaciones de Firebase
///
/// IMPORTANTE: Descomentar los imports y código después de ejecutar 'flutterfire configure'
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Singleton instances (descomentar después de configurar Firebase)
  // FirebaseFirestore get firestore => FirebaseFirestore.instance;
  // FirebaseStorage get storage => FirebaseStorage.instance;
  // FirebaseMessaging get messaging => FirebaseMessaging.instance;

  /// Inicializar servicios de Firebase
  Future<void> initialize() async {
    try {
      // TODO: Descomentar después de configurar Firebase
      // await _initializeMessaging();
      debugPrint('[FIREBASE] Servicios inicializados');
    } catch (e) {
      debugPrint('[FIREBASE] Error al inicializar: $e');
    }
  }

  /// Configurar Firebase Cloud Messaging para notificaciones push
  // Future<void> _initializeMessaging() async {
  //   // Solicitar permisos para notificaciones
  //   NotificationSettings settings = await messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  //
  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     debugPrint('[FCM] Permisos de notificación concedidos');
  //
  //     // Obtener token FCM
  //     String? token = await messaging.getToken();
  //     debugPrint('[FCM] Token: $token');
  //
  //     // Escuchar cambios en el token
  //     messaging.onTokenRefresh.listen((newToken) {
  //       debugPrint('[FCM] Nuevo token: $newToken');
  //       // TODO: Enviar token al backend
  //     });
  //
  //     // Configurar handlers de mensajes
  //     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  //     FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  //   } else {
  //     debugPrint('[FCM] Permisos de notificación denegados');
  //   }
  // }

  /// Manejar mensajes cuando la app está en primer plano
  // void _handleForegroundMessage(RemoteMessage message) {
  //   debugPrint('[FCM] Mensaje recibido en primer plano: ${message.notification?.title}');
  //   // TODO: Mostrar notificación local o actualizar UI
  // }

  /// Manejar cuando el usuario toca una notificación
  // void _handleMessageOpenedApp(RemoteMessage message) {
  //   debugPrint('[FCM] Notificación tocada: ${message.data}');
  //   // TODO: Navegar a la pantalla correspondiente según message.data
  // }

  /// Subir imagen a Firebase Storage
  ///
  /// [filePath]: Ruta local del archivo
  /// [storagePath]: Ruta en Firebase Storage (ej: 'evidencias/garantia_123.jpg')
  ///
  /// Retorna la URL de descarga pública
  // Future<String> uploadImage(String filePath, String storagePath) async {
  //   try {
  //     File file = File(filePath);
  //     Reference ref = storage.ref().child(storagePath);
  //
  //     UploadTask uploadTask = ref.putFile(file);
  //     TaskSnapshot snapshot = await uploadTask;
  //
  //     String downloadUrl = await snapshot.ref.getDownloadURL();
  //     debugPrint('[STORAGE] Imagen subida: $downloadUrl');
  //
  //     return downloadUrl;
  //   } catch (e) {
  //     debugPrint('[STORAGE] Error al subir imagen: $e');
  //     rethrow;
  //   }
  // }

  /// Eliminar archivo de Firebase Storage
  // Future<void> deleteFile(String storagePath) async {
  //   try {
  //     Reference ref = storage.ref().child(storagePath);
  //     await ref.delete();
  //     debugPrint('[STORAGE] Archivo eliminado: $storagePath');
  //   } catch (e) {
  //     debugPrint('[STORAGE] Error al eliminar archivo: $e');
  //     rethrow;
  //   }
  // }

  /// Guardar datos en Firestore
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// await FirebaseService().saveToFirestore(
  ///   collection: 'garantias',
  ///   docId: 'garantia_123',
  ///   data: {
  ///     'usuario_id': 'abc',
  ///     'producto_id': 456,
  ///     'motivo': 'Producto defectuoso',
  ///     'evidencias': ['url1', 'url2'],
  ///     'fecha': FieldValue.serverTimestamp(),
  ///   },
  /// );
  /// ```
  // Future<void> saveToFirestore({
  //   required String collection,
  //   required String docId,
  //   required Map<String, dynamic> data,
  // }) async {
  //   try {
  //     await firestore.collection(collection).doc(docId).set(
  //       data,
  //       SetOptions(merge: true),
  //     );
  //     debugPrint('[FIRESTORE] Documento guardado: $collection/$docId');
  //   } catch (e) {
  //     debugPrint('[FIRESTORE] Error al guardar: $e');
  //     rethrow;
  //   }
  // }

  /// Leer documento de Firestore
  // Future<Map<String, dynamic>?> getFromFirestore({
  //   required String collection,
  //   required String docId,
  // }) async {
  //   try {
  //     DocumentSnapshot doc = await firestore.collection(collection).doc(docId).get();
  //
  //     if (doc.exists) {
  //       return doc.data() as Map<String, dynamic>?;
  //     }
  //     return null;
  //   } catch (e) {
  //     debugPrint('[FIRESTORE] Error al leer: $e');
  //     rethrow;
  //   }
  // }

  /// Escuchar cambios en tiempo real de Firestore
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// FirebaseService().listenToFirestore(
  ///   collection: 'garantias',
  ///   docId: 'garantia_123',
  ///   onData: (data) {
  ///     print('Datos actualizados: $data');
  ///   },
  /// );
  /// ```
  // Stream<Map<String, dynamic>?> listenToFirestore({
  //   required String collection,
  //   required String docId,
  // }) {
  //   return firestore.collection(collection).doc(docId).snapshots().map((snapshot) {
  //     if (snapshot.exists) {
  //       return snapshot.data() as Map<String, dynamic>?;
  //     }
  //     return null;
  //   });
  // }
}
