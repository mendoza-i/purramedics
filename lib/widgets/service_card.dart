import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double width;

  const ServiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.rLg,
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: AppRadii.rSm,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            AppSpacing.vXs,
            Row(
              children: [
                Text(
                  'Book now',
                  style: AppTypography.labelMedium.copyWith(color: color),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
