import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

/// AuthService - Usa los endpoints del backend (/api/login/, /api/register/)
/// El backend valida los JWTs de Supabase internamente.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final ApiClient _api = ApiClient();

  static Future<void> init() async {
    // On startup, restore token from secure storage if present
    final token = await const FlutterSecureStorage().read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      ApiClient().setAuthToken(token);
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await _api.post(
      'login/',
      data: {'email': email, 'password': password},
    );

    final data = Map<String, dynamic>.from(response.data);
    final tokens = data['tokens'] as Map<String, dynamic>?;
    final access = tokens?['access'] as String?;

    if (access != null && access.isNotEmpty) {
      await _storage.write(key: 'access_token', value: access);
      _api.setAuthToken(access);
    }

    return data;
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
  }) async {
    final response = await _api.post(
      'register/',
      data: {
        'email': email,
        'password': password,
        'nombre': nombre,
        if (telefono != null) 'telefono': telefono,
      },
    );

    final data = Map<String, dynamic>.from(response.data);
    final tokens = data['tokens'] as Map<String, dynamic>?;
    final access = tokens?['access'] as String?;

    if (access != null && access.isNotEmpty) {
      await _storage.write(key: 'access_token', value: access);
      _api.setAuthToken(access);
    }

    return data;
  }

  Future<void> signOut() async {
    await _storage.delete(key: 'access_token');
    _api.clearAuthToken();
  }

  Future<String?> currentAccessToken() async {
    final stored = await _storage.read(key: 'access_token');
    return stored;
  }

  Future<Map<String, dynamic>> getMe() async {
    return await _api.getMe();
  }
}
