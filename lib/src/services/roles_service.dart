import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/rol_model.dart';

/// Servicio para manejar roles de usuario
class RolesService {
  final ApiClient _api = ApiClient();

  /// Obtener roles del usuario autenticado
  Future<RolesResponse> obtenerMisRoles() async {
    try {
      debugPrint('[RolesService] 🔍 Obteniendo roles del usuario...');

      final response = await _api.get('rolesusuario/me/');

      debugPrint('[RolesService] 📨 Respuesta del backend:');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      final rolesResponse = RolesResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      debugPrint('[RolesService] ✅ Roles parseados exitosamente');

      return rolesResponse;
    } catch (e) {
      debugPrint('[RolesService] ❌ Error al obtener roles: $e');
      rethrow;
    }
  }

  /// Verificar si el usuario tiene un rol específico
  Future<bool> tieneRol(String rolNombre) async {
    try {
      final roles = await obtenerMisRoles();

      switch (rolNombre) {
        case 'Administrador':
          return roles.tieneRolAdmin;
        case 'Analista':
          return roles.tieneRolAnalista;
        case 'Vendedor':
          return roles.tieneRolVendedor;
        case 'Cliente':
          return roles.roles.contains('Cliente');
        case 'Tecnico':
          return roles.roles.contains('Técnico');
        default:
          return false;
      }
    } catch (e) {
      debugPrint('[RolesService] ❌ Error verificando rol $rolNombre: $e');
      return false;
    }
  }

  /// Verificar si el usuario puede acceder al dashboard ejecutivo
  Future<bool> puedeAccederDashboardEjecutivo() async {
    try {
      debugPrint('[RolesService] 🔍 Verificando acceso al dashboard...');
      final roles = await obtenerMisRoles();
      debugPrint('[RolesService] 📋 Roles obtenidos:');
      debugPrint('  - Nombre: ${roles.nombre}');
      debugPrint('  - Roles: ${roles.roles}');
      debugPrint('  - IDs: ${roles.rolesIds}');
      debugPrint('  - is_admin: ${roles.tieneRolAdmin}');
      debugPrint('  - is_analista: ${roles.tieneRolAnalista}');
      debugPrint('  - is_vendedor: ${roles.tieneRolVendedor}');

      final hasAccess = roles.puedeAccederDashboardEjecutivo;
      debugPrint('[RolesService] ✅ Puede acceder dashboard: $hasAccess');

      return hasAccess;
    } catch (e) {
      debugPrint('[RolesService] ❌ Error verificando acceso dashboard: $e');
      return false;
    }
  }
}
