import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/api_client.dart';

/// Servicio para gestionar notificaciones push con Firebase Cloud Messaging
///
/// Funcionalidades:
/// - Solicitar permisos de notificaciones
/// - Obtener y registrar token FCM en el backend
/// - Escuchar notificaciones en foreground y background
/// - Manejar navegación según tipo de notificación
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _api = ApiClient();

  String? _fcmToken;

  /// Obtener el token FCM actual
  String? get fcmToken => _fcmToken;

  /// Inicializar el servicio de notificaciones
  /// Debe llamarse al iniciar la app
  Future<void> initialize() async {
    try {
      // Configurar notificaciones locales para Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configurar notificaciones locales para iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Cuando el usuario toca la notificación local
          if (response.payload != null) {
            debugPrint(
              '[Local Notif] 📬 Usuario tocó notificación: ${response.payload}',
            );
            // TODO: Parsear payload y navegar
          }
        },
      );

      // Crear canal de notificaciones para Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // ID debe coincidir con AndroidManifest.xml
        'Notificaciones importantes', // Nombre
        description: 'Este canal se usa para notificaciones importantes',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Solicitar permisos FCM (especialmente importante en iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            criticalAlert: false,
            announcement: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCM] ✅ Permisos de notificaciones concedidos');

        // Obtener el token FCM
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('[FCM] 🔑 Token FCM: $_fcmToken');

        // Listener para cuando el token se actualice
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('[FCM] 🔄 Token FCM actualizado: $newToken');
          _fcmToken = newToken;
          // El token se actualizará en el backend en el próximo login
        });

        // Configurar listeners de notificaciones
        _setupNotificationListeners();
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('[FCM] ⚠️ Permisos provisionales concedidos');
      } else {
        debugPrint('[FCM] ❌ Permisos de notificaciones denegados');
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Error al inicializar: $e');
    }
  }

  /// Configurar listeners para notificaciones
  void _setupNotificationListeners() {
    // Cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] 📩 Notificación recibida en foreground');
      debugPrint('[FCM] Título: ${message.notification?.title}');
      debugPrint('[FCM] Mensaje: ${message.notification?.body}');
      debugPrint('[FCM] Datos: ${message.data}');

      // Mostrar notificación local cuando la app está en foreground
      _showLocalNotification(message);
    });

    // Cuando el usuario toca la notificación y abre la app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] 📬 Usuario abrió la app desde una notificación');
      debugPrint('[FCM] Datos: ${message.data}');

      // Manejar navegación según el tipo de notificación
      _handleNotificationNavigation(message.data);
    });

    // Verificar si la app fue abierta desde una notificación mientras estaba cerrada
    _checkInitialMessage();
  }

  /// Mostrar notificación local en foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones importantes',
          channelDescription:
              'Este canal se usa para notificaciones importantes',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'SmartSales',
      message.notification?.body ?? 'Nueva notificación',
      notificationDetails,
      payload: message.data['tipo'], // Pasamos el tipo para navegación
    );

    debugPrint('[Local Notif] ✅ Notificación mostrada en foreground');
  }

  /// Verificar si la app fue abierta desde una notificación
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      debugPrint('[FCM] 🚀 App abierta desde notificación en estado cerrado');
      debugPrint('[FCM] Datos: ${initialMessage.data}');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// Manejar navegación según el tipo de notificación
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    String? tipo = data['tipo'];

    switch (tipo) {
      case 'compra_exitosa':
        // Navegar a historial de compras o detalle de venta
        int? ventaId = int.tryParse(data['venta_id'] ?? '');
        debugPrint('[FCM] 🛒 Navegar a venta: $ventaId');
        // TODO: Navigator.pushNamed(context, '/payment-history', arguments: ventaId);
        break;

      case 'stock_bajo':
        // Navegar a inventario/productos (para vendedores)
        int? productoId = int.tryParse(data['producto_id'] ?? '');
        debugPrint('[FCM] 📦 Navegar a producto: $productoId');
        // TODO: Navigator.pushNamed(context, '/product-detail', arguments: productoId);
        break;

      case 'garantia':
        // Navegar a detalle de garantía
        int? garantiaId = int.tryParse(data['garantia_id'] ?? '');
        debugPrint('[FCM] 🔧 Navegar a garantía: $garantiaId');
        // TODO: Navigator.pushNamed(context, '/guarantee-detail', arguments: garantiaId);
        break;

      default:
        debugPrint('[FCM] ⚠️ Tipo de notificación desconocido: $tipo');
    }
  }

  /// Registrar token FCM en el backend
  /// Debe llamarse después de un login exitoso
  Future<bool> registerTokenInBackend() async {
    if (_fcmToken == null) {
      debugPrint('[FCM] ❌ No hay token FCM disponible');
      return false;
    }

    try {
      debugPrint('[FCM] 📤 Enviando token al backend...');
      debugPrint('[FCM] 🔑 Token: $_fcmToken');

      await _api.post(
        'notificaciones/suscripcion/actualizar-token/',
        data: {'token_dispositivo': _fcmToken},
      );

      debugPrint('[FCM] ✅ Token FCM registrado en el backend exitosamente');
      return true;
    } catch (e) {
      debugPrint('[FCM] ❌ Error al registrar token en backend: $e');
      return false;
    }
  }

  /// Desactivar token FCM en el backend
  /// Debe llamarse al hacer logout
  Future<bool> unregisterTokenFromBackend() async {
    try {
      await _api.post('notificaciones/suscripcion/desactivar/');
      debugPrint('[FCM] ✅ Token desactivado en el backend');
      return true;
    } catch (e) {
      debugPrint('[FCM] ❌ Error al desactivar token: $e');
      return false;
    }
  }

  /// Eliminar el token FCM localmente
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] ✅ Token FCM eliminado localmente');
    } catch (e) {
      debugPrint('[FCM] ❌ Error al eliminar token: $e');
    }
  }
}
