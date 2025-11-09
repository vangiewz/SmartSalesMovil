import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'src/theme/app_theme.dart';
import 'src/services/auth_service.dart';
import 'src/services/cart_service.dart';
import 'src/widgets/auth_gate.dart';
import 'src/config/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AuthService and restore token if present
  await AuthService.init();

  // Initialize Stripe with a placeholder key (will be set properly when user logs in)
  // Using a placeholder prevents initialization errors
  Stripe.publishableKey = 'pk_test_placeholder';

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
