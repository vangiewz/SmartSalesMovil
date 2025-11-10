import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/dashboard_model.dart';

/// Parámetros opcionales para el dashboard
class DashboardParams {
  final String? fechaInicio;
  final String? fechaFin;
  final int? limitTop;

  DashboardParams({this.fechaInicio, this.fechaFin, this.limitTop});

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (fechaInicio != null) params['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) params['fecha_fin'] = fechaFin;
    if (limitTop != null) params['limit_top'] = limitTop;
    return params;
  }
}

/// Servicio para obtener datos del Dashboard Ejecutivo
/// Solo accesible para usuarios con rol de Analista o Administrador
class DashboardService {
  final ApiClient _api = ApiClient();

  /// Obtener datos completos del dashboard ejecutivo
  /// Solo accesible para Analistas y Administradores
  Future<DashboardData> obtenerDashboardEjecutivo({
    DashboardParams? params,
  }) async {
    try {
      debugPrint('[DashboardService] 📊 Cargando dashboard ejecutivo...');

      final response = await _api.get(
        'dashboard-ejecutivo/',
        queryParameters: params?.toQueryParams(),
      );

      debugPrint('[DashboardService] ✅ Dashboard cargado exitosamente');

      return DashboardData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[DashboardService] ❌ Error cargando dashboard: $e');
      rethrow;
    }
  }

  /// Obtener solo KPIs
  Future<List<KPI>> obtenerKPIs({DashboardParams? params}) async {
    final dashboard = await obtenerDashboardEjecutivo(params: params);
    return dashboard.kpis;
  }

  /// Obtener solo top productos
  Future<List<ProductoTop>> obtenerTopProductos({
    DashboardParams? params,
  }) async {
    final dashboard = await obtenerDashboardEjecutivo(params: params);
    return dashboard.productosMasVendidos;
  }

  /// Obtener solo top clientes
  Future<List<ClienteTop>> obtenerTopClientes({DashboardParams? params}) async {
    final dashboard = await obtenerDashboardEjecutivo(params: params);
    return dashboard.mejoresClientes;
  }

  /// Obtener solo resumen del sistema
  Future<ResumenGeneral> obtenerResumenGeneral() async {
    final dashboard = await obtenerDashboardEjecutivo();
    return dashboard.resumen;
  }
}
