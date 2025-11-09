import '../api/api_client.dart';
import '../models/payment_intent_response.dart';

/// Servicio para gestionar pagos con Stripe
///
/// FLUJO MÓVIL (X-Platform: mobile):
/// 1. iniciarCheckout() → Backend crea Payment Intent y LO CONFIRMA automáticamente
///    con tarjeta de prueba pm_card_visa (NO requiere confirmación del cliente)
/// 2. Backend → Stripe envía webhook payment_intent.succeeded
/// 3. Webhook → Crea la venta en la base de datos
/// 4. confirmarPago() → Lee la venta creada por el webhook y retorna datos
///
/// ⚠️ IMPORTANTE: El móvil NO debe llamar a stripe.confirmPayment() porque el
/// backend ya confirmó el pago. Confirmar dos veces causa confusión en el flujo.
///
/// FLUJO WEB:
/// - El frontend web SÍ confirma con Stripe.js usando stripe.confirmCardPayment()
class PaymentService {
  final ApiClient _api = ApiClient();

  Future<String> getPublicKey() async {
    final map = await _api.getPublicStripeKey();
    return map['publicKey'] as String;
  }

  /// Inicia el checkout creando un Payment Intent en el backend
  ///
  /// Para móvil: El backend auto-confirma el pago con pm_card_visa
  /// y no requiere confirmación adicional del cliente
  Future<PaymentIntentResponse> iniciarCheckout(
    Map<String, dynamic> payload,
  ) async {
    final map = await _api.iniciarCheckout(payload);
    return PaymentIntentResponse.fromJson(map);
  }

  /// Verifica que la venta fue creada por el webhook y obtiene los detalles
  ///
  /// Este endpoint NO crea ventas, solo las lee.
  /// La venta debe ser creada por el webhook cuando Stripe confirma el pago.
  Future<Map<String, dynamic>> confirmarPago(String paymentIntentId) async {
    return await _api.confirmarPago(paymentIntentId);
  }
}
