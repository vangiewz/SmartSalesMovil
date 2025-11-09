import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'create_claim_screen.dart';
import 'my_claims_screen.dart';

class GuaranteesScreen extends StatelessWidget {
  const GuaranteesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garantías'),
        elevation: 0,
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.brandPrimary.withOpacity(0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Gestión de Garantías',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administra tus solicitudes de garantía',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                _GuaranteeCard(
                  icon: Icons.add_circle_outline,
                  title: 'Crear Reclamo',
                  subtitle: 'Solicita una garantía para tus productos',
                  color: AppColors.brandPrimary,
                  gradientColors: [
                    AppColors.brandPrimary,
                    AppColors.brandPrimary.withOpacity(0.7),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateClaimScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _GuaranteeCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Mis Garantías',
                  subtitle: 'Ver el estado de tus reclamos',
                  color: AppColors.success,
                  gradientColors: [
                    AppColors.success,
                    AppColors.success.withOpacity(0.7),
                  ],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyClaimsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuaranteeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GuaranteeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Ícono con fondo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 20),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Flecha
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
