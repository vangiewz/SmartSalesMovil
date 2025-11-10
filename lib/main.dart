import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'src/theme/app_theme.dart';
import 'src/services/auth_service.dart';
import 'src/services/cart_service.dart';
import 'src/services/notification_service.dart';
import 'src/widgets/auth_gate.dart';
import 'src/config/routes.dart';

/// Handler para notificaciones en background
/// Debe ser una función de nivel superior (no puede estar dentro de una clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM Background] 📩 Notificación recibida: ${message.messageId}');
  debugPrint('[FCM Background] Título: ${message.notification?.title}');
  debugPrint('[FCM Background] Mensaje: ${message.notification?.body}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService and restore token if present
  await AuthService.init();

  // Initialize Stripe with a placeholder key (will be set properly when user logs in)
  // Using a placeholder prevents initialization errors
  Stripe.publishableKey = 'pk_test_placeholder';

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FIREBASE] Inicializado correctamente');

  // Configurar handler de notificaciones en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar servicio de notificaciones
  await NotificationService().initialize();

  // Inicializar formateo de fechas para español
  await initializeDateFormatting('es_MX', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartService(),
      child: MaterialApp(
        title: 'SmartSales Móvil',
        theme: AppTheme.light(),
        home: const AuthGate(),
        onGenerateRoute: RouteGenerator.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
