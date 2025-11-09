import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _claims = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      final response = await _api.get('garantia/mis/');
      setState(() {
        // Backend may return array directly or paginated {results: [...]}
        if (response.data is List) {
          _claims = List<dynamic>.from(response.data);
        } else if (response.data is Map && response.data['results'] != null) {
          _claims = List<dynamic>.from(response.data['results']);
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Garantías'), elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _claims.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes garantías registradas',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadClaims,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _claims.length,
                itemBuilder: (ctx, i) {
                  final claim = _claims[i];
                  return _buildClaimCard(claim);
                },
              ),
            ),
    );
  }

  Widget _buildClaimCard(dynamic claim) {
    final status = claim['estado'] ?? 'Pendiente';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
      ),
      child: InkWell(
        onTap: () => _showClaimDetail(claim),
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Garantía #${claim['garantia_id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const Divider(height: 24),
              // Información del producto
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      claim['producto_nombre'] ?? 'Producto',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Venta #${claim['venta_id']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.numbers, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Cant: ${claim['cantidad']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              if (claim['hora'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(claim['hora']),
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completado':
        return AppColors.success;
      case 'Rechazado':
        return AppColors.danger;
      case 'En Proceso':
        return AppColors.brandPrimary;
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completado':
        return Icons.check_circle;
      case 'Rechazado':
        return Icons.cancel;
      case 'En Proceso':
        return Icons.sync;
      default:
        return Icons.pending;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showClaimDetail(dynamic claim) {
    final status = claim['estado'] ?? 'Pendiente';
    final statusColor = _getStatusColor(status);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        ),
        title: Row(
          children: [
            Icon(_getStatusIcon(status), color: statusColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Garantía #${claim['garantia_id']}',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Estado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Estado: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Detalles
              _buildDetailRow(
                Icons.inventory_2_outlined,
                'Producto',
                claim['producto_nombre'] ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.shopping_bag_outlined,
                'Venta ID',
                '#${claim['venta_id']}',
              ),
              _buildDetailRow(
                Icons.numbers,
                'Cantidad',
                '${claim['cantidad']}',
              ),
              if (claim['hora'] != null)
                _buildDetailRow(
                  Icons.access_time,
                  'Fecha',
                  _formatDate(claim['hora']),
                ),
              const Divider(height: 24),
              // Motivo
              if (claim['motivo'] != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Motivo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            claim['motivo'],
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // Reemplazo
              if (claim['reemplazo'] != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.autorenew, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reemplazo: ${claim['reemplazo']}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(ctx).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Cerrar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
