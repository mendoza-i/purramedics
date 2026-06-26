import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? AppSpacing.xl : AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.textTertiary,
              size: compact ? 28 : 36,
            ),
          ),
          AppSpacing.vLg,
          Text(
            title,
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            AppSpacing.vXs,
            Text(
              message!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.vLg,
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
