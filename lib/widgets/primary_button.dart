import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonSize { small, medium, large }

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final AppButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.size = AppButtonSize.large,
    this.backgroundColor,
    this.foregroundColor,
  });

  double get _height => switch (size) {
        AppButtonSize.small => 40,
        AppButtonSize.medium => 48,
        AppButtonSize.large => 56,
      };

  double get _fontSize => switch (size) {
        AppButtonSize.small => 13,
        AppButtonSize.medium => 14,
        AppButtonSize.large => 15,
      };

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: _height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.textInverse,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.textInverse,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: _fontSize + 3, color: foregroundColor ?? AppColors.textInverse),
                    AppSpacing.hSm,
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor ?? AppColors.textInverse,
                    ),
                  ),
                ],
              ),
      ),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;
  final AppButtonSize size;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = true,
    this.size = AppButtonSize.large,
  });

  double get _height => switch (size) {
        AppButtonSize.small => 40,
        AppButtonSize.medium => 48,
        AppButtonSize.large => 56,
      };

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: _height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.textPrimary),
              AppSpacing.hSm,
            ],
            Text(label, style: AppTypography.labelLarge),
          ],
        ),
      ),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
