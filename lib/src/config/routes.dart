import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/addresses_screen.dart';
import '../screens/payment_history_screen.dart';
import '../screens/comercial_management_screen.dart';
import '../screens/guarantees_screen.dart';
import '../screens/create_claim_screen.dart';
import '../screens/my_claims_screen.dart';
import '../screens/dashboard_ejecutivo_screen.dart';
import '../models/product_model.dart';

/// Nombres de rutas centralizados (estilo React Router)
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String addresses = '/addresses';
  static const String paymentHistory = '/payment-history';
  static const String comercialManagement = '/comercial-management';
  static const String guarantees = '/guarantees';
  static const String createClaim = '/create-claim';
  static const String myClaims = '/my-claims';
  static const String dashboardEjecutivo = '/dashboard-ejecutivo';
}

/// Generador de rutas con argumentos tipados
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.products:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());

      case AppRoutes.productDetail:
        final product = settings.arguments as ProductModel;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        );

      case AppRoutes.cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case AppRoutes.checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());

      case AppRoutes.addresses:
        return MaterialPageRoute(builder: (_) => const AddressesScreen());

      case AppRoutes.paymentHistory:
        return MaterialPageRoute(builder: (_) => const PaymentHistoryScreen());

      case AppRoutes.comercialManagement:
        return MaterialPageRoute(
          builder: (_) => const ComercialManagementScreen(),
        );

      case AppRoutes.guarantees:
        return MaterialPageRoute(builder: (_) => const GuaranteesScreen());

      case AppRoutes.createClaim:
        return MaterialPageRoute(builder: (_) => const CreateClaimScreen());

      case AppRoutes.myClaims:
        return MaterialPageRoute(builder: (_) => const MyClaimsScreen());

      case AppRoutes.dashboardEjecutivo:
        return MaterialPageRoute(
          builder: (_) => const DashboardEjecutivoScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}
