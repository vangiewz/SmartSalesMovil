import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../services/cart_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.nombre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
                child: SizedBox(
                  height: 300,
                  child: product.imagenUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imagenUrl!,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (ctx, url, err) =>
                              const Center(child: Icon(Icons.image, size: 64)),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, size: 64),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.nombre, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '\$${product.precio.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Stock disponible: ${product.stock}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Garantía: ${product.tiempogarantia} días',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            if (product.marca != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.label, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Marca: ${product.marca!['nombre']}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (product.tipoproducto != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tipo: ${product.tipoproducto!['nombre']}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: product.stock > 0
                  ? () {
                      CartService().addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Producto agregado al carrito'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Agregar al carrito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
