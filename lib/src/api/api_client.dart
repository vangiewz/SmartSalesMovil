import 'package:dio/dio.dart';

/// Toggle to switch between local and production API base URLs.
const bool USE_PROD = true; // Cambia a true para producción

const BASE_URLS = {
  'local': 'http://127.0.0.1:8000/api/',
  'prod': 'https://smartsalesbackend.onrender.com/api/',
};

String get baseUrl => USE_PROD ? BASE_URLS['prod']! : BASE_URLS['local']!;

class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient._internal(this._dio) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers['content-type'] = 'application/json';
    _dio.options.headers['X-Platform'] =
        'mobile'; // Activa auto-confirmación en backend
  }

  static final ApiClient _instance = ApiClient._internal(Dio());

  factory ApiClient() => _instance;

  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  // Convenience API methods (examples based on the backend spec)
  Future<Map<String, dynamic>> getPublicStripeKey() async {
    final r = await get('/pagos/public-key/');
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> listarProductos({
    Map<String, dynamic>? params,
  }) async {
    final r = await get('/listadoproductos/', queryParameters: params);
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> iniciarCheckout(
    Map<String, dynamic> payload,
  ) async {
    final r = await post('/pagos/iniciar-checkout/', data: payload);
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> confirmarPago(String paymentIntentId) async {
    final r = await post(
      '/pagos/confirmar-pago/',
      data: {'paymentIntentId': paymentIntentId},
    );
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> getMe() async {
    final r = await get('/me/');
    return Map<String, dynamic>.from(r.data);
  }

  Future<List<dynamic>> getDirecciones() async {
    final r = await get('/direcciones/');
    return List<dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> createDireccion(String direccion) async {
    final r = await post('/direcciones/', data: {'direccion': direccion});
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> deleteDireccion(int id) async {
    await _dio.delete('/direcciones/\$id/'.replaceAll('\$id', id.toString()));
  }

  // Warranty endpoints
  Future<List<dynamic>> ventasElegiblesGarantia() async {
    final r = await get('/garantia/ventas-elegibles/');
    return List<dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> crearGarantia(
    Map<String, dynamic> payload,
  ) async {
    final r = await post('/garantia/crear/', data: payload);
    return Map<String, dynamic>.from(r.data);
  }
}
