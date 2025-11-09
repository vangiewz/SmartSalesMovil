import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api_client.dart';
import '../models/listing_response.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiClient _api = ApiClient();
  final _searchCtrl = TextEditingController();

  List<ProductModel> _products = [];
  bool _loading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _searchQuery;
  int? _selectedMarca;
  int? _selectedTipo;

  List<Map<String, dynamic>> _marcas = [];
  List<Map<String, dynamic>> _tipos = [];

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadProducts();
  }

  Future<void> _loadFilters() async {
    try {
      final filters = await _api.get('listadoproductos/filtros/');
      final data = Map<String, dynamic>.from(filters.data);
      setState(() {
        _marcas = List<Map<String, dynamic>>.from(data['marcas'] ?? []);
        _tipos = List<Map<String, dynamic>>.from(data['tipos'] ?? []);
      });
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _loadProducts({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        'page': page,
        'page_size': 20,
        if (_searchQuery != null && _searchQuery!.isNotEmpty) 'q': _searchQuery,
        if (_selectedMarca != null) 'marca_id': _selectedMarca,
        if (_selectedTipo != null) 'tipoproducto_id': _selectedTipo,
      };

      final response = await _api.listarProductos(params: params);
      final listing = ListingResponse.fromJson(response);

      setState(() {
        _products = listing.results;
        _currentPage = listing.page;
        _totalPages = listing.totalPages;
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

  void _onSearch() {
    setState(() {
      _searchQuery = _searchCtrl.text.trim();
      _currentPage = 1;
    });
    _loadProducts();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = null;
      _selectedMarca = null;
      _selectedTipo = null;
      _searchCtrl.clear();
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearFilters,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_products.isEmpty)
            const Expanded(
              child: Center(child: Text('No se encontraron productos')),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _products.length,
                itemBuilder: (ctx, i) => _ProductCard(product: _products[i]),
              ),
            ),
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _loadProducts(page: _currentPage - 1)
                : null,
          ),
          Text('Página $_currentPage de $_totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => _loadProducts(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedMarca,
              decoration: const InputDecoration(labelText: 'Marca'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._marcas.map(
                  (m) => DropdownMenuItem(
                    value: m['id'] as int,
                    child: Text(m['nombre'] as String),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedMarca = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedTipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ..._tipos.map(
                  (t) => DropdownMenuItem(
                    value: t['id'] as int,
                    child: Text(t['nombre'] as String),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedTipo = val),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _clearFilters();
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadProducts();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con badge de stock
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppMetrics.radiusLg),
                  ),
                  child: SizedBox(
                    height: 140,
                    child: product.imagenUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imagenUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 140,
                            placeholder: (ctx, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (ctx, url, err) =>
                                const Icon(Icons.image, size: 48),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 48),
                          ),
                  ),
                ),
                // Badge de stock
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.stock > 10
                          ? AppColors.success
                          : product.stock > 0
                          ? AppColors.warning
                          : AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stock: ${product.stock}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
