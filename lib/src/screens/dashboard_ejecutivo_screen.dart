import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/roles_service.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';
import '../widgets/dashboard_widgets.dart';

/// Pantalla del Dashboard Ejecutivo
/// Solo accesible para usuarios con rol de Administrador o Analista
class DashboardEjecutivoScreen extends StatefulWidget {
  const DashboardEjecutivoScreen({super.key});

  @override
  State<DashboardEjecutivoScreen> createState() =>
      _DashboardEjecutivoScreenState();
}

class _DashboardEjecutivoScreenState extends State<DashboardEjecutivoScreen> {
  final RolesService _rolesService = RolesService();
  final DashboardService _dashboardService = DashboardService();

  bool _loadingRoles = true;
  bool _loadingDashboard = true;
  bool _hasAccess = false;
  DashboardData? _dashboardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadData();
  }

  Future<void> _checkAccessAndLoadData() async {
    setState(() {
      _loadingRoles = true;
      _loadingDashboard = true;
      _errorMessage = null;
    });

    try {
      // 1. Verificar si tiene acceso
      final hasAccess = await _rolesService.puedeAccederDashboardEjecutivo();

      if (!mounted) return;

      setState(() {
        _hasAccess = hasAccess;
        _loadingRoles = false;
      });

      if (!hasAccess) {
        debugPrint('[Dashboard] ❌ Usuario sin permisos de acceso');
        return;
      }

      // 2. Cargar datos del dashboard
      await _loadDashboard();
    } catch (e) {
      debugPrint('[Dashboard] ❌ Error verificando acceso: $e');
      if (mounted) {
        setState(() {
          _loadingRoles = false;
          _loadingDashboard = false;
          _errorMessage = 'Error al verificar permisos';
        });
      }
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loadingDashboard = true;
      _errorMessage = null;
    });

    try {
      final data = await _dashboardService.obtenerDashboardEjecutivo();

      if (!mounted) return;

      setState(() {
        _dashboardData = data;
        _loadingDashboard = false;
      });

      debugPrint('[Dashboard] ✅ Datos cargados exitosamente');
    } catch (e) {
      debugPrint('[Dashboard] ❌ Error cargando dashboard: $e');
      if (mounted) {
        setState(() {
          _loadingDashboard = false;
          _errorMessage = 'Error al cargar el dashboard';
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Ejecutivo'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading inicial
    if (_loadingRoles) {
      return _buildLoadingState('Verificando permisos...');
    }

    // Sin acceso
    if (!_hasAccess) {
      return _buildAccessDenied();
    }

    // Loading dashboard
    if (_loadingDashboard && _dashboardData == null) {
      return _buildLoadingState('Cargando dashboard...');
    }

    // Error
    if (_errorMessage != null && _dashboardData == null) {
      return _buildErrorState();
    }

    // Dashboard con datos
    if (_dashboardData != null) {
      return _buildDashboard();
    }

    // Estado fallback
    return _buildErrorState();
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.brandPrimary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 80, color: AppColors.danger),
            const SizedBox(height: 24),
            const Text(
              'Acceso Denegado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Este módulo es exclusivo para usuarios con rol de Administrador o Analista.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.danger),
            const SizedBox(height: 24),
            const Text(
              'Error al Cargar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'No se pudo cargar el dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkAccessAndLoadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final data = _dashboardData!;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.brandPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con fecha
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Dashboard Ejecutivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última actualización: ${_formatDateTime(DateTime.now())}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // KPIs Principales
            _buildSection(
              title: 'Métricas Principales',
              child: Column(
                children: data.kpis.map((kpi) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MetricCard(
                      title: kpi.titulo,
                      value: kpi.valor,
                      icon: _getIconFromString(kpi.icono),
                      color: _getColorFromIcon(kpi.icono),
                      subtitle: kpi.cambioPorcentual != null
                          ? '${kpi.cambioPorcentual! > 0 ? "+" : ""}${kpi.cambioPorcentual!.toStringAsFixed(1)}% vs período anterior'
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Resumen del Sistema
            _buildSection(
              title: '📦 Resumen del Sistema',
              child: Column(
                children: [
                  MetricCard(
                    title: 'Total Productos en Catálogo',
                    value: data.resumen.totalProductos.toString(),
                    icon: Icons.inventory_2,
                    color: const Color(0xFF607D8B),
                  ),
                  const SizedBox(height: 12),
                  MetricCard(
                    title: 'Usuarios Registrados',
                    value: data.resumen.totalUsuarios.toString(),
                    icon: Icons.people,
                    color: const Color(0xFF9C27B0),
                  ),
                  const SizedBox(height: 12),
                  MetricCard(
                    title: 'Vendedores Activos',
                    value: data.resumen.totalVendedores.toString(),
                    icon: Icons.business_center,
                    color: const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 12),
                  MetricCard(
                    title: 'Valor Total Inventario',
                    value: _formatCurrency(data.resumen.valorInventario),
                    icon: Icons.attach_money,
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),

            // Top Productos
            _buildSection(
              title: '🏆 Top 10 Productos Más Vendidos',
              child: Column(
                children: data.productosMasVendidos.asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final producto = entry.value;
                  return TopItemCard(
                    rank: index + 1,
                    title: producto.nombre,
                    subtitle: producto.marca,
                    stats:
                        'Vendidos: ${producto.cantidadVendida} | Total: ${_formatCurrency(producto.montoTotal)}',
                    rankColor: _getRankColor(index),
                  );
                }).toList(),
              ),
            ),

            // Top Clientes
            _buildSection(
              title: '👑 Top 10 Mejores Clientes',
              child: Column(
                children: data.mejoresClientes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cliente = entry.value;
                  return TopItemCard(
                    rank: index + 1,
                    title: cliente.nombre,
                    subtitle: cliente.correo,
                    stats:
                        'Compras: ${cliente.totalCompras} | Total: ${_formatCurrency(cliente.montoTotal)}',
                    rankColor: _getRankColor(index),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'es_MX',
    );
    return formatter.format(amount);
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es');
    return formatter.format(dateTime);
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Oro
      case 1:
        return const Color(0xFFC0C0C0); // Plata
      case 2:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return const Color(0xFF007AFF); // Azul por defecto
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'dollar':
        return Icons.attach_money;
      case 'shopping-cart':
        return Icons.shopping_cart;
      case 'users':
        return Icons.people;
      case 'receipt':
        return Icons.receipt;
      case 'package':
        return Icons.inventory;
      case 'alert-circle':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getColorFromIcon(String iconName) {
    switch (iconName) {
      case 'dollar':
        return const Color(0xFF4CAF50);
      case 'shopping-cart':
        return const Color(0xFF2196F3);
      case 'users':
        return const Color(0xFF9C27B0);
      case 'receipt':
        return const Color(0xFFFF9800);
      case 'package':
        return const Color(0xFF00BCD4);
      case 'alert-circle':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF607D8B);
    }
  }
}
