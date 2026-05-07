import 'package:flutter/material.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/pages/vet/revenue_details_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/visit_fees.dart';

class RevenueStatsWidget extends StatelessWidget {
  const RevenueStatsWidget({super.key});

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }
    return amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getAllAppointmentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator(color: AppColors.success)),
          );
        }

        final all = snapshot.data!;

        int thisRevenue = 0;
        int lastRevenue = 0;
        final thisMonthByType = <String, int>{};
        int thisConfirmedCount = 0;

        for (final appt in all) {
          if ((appt['status'] ?? '').toString().toLowerCase() != 'confirmed') continue;

          DateTime? date;
          try {
            final parts = appt['date'].toString().split('-');
            if (parts.length == 3) {
              date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          } catch (_) {}

          if (date == null) continue;

          final fee = feeFor(appt['visitType'] ?? '');
          final apptMonth = DateTime(date.year, date.month);

          if (apptMonth == thisMonth) {
            thisRevenue += fee;
            thisConfirmedCount++;
            final type = (appt['visitType'] ?? 'Others').toString();
            thisMonthByType[type] = (thisMonthByType[type] ?? 0) + fee;
          } else if (apptMonth == lastMonth) {
            lastRevenue += fee;
          }
        }

        double changePercent = 0;
        bool isGrowing = true;
        if (lastRevenue > 0) {
          changePercent = ((thisRevenue - lastRevenue) / lastRevenue) * 100;
          isGrowing = changePercent >= 0;
        } else if (thisRevenue > 0) {
          changePercent = 100;
          isGrowing = true;
        }

        String topService = 'N/A';
        if (thisMonthByType.isNotEmpty) {
          topService = thisMonthByType.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
          topService = topService[0].toUpperCase() + topService.substring(1);
        }

        const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final thisMonthLabel = monthNames[now.month - 1];
        final lastMonthLabel = monthNames[lastMonth.month - 1];

        return Material(
          color: Colors.transparent,
          borderRadius: AppRadii.rXl,
          child: InkWell(
            borderRadius: AppRadii.rXl,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RevenueDetailsPage()));
            },
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.success, Color(0xFF0A8860)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadii.rXl,
                boxShadow: AppShadows.colored(AppColors.success),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
                            ),
                            AppSpacing.hSm,
                            Text(
                              'ESTIMATED REVENUE',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: AppRadii.rFull,
                          ),
                          child: Text(
                            thisMonthLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vLg,
                    Text(
                      '₱${_formatAmount(thisRevenue)}',
                      style: AppTypography.displayLarge.copyWith(color: Colors.white),
                    ),
                    AppSpacing.vXs,
                    Row(
                      children: [
                        Icon(
                          isGrowing ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        AppSpacing.hXs,
                        Expanded(
                          child: Text(
                            '${isGrowing ? '+' : ''}${changePercent.toStringAsFixed(1)}% vs $lastMonthLabel  (₱${_formatAmount(lastRevenue)})',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vLg,
                    Divider(color: Colors.white.withOpacity(0.2), height: 1),
                    AppSpacing.vLg,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statChip(Icons.star_rounded, 'Top service', topService),
                        _statChip(Icons.check_circle_rounded, 'Confirmed', '$thisConfirmedCount apts'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
        AppSpacing.hSm,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
