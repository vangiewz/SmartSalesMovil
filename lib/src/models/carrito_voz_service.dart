// lib/services/carrito_voz_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/carrito_voz.dart';

class CarritoVozService {
  // TODO: pon aquí tu baseUrl real
  static const String baseUrl = 'https://TU_API_BACKEND'; // sin barra final

  static Future<CarritoVozResponse> armarCarritoDesdeTexto({
    required String texto,
    required String usuarioId,
    int limiteItems = 10,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/carrito-voz/carrito-voz/');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = jsonEncode({
      'usuario_id': usuarioId,
      'texto': texto.trim(),
      'limite_items': limiteItems,
    });

    final resp = await http.post(uri, headers: headers, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return CarritoVozResponse.fromJson(data);
  }
}
