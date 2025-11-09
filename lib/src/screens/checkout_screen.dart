import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/cart_service.dart';
import '../services/payment_service.dart';
import '../api/api_client.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiClient _api = ApiClient();
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _addressController = TextEditingController();

  List<dynamic> _addresses = [];
  bool _useCustomAddress = false;
  int? _selectedAddressId;
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final data = await _api.getDirecciones();
      setState(() {
        _addresses = data;
        _loading = false;
        if (_addresses.isNotEmpty) {
          _selectedAddressId = _addresses.first['id'] as int;
        }
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error loading addresses: $e');
    }
  }

  /// Procesar pago automáticamente con tarjeta de prueba
  Future<void> _procesarPago() async {
    final cart = CartService();

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    String? direccionManual;
    int? addressId;

    if (_useCustomAddress) {
      direccionManual = _addressController.text.trim();
      if (direccionManual.isEmpty || direccionManual.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La dirección debe tener al menos 5 caracteres'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    } else {
      addressId = _selectedAddressId;
      if (addressId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar una dirección'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    setState(() => _processing = true);

    try {
      final payload = cart.toCheckoutPayload(
        addressId: addressId,
        direccionManual: direccionManual,
      );

      debugPrint('[CHECKOUT] Iniciando pago con payload: $payload');

      // Paso 1: Crear Payment Intent en backend
      // El backend auto-confirma el pago con tarjeta de prueba pm_card_visa
      final response = await _paymentService.iniciarCheckout(payload);
      debugPrint('[API] Payment Intent creado: ${response.paymentIntentId}');
      debugPrint('[API] Client Secret: ${response.clientSecret}');

      // Paso 2: Esperar a que el backend, Stripe y el webhook procesen todo
      debugPrint(
        '[BACKEND] Esperando confirmación automática y webhook (5 segundos)...',
      );
      await Future.delayed(const Duration(seconds: 5));

      // Paso 3: Verificar que la venta fue creada por el webhook
      // El webhook ya debería haber procesado el payment_intent.succeeded
      debugPrint('[BACKEND] Verificando venta creada por webhook...');
      final result = await _paymentService.confirmarPago(
        response.paymentIntentId,
      );

      // Limpiar carrito y mostrar éxito
      CartService().clear();
      setState(() => _processing = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandPrimary.withOpacity(0.05),
                    AppColors.brandAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícono de éxito con animación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  const Text(
                    '¡Pago Exitoso!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Mensaje
                  Text(
                    'Tu compra se ha procesado correctamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detalles de la venta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandPrimary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.brandPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Detalles de la compra',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ID de Venta:',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '#${result['venta_id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (result['receipt_url'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recibo:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(
                                Icons.check_circle_outline,
                                color: AppColors.success,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botones
                  Column(
                    children: [
                      if (result['receipt_url'] != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = result['receipt_url'] as String;
                              // Importar url_launcher
                              final Uri uri = Uri.parse(url);
                              try {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No se pudo abrir el recibo: $e',
                                      ),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Ver Recibo de Stripe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.brandPrimary,
                              side: BorderSide(
                                color: AppColors.brandPrimary,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Volver al Inicio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _processing = false);
      debugPrint('[ERROR PAGO] $e');

      String errorMsg = 'Error al procesar el pago';
      if (e.toString().contains('Stock insuficiente')) {
        errorMsg = 'No hay suficiente stock para uno o más productos';
      } else if (e.toString().contains('no encontrado')) {
        errorMsg = 'Uno o más productos ya no están disponibles';
      } else if (e.toString().contains('400')) {
        errorMsg =
            'El pago no pudo ser procesado.\n\n'
            '⚠️ El backend debe confirmar el Payment Intent en Stripe automáticamente.\n\n'
            'El equipo backend necesita implementar la confirmación automática del Payment Intent '
            'usando la Secret Key de Stripe con la tarjeta de prueba pm_card_visa.';
      } else if (e.toString().contains('401')) {
        errorMsg = 'Debes iniciar sesión nuevamente';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen del pedido
            Card(
              elevation: AppMetrics.elevationCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Items: ${CartService().totalItems}'),
                    const SizedBox(height: 4),
                    Text(
                      'Total: \$${CartService().total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Selección de dirección
            const Text(
              'Dirección de Envío',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Escribir dirección manualmente'),
              value: _useCustomAddress,
              activeColor: AppColors.brandPrimary,
              onChanged: (val) {
                setState(() => _useCustomAddress = val);
              },
            ),

            const SizedBox(height: 16),

            // Opción: Escribir dirección manual
            if (_useCustomAddress)
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Dirección de envío',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                  ),
                  hintText:
                      'Ej: Av. Siempre Viva 742, Springfield, Estado, CP 12345',
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 3,
              )
            // Opción: Seleccionar dirección guardada
            else if (_addresses.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedAddressId,
                decoration: InputDecoration(
                  labelText: 'Selecciona una dirección',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                items: _addresses.map((a) {
                  return DropdownMenuItem(
                    value: a['id'] as int,
                    child: Text(
                      a['direccion'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedAddressId = val);
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No tienes direcciones guardadas. Activa la opción para escribir una manualmente.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Información de tarjeta (decorativo)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandPrimary,
                    AppColors.brandPrimary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPrimary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Método de Pago',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.credit_card,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: '4242 4242 4242 4242',
                    enabled: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Número de Tarjeta',
                      labelStyle: TextStyle(color: Colors.white70),
                      disabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: '12/28',
                          enabled: false,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Exp.',
                            labelStyle: TextStyle(color: Colors.white70),
                            disabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: '123',
                          enabled: false,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'CVC',
                            labelStyle: TextStyle(color: Colors.white70),
                            disabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tarjeta de prueba para demostración',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botón de pago
            ElevatedButton(
              onPressed: _processing ? null : _procesarPago,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                ),
                disabledBackgroundColor: AppColors.brandPrimary.withOpacity(
                  0.5,
                ),
              ),
              child: _processing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Procesando pago...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'CONFIRMAR Y PAGAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
