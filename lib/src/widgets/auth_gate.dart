import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await AuthService().currentAccessToken();
      if (token != null && token.isNotEmpty) {
        // Validate token with backend
        final profile = await AuthService().getMe();
        if (profile['id'] != null) {
          setState(() {
            _authenticated = true;
            _checking = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Auth check failed: $e');
      // Token inválido o expirado - limpiarlo
      await AuthService().signOut();
    }

    setState(() {
      _authenticated = false;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _authenticated ? const HomeScreen() : const LoginScreen();
  }
}
