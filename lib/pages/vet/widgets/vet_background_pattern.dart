import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:purramedics/theme/app_theme.dart';

class VetBackgroundPattern extends StatelessWidget {
  final Widget child;

  const VetBackgroundPattern({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _PawPatternPainter(
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PawPatternPainter extends CustomPainter {
  final Color color;

  _PawPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 180.0;
    const iconSize = 48.0;

    for (var x = 0.0; x < size.width + spacing; x += spacing) {
      for (var y = 0.0; y < size.height + spacing; y += spacing) {
        // Offset alternate rows for a staggered pattern
        final offsetX = (y / spacing) % 2 == 0 ? 0 : spacing / 2;
        final dx = x + offsetX;

        // Add some random rotation based on position
        final rotate = math.sin(dx * y) * 0.5;

        canvas.save();
        canvas.translate(dx, y);
        canvas.rotate(rotate);

        // Draw a simple paw print shape (using circles)
        // Main pad
        canvas.drawCircle(const Offset(0, 5), iconSize * 0.35, paint);
        // Toe beans
        canvas.drawCircle(
          Offset(-iconSize * 0.35, -iconSize * 0.2),
          iconSize * 0.15,
          paint,
        );
        canvas.drawCircle(
          Offset(iconSize * 0.35, -iconSize * 0.2),
          iconSize * 0.15,
          paint,
        );
        canvas.drawCircle(
          Offset(-iconSize * 0.15, -iconSize * 0.45),
          iconSize * 0.15,
          paint,
        );
        canvas.drawCircle(
          Offset(iconSize * 0.15, -iconSize * 0.45),
          iconSize * 0.15,
          paint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PawPatternPainter oldDelegate) =>
      color != oldDelegate.color;
}
