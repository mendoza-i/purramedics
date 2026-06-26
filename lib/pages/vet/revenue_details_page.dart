import 'package:flutter/material.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/visit_fees.dart';
import 'package:purramedics/widgets/widgets.dart';

class RevenueDetailsPage extends StatefulWidget {
  const RevenueDetailsPage({super.key});

  @override
  State<RevenueDetailsPage> createState() => _RevenueDetailsPageState();
}

class _RevenueDetailsPageState extends State<RevenueDetailsPage> {
  String _formatAmount(int amount) {
    final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return amount.toString().replaceAll(formatter, ',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Revenue Breakdown', style: AppTypography.headlineLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getAllAppointmentsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final all = snapshot.data!;
          final now = DateTime.now();
          final thisMonth = DateTime(now.year, now.month);

          int thisRevenue = 0;
          final thisMonthByType = <String, int>{};
          final countsByType = <String, int>{};

          for (final appt in all) {
            if ((appt['status'] ?? '').toString().toLowerCase() != 'confirmed')
              continue;

            DateTime? date;
            try {
              final parts = appt['date'].toString().split('-');
              if (parts.length == 3) {
                date = DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              }
            } catch (_) {}

            if (date == null) continue;

            final apptMonth = DateTime(date.year, date.month);
            if (apptMonth == thisMonth) {
              final fee = feeFor(appt['visitType'] ?? '');
              thisRevenue += fee;

              final type = (appt['visitType'] ?? 'Others').toString();
              thisMonthByType[type] = (thisMonthByType[type] ?? 0) + fee;
              countsByType[type] = (countsByType[type] ?? 0) + 1;
            }
          }

          const monthNames = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
          final currentLabel = '${monthNames[now.month - 1]} ${now.year}';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.success, Color(0xFF0A8860)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppRadii.rXl,
                          boxShadow: AppShadows.colored(AppColors.success),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              currentLabel.toUpperCase(),
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: 1.2,
                              ),
                            ),
                            AppSpacing.vMd,
                            Text(
                              '₱${_formatAmount(thisRevenue)}',
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            AppSpacing.vXs,
                            Text(
                              'Estimated total revenue',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vHuge,
                      Text(
                        'Service Breakdown',
                        style: AppTypography.headlineSmall,
                      ),
                      AppSpacing.vLg,
                      if (thisMonthByType.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No revenue this month',
                          message:
                              'Confirm appointments to see service revenue',
                        )
                      else
                        ...thisMonthByType.entries.map((entry) {
                          final type = entry.key;
                          final revenue = entry.value;
                          final count = countsByType[type] ?? 0;
                          final percent = thisRevenue > 0
                              ? (revenue / thisRevenue) * 100
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  IconAvatar(
                                    icon: Icons.medical_services_rounded,
                                    color: AppColors.success,
                                    size: 40,
                                    circle: true,
                                  ),
                                  AppSpacing.hLg,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type[0].toUpperCase() +
                                              type.substring(1),
                                          style: AppTypography.titleSmall,
                                        ),
                                        AppSpacing.vXs,
                                        Text(
                                          '$count confirmed ${count == 1 ? 'visit' : 'visits'}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textTertiary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₱${_formatAmount(revenue)}',
                                        style: AppTypography.titleMedium
                                            .copyWith(color: AppColors.success),
                                      ),
                                      AppSpacing.vXs,
                                      Text(
                                        '${percent.toStringAsFixed(1)}%',
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      AppSpacing.vXxl,
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.infoSurface,
                          borderRadius: AppRadii.rMd,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.info,
                              size: 20,
                            ),
                            AppSpacing.hMd,
                            Expanded(
                              child: Text(
                                'Revenue shown is estimated from confirmed appointments and preset base fees per service type.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.info,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
