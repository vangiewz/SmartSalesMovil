import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';

class CreateClaimScreen extends StatefulWidget {
  const CreateClaimScreen({super.key});

  @override
  State<CreateClaimScreen> createState() => _CreateClaimScreenState();
}

class _CreateClaimScreenState extends State<CreateClaimScreen> {
  final ApiClient _api = ApiClient();
  final _motivoCtrl = TextEditingController();

  List<dynamic> _ventasElegibles = [];
  bool _loading = true;
  bool _submitting = false; // Nuevo: prevenir doble envío
  int? _selectedVenta;
  int? _selectedProducto;
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }

  Future<void> _loadVentas() async {
    try {
      final data = await _api.ventasElegiblesGarantia();
      setState(() {
        _ventasElegibles = data;
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

  Future<void> _createClaim() async {
    if (_submitting) return; // Prevenir doble envío

    if (_selectedVenta == null ||
        _selectedProducto == null ||
        _motivoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _api.crearGarantia({
        'venta_id': _selectedVenta,
        'producto_id': _selectedProducto,
        'cantidad': _cantidad,
        'motivo': _motivoCtrl.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reclamo creado exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reclamo de Garantía'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ventasElegibles.isEmpty
          ? const Center(
              child: Text('No hay productos elegibles para garantía'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedVenta,
                    decoration: const InputDecoration(
                      labelText: 'Venta',
                      border: OutlineInputBorder(),
                    ),
                    items: _ventasElegibles.map((v) {
                      return DropdownMenuItem(
                        value: v['venta_id'] as int,
                        child: Text(
                          'Venta #${v['venta_id']} - ${v['fecha_venta']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedVenta = val;
                        _selectedProducto = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedVenta != null)
                    DropdownButtonFormField<int>(
                      value: _selectedProducto,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                      items: _getProductosDeVenta(_selectedVenta!).map((p) {
                        return DropdownMenuItem(
                          value: p['producto_id'] as int,
                          child: Text(p['producto_nombre'] as String),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedProducto = val);
                      },
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _cantidad.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _cantidad = int.tryParse(val) ?? 1;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _motivoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Motivo del reclamo',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _createClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _submitting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Creando reclamo...'),
                              ],
                            )
                          : const Text(
                              'CREAR RECLAMO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<dynamic> _getProductosDeVenta(int ventaId) {
    final venta = _ventasElegibles.firstWhere(
      (v) => v['venta_id'] == ventaId,
      orElse: () => {},
    );
    return List<dynamic>.from(venta['productos'] ?? []);
  }
}
