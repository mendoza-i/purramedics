import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeTone { primary, secondary, success, warning, danger, info, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.primary,
    this.icon,
  });

  Color get _bg => switch (tone) {
    BadgeTone.primary => AppColors.primarySurface,
    BadgeTone.secondary => AppColors.secondarySurface,
    BadgeTone.success => AppColors.successSurface,
    BadgeTone.warning => AppColors.warningSurface,
    BadgeTone.danger => AppColors.dangerSurface,
    BadgeTone.info => AppColors.infoSurface,
    BadgeTone.neutral => AppColors.surfaceAlt,
  };

  Color get _fg => switch (tone) {
    BadgeTone.primary => AppColors.primaryDark,
    BadgeTone.secondary => AppColors.secondaryDark,
    BadgeTone.success => AppColors.success,
    BadgeTone.warning => AppColors.warning,
    BadgeTone.danger => AppColors.danger,
    BadgeTone.info => AppColors.info,
    BadgeTone.neutral => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(color: _bg, borderRadius: AppRadii.rFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _fg),
            AppSpacing.hXs,
          ],
          Text(label, style: AppTypography.labelSmall.copyWith(color: _fg)),
        ],
      ),
    );
  }
}
