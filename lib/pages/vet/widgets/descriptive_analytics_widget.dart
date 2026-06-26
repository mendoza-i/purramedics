import 'package:flutter/material.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:purramedics/pages/vet/analytics_details_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class DescriptiveAnalyticsWidget extends StatelessWidget {
  const DescriptiveAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsDetailsPage()),
        );
      },
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Traffic', style: AppTypography.titleMedium),
                    AppSpacing.vXs,
                    Text(
                      'Daily clinic intake this week',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.hMd,
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          AppSpacing.vXxl,
          SizedBox(
            height: 180,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getAllAppointmentsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final appointments = snapshot.data!;
                final now = DateTime.now();

                final int offsetFromSunday = now.weekday == 7 ? 0 : now.weekday;
                final startOfWeek = now.subtract(
                  Duration(days: offsetFromSunday),
                );

                final weeklyData = List<int>.filled(7, 0);
                final days = List<String>.filled(7, '');
                final isToday = List<bool>.filled(7, false);

                for (int i = 0; i < 7; i++) {
                  final targetDay = startOfWeek.add(Duration(days: i));
                  days[i] = DateFormat('E\nM/d').format(targetDay);
                  if (now.year == targetDay.year &&
                      now.month == targetDay.month &&
                      now.day == targetDay.day) {
                    isToday[i] = true;
                  }
                }

                for (final appt in appointments) {
                  if (appt['createdAt'] != null) {
                    final dt =
                        (appt['createdAt'] as dynamic).toDate() as DateTime;
                    for (int i = 0; i < 7; i++) {
                      final targetDay = startOfWeek.add(Duration(days: i));
                      if (dt.year == targetDay.year &&
                          dt.month == targetDay.month &&
                          dt.day == targetDay.day) {
                        weeklyData[i]++;
                        break;
                      }
                    }
                  }
                }

                int maxVal = weeklyData.reduce(
                  (curr, next) => curr > next ? curr : next,
                );
                if (maxVal < 5) maxVal = 5;

                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: CustomPaint(
                          size: const Size(double.infinity, double.infinity),
                          painter: BarChartPainter(
                            data: weeklyData,
                            maxVal: maxVal,
                            isToday: isToday,
                            barColor: AppColors.primaryLight,
                            todayColor: AppColors.primary,
                            emptyColor: AppColors.border,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.vSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        return SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              Text(
                                weeklyData[index].toString(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: isToday[index]
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppSpacing.vXs,
                              Text(
                                days[index],
                                textAlign: TextAlign.center,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isToday[index]
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                  fontWeight: isToday[index]
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<int> data;
  final int maxVal;
  final List<bool> isToday;
  final Color barColor;
  final Color todayColor;
  final Color emptyColor;

  BarChartPainter({
    required this.data,
    required this.maxVal,
    required this.isToday,
    required this.barColor,
    required this.todayColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final int count = data.length;
    final double totalSpacing = size.width * 0.28;
    final double barWidth = (size.width - totalSpacing) / count;
    final double gap = totalSpacing / (count + 1);

    for (int i = 0; i < count; i++) {
      final double barHeight = maxVal == 0
          ? 0
          : (data[i] / maxVal) * (size.height - 4);
      final double left = gap + i * (barWidth + gap);
      final double top = size.height - barHeight;

      final Color color = isToday[i] ? todayColor : barColor;

      if (barHeight < 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, size.height - 3, barWidth, 3),
            const Radius.circular(3),
          ),
          Paint()..color = emptyColor,
        );
        continue;
      }

      final RRect rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(6),
      );

      canvas.drawRRect(
        rRect.shift(const Offset(0, 2)),
        Paint()
          ..color = color.withOpacity(0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      canvas.drawRRect(
        rRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withOpacity(0.6)],
          ).createShader(Rect.fromLTWH(left, top, barWidth, barHeight)),
      );

      if (barHeight > 10) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, barWidth, 4),
            const Radius.circular(6),
          ),
          Paint()..color = Colors.white.withOpacity(0.3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter old) =>
      old.data != data || old.maxVal != maxVal;
}
