import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IconAvatar extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;
  final bool circle;

  const IconAvatar({
    super.key,
    required this.icon,
    this.color,
    this.background,
    this.size = 44,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.primary;
    final bg = background ?? fg.withOpacity(0.12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : AppRadii.rMd,
      ),
      child: Icon(icon, color: fg, size: size * 0.5),
    );
  }
}
