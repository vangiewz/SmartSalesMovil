import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'] as int,
    );
  }
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal() {
    _loadCart();
  }

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(
    0.0,
    (sum, item) => sum + (item.product.precio * item.quantity),
  );

  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('cart');
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _items.clear();
        _items.addAll(decoded.map((e) => CartItem.fromJson(e)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString('cart', data);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  void addProduct(ProductModel product, {int quantity = 1}) {
    final existing = _items.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );

    if (existing.quantity == 0) {
      _items.add(CartItem(product: product, quantity: quantity));
    } else {
      existing.quantity += quantity;
    }

    _saveCart();
    notifyListeners();
  }

  void removeProduct(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final item = _items.firstWhere((i) => i.product.id == productId);
    item.quantity = quantity;
    _saveCart();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  /// Convierte el carrito al formato correcto para el backend
  /// Si addressId != null, usa "id_direccion"
  /// Si addressId == null, usa "direccion_manual" con el texto
  Map<String, dynamic> toCheckoutPayload({
    int? addressId,
    String? direccionManual,
  }) {
    final payload = <String, dynamic>{
      'items': _items
          .map(
            (item) => {
              'producto_id': item.product.id,
              'cantidad': item.quantity,
            },
          )
          .toList(),
    };

    // Según la documentación: enviar SOLO uno de estos dos campos
    if (addressId != null) {
      payload['id_direccion'] = addressId;
    } else if (direccionManual != null && direccionManual.isNotEmpty) {
      payload['direccion_manual'] = direccionManual;
    }

    return payload;
  }
}
