import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final double? radius;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.shadow,
    this.radius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? AppRadii.lg);

    final container = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: shadow ?? AppShadows.sm,
      ),
      child: Padding(
        padding: padding ?? AppSpacing.cardPadding,
        child: child,
      ),
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: container,
      ),
    );
  }
}
