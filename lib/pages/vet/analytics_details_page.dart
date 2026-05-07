import 'package:flutter/material.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class AnalyticsDetailsPage extends StatefulWidget {
  const AnalyticsDetailsPage({super.key});

  @override
  State<AnalyticsDetailsPage> createState() => _AnalyticsDetailsPageState();
}

class _AnalyticsDetailsPageState extends State<AnalyticsDetailsPage> {
  late DateTime _selectedMonth;
  late DateTime _compareMonth;

  static const List<String> _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  static const List<Color> _breakdownColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.info,
    AppColors.warning,
    AppColors.success,
    AppColors.danger,
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _compareMonth = DateTime(now.year, now.month - 1);
  }

  Map<String, int> _visitTypeCounts(List<Map<String, dynamic>> apts, DateTime month) {
    final counts = <String, int>{};
    for (final appt in apts) {
      try {
        final parts = appt['date'].toString().split('-');
        if (parts.length != 3) continue;
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (d.year != month.year || d.month != month.month) continue;
        final type = (appt['visitType'] ?? 'General').toString().trim();
        final key = type.isEmpty ? 'General' : type[0].toUpperCase() + type.substring(1).toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
      } catch (_) {}
    }
    return counts;
  }

  int _monthTotal(List<Map<String, dynamic>> apts, DateTime month) {
    int total = 0;
    for (final appt in apts) {
      try {
        final parts = appt['date'].toString().split('-');
        if (parts.length != 3) continue;
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        if (d.year == month.year && d.month == month.month) total++;
      } catch (_) {}
    }
    return total;
  }

  String _conclusion({
    required int thisTotal,
    required int prevTotal,
    required Map<String, int> thisTypes,
    required Map<String, int> prevTypes,
    required String thisMonthName,
    required String prevMonthName,
  }) {
    if (thisTotal == 0 && prevTotal == 0) {
      return 'No appointment data available for $thisMonthName or $prevMonthName yet.';
    }

    String change;
    if (prevTotal == 0) {
      change = '$thisMonthName had $thisTotal appointment${thisTotal != 1 ? 's' : ''} with no prior data to compare.';
    } else if (thisTotal == prevTotal) {
      change = '$thisMonthName and $prevMonthName had equal volume ($thisTotal each).';
    } else {
      final pct = (((thisTotal - prevTotal) / prevTotal) * 100).abs().toStringAsFixed(0);
      final dir = thisTotal > prevTotal ? 'increase' : 'decrease';
      change = '$thisMonthName had $thisTotal appointment${thisTotal != 1 ? 's' : ''} — a $pct% $dir from $prevMonthName ($prevTotal).';
    }

    String typeSentence = '';
    if (thisTypes.isNotEmpty) {
      final top = thisTypes.entries.reduce((a, b) => a.value >= b.value ? a : b);
      typeSentence = ' ${top.key} led with ${top.value} booking${top.value != 1 ? 's' : ''}.';
    }

    String declineSentence = '';
    for (final entry in prevTypes.entries) {
      final curr = thisTypes[entry.key] ?? 0;
      if (curr < entry.value) {
        declineSentence = ' ${entry.key} bookings fell by ${entry.value - curr} vs $prevMonthName.';
        break;
      }
    }

    return change + typeSentence + declineSentence;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Analytics Dashboard', style: AppTypography.headlineLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getAllAppointmentsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final all = snapshot.data!;
          final thisTotal = _monthTotal(all, _selectedMonth);
          final prevTotal = _monthTotal(all, _compareMonth);
          final thisTypes = _visitTypeCounts(all, _selectedMonth);
          final prevTypes = _visitTypeCounts(all, _compareMonth);
          final totalAllTime = all.length;

          final dayCount = List<int>.filled(7, 0);
          for (final appt in all) {
            try {
              final parts = appt['date'].toString().split('-');
              if (parts.length != 3) continue;
              final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              dayCount[d.weekday - 1]++;
            } catch (_) {}
          }
          const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          int peakIdx = 0;
          for (int i = 1; i < 7; i++) {
            if (dayCount[i] > dayCount[peakIdx]) peakIdx = i;
          }
          final busiestDay = dayCount[peakIdx] > 0 ? dayNames[peakIdx] : 'N/A';

          final conclusion = _conclusion(
            thisTotal: thisTotal,
            prevTotal: prevTotal,
            thisTypes: thisTypes,
            prevTypes: prevTypes,
            thisMonthName: _monthNames[_selectedMonth.month - 1],
            prevMonthName: _monthNames[_compareMonth.month - 1],
          );

          final sortedTypes = thisTypes.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              'Lifetime appts',
                              '$totalAllTime',
                              Icons.analytics_outlined,
                              AppColors.info,
                            ),
                          ),
                          AppSpacing.hLg,
                          Expanded(
                            child: _kpiCard(
                              'Peak day',
                              busiestDay,
                              Icons.trending_up_rounded,
                              AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vXxxl,
                      Text('Compare Appointment Volumes', style: AppTypography.headlineSmall),
                      AppSpacing.vMd,
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _miniPicker(
                                    label: 'Month A',
                                    date: _selectedMonth,
                                    color: AppColors.primary,
                                    onPrev: () => setState(() =>
                                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
                                    onNext: () {
                                      final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                                      if (!next.isAfter(DateTime.now())) {
                                        setState(() => _selectedMonth = next);
                                      }
                                    },
                                  ),
                                ),
                                Container(width: 1, height: 54, color: AppColors.divider),
                                Expanded(
                                  child: _miniPicker(
                                    label: 'Month B',
                                    date: _compareMonth,
                                    color: AppColors.textSecondary,
                                    onPrev: () => setState(() =>
                                        _compareMonth = DateTime(_compareMonth.year, _compareMonth.month - 1)),
                                    onNext: () {
                                      final next = DateTime(_compareMonth.year, _compareMonth.month + 1);
                                      if (!next.isAfter(DateTime.now())) {
                                        setState(() => _compareMonth = next);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.vLg,
                            const Divider(height: 1, color: AppColors.divider),
                            AppSpacing.vXl,
                            _comparisonBar(
                              label: '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                              count: thisTotal,
                              max: thisTotal > prevTotal ? thisTotal : prevTotal,
                              color: AppColors.primary,
                            ),
                            AppSpacing.vSm,
                            _comparisonBar(
                              label: '${_monthNames[_compareMonth.month - 1]} ${_compareMonth.year}',
                              count: prevTotal,
                              max: thisTotal > prevTotal ? thisTotal : prevTotal,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vLg,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: AppRadii.rLg,
                          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconAvatar(
                              icon: Icons.auto_awesome_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                            AppSpacing.hMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'System Insight',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  AppSpacing.vXs,
                                  Text(
                                    conclusion,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vXxxl,
                      Text(
                        'Visit Type Breakdown — ${_monthNames[_selectedMonth.month - 1]}',
                        style: AppTypography.headlineSmall,
                      ),
                      AppSpacing.vMd,
                      if (sortedTypes.isEmpty)
                        const EmptyState(
                          icon: Icons.insights_rounded,
                          title: 'No visits yet',
                          message: 'Visit types will appear as appointments are confirmed',
                          compact: true,
                        )
                      else
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: Column(
                            children: List.generate(sortedTypes.length, (i) {
                              final e = sortedTypes[i];
                              final ratio = thisTotal == 0 ? 0.0 : e.value / thisTotal;
                              final col = _breakdownColors[i % _breakdownColors.length];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${i + 1}. ${e.key}',
                                          style: AppTypography.titleSmall,
                                        ),
                                        Text(
                                          '${e.value} • ${(ratio * 100).toStringAsFixed(0)}%',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                                        ),
                                      ],
                                    ),
                                    AppSpacing.vSm,
                                    Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: AppColors.divider,
                                            borderRadius: AppRadii.rXs,
                                          ),
                                        ),
                                        LayoutBuilder(
                                          builder: (ctx, c) => AnimatedContainer(
                                            duration: const Duration(milliseconds: 700),
                                            curve: Curves.easeOutQuart,
                                            height: 8,
                                            width: c.maxWidth * ratio,
                                            decoration: BoxDecoration(
                                              color: col,
                                              borderRadius: AppRadii.rXs,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      AppSpacing.vHuge,
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

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconAvatar(icon: icon, color: color, size: 40, circle: true),
          AppSpacing.vMd,
          Text(value, style: AppTypography.headlineSmall),
          AppSpacing.vXs,
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _miniPicker({
    required String label,
    required DateTime date,
    required Color color,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Column(
      children: [
        Container(
          height: 6,
          width: 32,
          decoration: BoxDecoration(color: color, borderRadius: AppRadii.rXs),
        ),
        AppSpacing.vSm,
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.vXs,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onPrev,
              child: const Icon(Icons.chevron_left_rounded, size: 26, color: AppColors.textSecondary),
            ),
            AppSpacing.hSm,
            Column(
              children: [
                Text(_monthNames[date.month - 1], style: AppTypography.titleSmall),
                Text(
                  '${date.year}',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
            AppSpacing.hSm,
            GestureDetector(
              onTap: onNext,
              child: const Icon(Icons.chevron_right_rounded, size: 26, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _comparisonBar({
    required String label,
    required int count,
    required int max,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadii.rSm,
                ),
              ),
              LayoutBuilder(builder: (ctx, c) {
                final w = max == 0 ? 0.0 : (count / max) * c.maxWidth;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutQuart,
                  height: 22,
                  width: w.clamp(0, c.maxWidth),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadii.rSm,
                  ),
                );
              }),
            ],
          ),
        ),
        AppSpacing.hSm,
        Text('$count', style: AppTypography.titleSmall),
      ],
    );
  }
}
