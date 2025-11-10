import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/roles_service.dart';
import '../api/api_client.dart';
import '../models/product_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProductModel> _featuredProducts = [];
  bool _loadingProducts = true;
  String _userName = 'Cliente SmartSales';
  bool _canAccessDashboard = false;
  bool _checkingRoles = true;

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
        'listadoproductos/', // ENDPOINT CORRECTO
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
