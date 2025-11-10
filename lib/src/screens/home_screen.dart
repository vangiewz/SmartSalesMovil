import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/roles_service.dart';
import '../api/api_client.dart';
import '../models/product_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Canal de voz nativo (coincide con MainActivity)
  static const _voiceChannel = MethodChannel('smart_sales/voice');

  // Productos destacados
  List<ProductModel> _featuredProducts = [];
  bool _loadingProducts = true;

  // Usuario
  String _userName = 'Cliente SmartSales';

  // Roles / dashboard
  bool _canAccessDashboard = false;
  bool _checkingRoles = true;

  // Carrito por texto / voz
  bool _escuchando = false;
  bool _cargandoCarritoVoz = false;
  final TextEditingController _textoCarritoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
    _loadUserProfile();
    _checkDashboardAccess();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthService().getMe();
      if (mounted && profile['nombre'] != null) {
        setState(() {
          _userName = profile['nombre'] as String;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _checkDashboardAccess() async {
    debugPrint(
      '[HomeScreen] 🔍 Iniciando verificación de acceso al dashboard...',
    );
    setState(() => _checkingRoles = true);
    try {
      final hasAccess = await RolesService().puedeAccederDashboardEjecutivo();
      debugPrint(
        '[HomeScreen] ✅ Verificación completa. Tiene acceso: $hasAccess',
      );
      if (mounted) {
        setState(() {
          _canAccessDashboard = hasAccess;
          _checkingRoles = false;
        });
        debugPrint(
          '[HomeScreen] 📊 Estado actualizado - _canAccessDashboard: $_canAccessDashboard, _checkingRoles: $_checkingRoles',
        );
      }
    } catch (e) {
      debugPrint('[HomeScreen] ❌ Error checking dashboard access: $e');
      if (mounted) {
        setState(() {
          _canAccessDashboard = false;
          _checkingRoles = false;
        });
      }
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      debugPrint('=== CARGANDO PRODUCTOS DESTACADOS ===');

      final response = await ApiClient().get(
        'listadoproductos/',
        queryParameters: {'page': 1, 'page_size': 5},
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.data == null || response.data['results'] == null) {
        debugPrint('ERROR: No hay resultados');
        if (mounted) setState(() => _loadingProducts = false);
        return;
      }

      final results = (response.data['results'] as List)
          .map((e) => ProductModel.fromJson(e))
          .toList();

      debugPrint('✅ Productos cargados: ${results.length}');

      if (mounted) {
        setState(() {
          _featuredProducts = results;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('=== ERROR CARGANDO PRODUCTOS ===');
      debugPrint('Error: $e');

      if (mounted) {
        setState(() => _loadingProducts = false);
      }
    }
  }

  // ================== CARRITO POR TEXTO / VOZ ==================

  Future<void> _handleArmarCarritoPorTexto() async {
    await _armarCarritoDesdeBackend(_textoCarritoController.text);
  }

  Future<void> _handleArmarCarritoPorVoz() async {
    if (_escuchando) return;

    setState(() {
      _escuchando = true;
    });

    try {
      // Llama al método nativo startListening (MainActivity)
      final text = await _voiceChannel.invokeMethod<String>('startListening');

      if (!mounted) return;

      setState(() {
        _escuchando = false;
        if (text != null && text.isNotEmpty) {
          _textoCarritoController.text = text;
        }
      });

      if (text != null && text.trim().isNotEmpty) {
        await _armarCarritoDesdeBackend(text);
      }
    } on PlatformException catch (e) {
      debugPrint('[HomeScreen] Error al usar voz: ${e.message}');
      if (!mounted) return;
      setState(() {
        _escuchando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al usar voz: ${e.message}'),
        ),
      );
    }
  }

  Future<void> _armarCarritoDesdeBackend(String texto) async {
    final textoLimpio = texto.trim();
    if (textoLimpio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe o dicta una orden para armar el carrito.'),
        ),
      );
      return;
    }

    setState(() => _cargandoCarritoVoz = true);

    try {
      // TODO: reemplazar por el id REAL del usuario autenticado
      const usuarioId = '00000000-0000-0000-0000-000000000000';

      final resp = await ApiClient().post(
        'carrito-voz/carrito-voz/',
        data: {
          'usuario_id': usuarioId,
          'texto': textoLimpio,
          'limite_items': 10,
        },
      );

      final data = resp.data as Map<String, dynamic>;
      final List<dynamic> items = (data['items'] as List?) ?? [];

      if (items.isEmpty) {
        final mensaje = data['mensaje'] as String?;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mensaje ?? 'No se detectaron productos en tu orden.',
            ),
          ),
        );
        return;
      }

      final cart = context.read<CartService>();
      int totalUnidades = 0;

      for (final dynamic rawItem in items) {
        final item = rawItem as Map<String, dynamic>;
        final int productoId = item['producto_id'] as int;
        final int cantidad = item['cantidad'] as int;

        ProductModel? product;

        // 1) Intentar buscar en los productos destacados ya cargados
        try {
          product = _featuredProducts.firstWhere(
            (p) => p.id == productoId,
          );
        } catch (_) {
          product = null;
        }

        // 2) Si no está en destacados, intentar cargar detalle del backend
        if (product == null) {
          try {
            final detailResp =
                await ApiClient().get('listadoproductos/$productoId/');
            if (detailResp.data != null) {
              product = ProductModel.fromJson(detailResp.data);
            }
          } catch (e) {
            debugPrint(
              '[HomeScreen] No se pudo cargar producto $productoId: $e',
            );
          }
        }

        // 3) Si tenemos ProductModel -> addProduct
        if (product != null) {
          cart.addProduct(product, quantity: cantidad);
          totalUnidades += cantidad;
        } else {
          // 4) Si no tenemos el modelo, al menos intentamos sumar cantidad
          cart.addQuantityForExistingProduct(productoId, cantidad);
          totalUnidades += cantidad;
        }
      }

      _textoCarritoController.clear();

      if (totalUnidades > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se agregaron $totalUnidades producto(s) al carrito desde tu orden.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error carrito voz/texto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al interpretar tu orden.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cargandoCarritoVoz = false);
      }
    }
  }

  @override
  void dispose() {
    _textoCarritoController.dispose();
    super.dispose();
  }

  // ================== BUILD ==================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartSales'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Cart Badge
          Consumer<CartService>(
            builder: (context, cart, child) {
              final itemCount = cart.itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.cart),
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.brandAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Hero
            _buildHeroBanner(context),

            const SizedBox(height: 16),

            // 🔥 SECCIÓN: CARRITO POR TEXTO / VOZ
            _buildVoiceCartSection(context),

            const SizedBox(height: 24),

            // Sección Categorías
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryGrid(context),

            const SizedBox(height: 32),

            // Sección Destacados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Productos Destacados',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFeaturedProducts(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ================== WIDGETS AUXILIARES ==================

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header con gradiente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandPrimary, AppColors.brandAccent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  context,
                  icon: Icons.home,
                  title: 'Inicio',
                  route: AppRoutes.home,
                ),
                _drawerItem(
                  context,
                  icon: Icons.shopping_bag,
                  title: 'Productos',
                  route: AppRoutes.products,
                ),
                _drawerItem(
                  context,
                  icon: Icons.shopping_cart,
                  title: 'Mi Carrito',
                  route: AppRoutes.cart,
                ),
                const Divider(),
                _drawerItem(
                  context,
                  icon: Icons.business_center_rounded,
                  title: 'Gestión Comercial',
                  route: AppRoutes.comercialManagement,
                ),
                _drawerItem(
                  context,
                  icon: Icons.verified_user_rounded,
                  title: 'Gestión de Garantía',
                  route: AppRoutes.guarantees,
                ),
                const Divider(),

                // Dashboard Ejecutivo (solo Admin/Analista)
                if (!_checkingRoles && _canAccessDashboard)
                  _drawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard Ejecutivo',
                    route: AppRoutes.dashboardEjecutivo,
                    highlighted: true,
                  ),
                if (!_checkingRoles && _canAccessDashboard) const Divider(),

                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.danger),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool highlighted = false,
  }) {
    return Container(
      decoration: highlighted
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandPrimary.withOpacity(0.1),
                  AppColors.brandAccent.withOpacity(0.1),
                ],
              ),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: highlighted ? AppColors.brandPrimary : AppColors.brandPrimary,
        ),
        title: Text(
          title,
          style: highlighted
              ? TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                )
              : null,
        ),
        onTap: () {
          Navigator.of(context).pop(); // Cerrar drawer
          Navigator.of(context).pushNamed(route);
        },
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 158,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandPrimary, AppColors.brandAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎉 Ofertas Especiales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hasta 50% de descuento',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.products),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'COMPRAR AHORA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCartSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: AppMetrics.elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Armar carrito por texto o voz',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textoCarritoController,
                onSubmitted: (_) => _handleArmarCarritoPorTexto(),
                decoration: const InputDecoration(
                  hintText:
                      'Ej: "agrega dos refrigeradores Samsung y una cocina LG"',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _cargandoCarritoVoz
                          ? null
                          : () => _handleArmarCarritoPorTexto(),
                      icon: _cargandoCarritoVoz
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart),
                      label: const Text('Construir carrito'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleArmarCarritoPorVoz,
                    icon: Icon(
                      _escuchando ? Icons.mic_off : Icons.mic,
                      color: _escuchando ? Colors.red : AppColors.brandPrimary,
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

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {'name': 'Refrigeradores', 'icon': Icons.kitchen},
      {'name': 'Cocinas', 'icon': Icons.microwave},
      {'name': 'Lavadoras', 'icon': Icons.local_laundry_service},
      {'name': 'Aires Acond.', 'icon': Icons.ac_unit},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.products),
              child: Card(
                elevation: AppMetrics.elevationCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 40,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProducts(BuildContext context) {
    if (_loadingProducts) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_featuredProducts.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'No hay productos disponibles',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredProducts.length,
        itemBuilder: (context, index) {
          final product = _featuredProducts[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.productDetail, arguments: product),
              child: Card(
                elevation: AppMetrics.elevationCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppMetrics.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen del producto
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppMetrics.radiusMd),
                        topRight: Radius.circular(AppMetrics.radiusMd),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product.imagenUrl ?? '',
                        height: 140,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.bgBase,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.bgBase,
                          child: Icon(
                            Icons.shopping_bag,
                            size: 60,
                            color: AppColors.brandPrimary.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${product.precio.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
