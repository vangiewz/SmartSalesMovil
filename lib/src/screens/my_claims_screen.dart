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
      appBar: AppBar(title: const Text('Mis Garantías')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _claims.isEmpty
          ? const Center(child: Text('No tienes reclamos registrados'))
          : ListView.builder(
              itemCount: _claims.length,
              itemBuilder: (ctx, i) {
                final claim = _claims[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
                  ),
                  child: ListTile(
                    leading: _buildStatusIcon(claim['estado']),
                    title: Text(claim['producto_nombre'] ?? 'Producto'),
                    subtitle: Text(
                      'Estado: ${claim['estado']}\n'
                      'Cantidad: ${claim['cantidad']}\n'
                      'Venta #${claim['venta_id']}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showClaimDetail(claim),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusIcon(String? estado) {
    IconData icon;
    Color color;
    switch (estado) {
      case 'Completado':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'Rechazado':
        icon = Icons.cancel;
        color = AppColors.danger;
        break;
      default:
        icon = Icons.pending;
        color = AppColors.warning;
    }
    return Icon(icon, color: color);
  }

  void _showClaimDetail(dynamic claim) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Garantía #${claim['garantia_id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Producto: ${claim['producto_nombre']}'),
              Text('Estado: ${claim['estado']}'),
              Text('Cantidad: ${claim['cantidad']}'),
              Text('Venta ID: ${claim['venta_id']}'),
              Text('Motivo: ${claim['motivo']}'),
              if (claim['hora'] != null) Text('Fecha: ${claim['hora']}'),
              if (claim['reemplazo'] != null)
                Text('Reemplazo: ${claim['reemplazo']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
