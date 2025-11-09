import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'create_claim_screen.dart';
import 'my_claims_screen.dart';

class GuaranteesScreen extends StatelessWidget {
  const GuaranteesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Garantías')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _GuaranteeCard(
              icon: Icons.add_circle,
              title: 'Crear Reclamo',
              subtitle: 'Solicita una garantía para tus productos',
              color: AppColors.brandPrimary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateClaimScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _GuaranteeCard(
              icon: Icons.list_alt,
              title: 'Mis Garantías',
              subtitle: 'Ver el estado de tus reclamos',
              color: AppColors.brandAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyClaimsScreen()),
                );
              },
            ),
          ],
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
  final VoidCallback onTap;

  const _GuaranteeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
