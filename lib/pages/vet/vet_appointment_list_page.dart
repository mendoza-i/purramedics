import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/utils/responsive.dart';
import 'package:purramedics/pages/addpet_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class VetAppointmentListPage extends StatefulWidget {
  const VetAppointmentListPage({super.key});

  @override
  State<VetAppointmentListPage> createState() => _VetAppointmentListPageState();
}

class _VetAppointmentListPageState extends State<VetAppointmentListPage> {
  final FirestoreService firestoreService = FirestoreService();
  int _selectedYear = DateTime.now().year;
  final Map<String, bool> _expandedMonths = {};

  @override
  void initState() {
    super.initState();
    firestoreService.markAppointmentsAsRead();
  }

  void _updateStatus(String docId, String newStatus) {
    FirebaseFirestore.instance.collection('appointments').doc(docId).update({
      'status': newStatus,
    });
  }

  Color _statusColor(String status, bool isPast) {
    if (isPast) return AppColors.textTertiary;
    return switch (status) {
      'Confirmed' => AppColors.success,
      'Pending' => AppColors.warning,
      'Declined' => AppColors.danger,
      _ => AppColors.primary,
    };
  }

  BadgeTone _statusTone(String status, bool isPast) {
    if (isPast) return BadgeTone.neutral;
    return switch (status) {
      'Confirmed' => BadgeTone.success,
      'Pending' => BadgeTone.warning,
      'Declined' => BadgeTone.danger,
      _ => BadgeTone.primary,
    };
  }

  void _showAppointmentDetails(Map<String, dynamic> apt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
        title: Text('Appointment details', style: AppTypography.headlineSmall),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                apt['visitType'] ?? 'Appointment',
                style: AppTypography.titleMedium,
              ),
              AppSpacing.vMd,
              _kv('Date', apt['date'] ?? 'N/A'),
              _kv('Owner', apt['userName'] ?? 'N/A'),
              _kv('Pet', apt['petName'] ?? 'N/A'),
              _kv('Status', apt['status'] ?? 'Pending'),
              AppSpacing.vMd,
              const Divider(color: AppColors.divider),
              AppSpacing.vMd,
              Text('Notes', style: AppTypography.titleSmall),
              AppSpacing.vXs,
              Text(
                apt['additionalInfo'] ??
                    'No notes were added by the pet owner.',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            k,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(child: Text(v, style: AppTypography.bodyMedium)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Appointment Schedule', style: AppTypography.headlineLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getAllAppointmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData) {
            return const EmptyState(
              icon: Icons.calendar_today_outlined,
              title: 'No appointments yet',
            );
          }

          final appointments = snapshot.data!;
          final now = DateTime.now();

          final yearApts = <Map<String, dynamic>>[];
          for (final apt in appointments) {
            try {
              final parts = apt['date'].toString().split('-');
              if (parts.length == 3 && int.parse(parts[0]) == _selectedYear) {
                yearApts.add(apt);
              }
            } catch (_) {}
          }
          yearApts.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

          final grouped = <int, List<Map<String, dynamic>>>{};
          for (final apt in yearApts) {
            try {
              final parts = apt['date'].toString().split('-');
              if (parts.length == 3) {
                final m = int.parse(parts[1]);
                grouped.putIfAbsent(m, () => []).add(apt);
              }
            } catch (_) {}
          }

          final displayMonths = <int>[];
          if (_selectedYear == now.year) {
            displayMonths.add(now.month);
            for (var i = 12; i >= 1; i--) {
              if (i != now.month) displayMonths.add(i);
            }
          } else {
            for (var i = 12; i >= 1; i--) {
              displayMonths.add(i);
            }
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                await Future.delayed(const Duration(milliseconds: 600)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.contentMaxWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildYearToggle(),
                      AppSpacing.vXxl,
                      ...displayMonths.map((m) {
                        final list = grouped[m] ?? [];
                        final isCurrent =
                            _selectedYear == now.year && m == now.month;
                        return _buildMonthSection(m, list, isCurrent, now);
                      }),
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

  Widget _buildYearToggle() {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textPrimary,
            onPressed: () => setState(() => _selectedYear--),
          ),
          Text('YEAR $_selectedYear', style: AppTypography.titleLarge),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textPrimary,
            onPressed: () => setState(() => _selectedYear++),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(
    int monthInt,
    List<Map<String, dynamic>> list,
    bool isCurrent,
    DateTime now,
  ) {
    final monthDate = DateTime(_selectedYear, monthInt, 1);
    final monthLabel = DateFormat('MMMM yyyy').format(monthDate).toUpperCase();
    final isExpanded = _expandedMonths[monthLabel] ?? isCurrent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = Responsive.isWide(context)
              ? 3
              : (Responsive.isTablet(context) ? 2 : 1);
          final cardWidth =
              (constraints.maxWidth - (AppSpacing.lg * (cols - 1))) / cols -
              0.1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: AppRadii.rMd,
                onTap: () =>
                    setState(() => _expandedMonths[monthLabel] = !isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: isCurrent
                      ? BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: AppRadii.rMd,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        )
                      : null,
                  child: Row(
                    children: [
                      Text(
                        monthLabel.split(' ')[0],
                        style:
                            (isCurrent
                                    ? AppTypography.headlineMedium
                                    : AppTypography.headlineSmall)
                                .copyWith(
                                  color: isCurrent
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                      ),
                      if (isCurrent) ...[
                        AppSpacing.hSm,
                        const AppBadge(
                          label: 'CURRENT',
                          tone: BadgeTone.primary,
                        ),
                      ],
                      AppSpacing.hMd,
                      AppBadge(
                        label: '${list.length} appointments',
                        tone: BadgeTone.neutral,
                      ),
                      const Spacer(),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                AppSpacing.vMd,
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      'No appointments scheduled for this month.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: list
                        .map(
                          (apt) => SizedBox(
                            width: cardWidth,
                            child: _buildAppointmentCard(apt, now),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt, DateTime now) {
    final id = apt['id'];
    final status = (apt['status'] as String?) ?? 'Pending';
    final userName = apt['userName'] ?? 'Unknown user';

    var isPast = false;
    var explicitDate = apt['date'] ?? 'No date';
    try {
      final parts = apt['date'].toString().split('-');
      if (parts.length == 3) {
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        isPast = d.isBefore(DateTime(now.year, now.month, now.day));
        explicitDate = DateFormat('MMMM dd, yyyy').format(d);
      }
    } catch (_) {}

    final accent = _statusColor(status, isPast);

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: AppRadii.rLg,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.textInverse,
        ),
      ),
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
            title: Text(
              'Delete appointment?',
              style: AppTypography.headlineSmall,
            ),
            content: Text(
              "Are you sure you want to completely delete $userName's appointment?",
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  firestoreService.deleteAppointment(id);
                  Navigator.pop(context, true);
                },
                child: Text(
                  'Delete',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => _showAppointmentDetails(apt),
        child: ClipRRect(
          borderRadius: AppRadii.rLg,
          child: Container(
            decoration: BoxDecoration(
              color: isPast ? AppColors.surfaceAlt : accent.withOpacity(0.04),
              border: Border.all(color: accent.withOpacity(0.3), width: 1),
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.pets_rounded, color: accent, size: 24),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt['visitType'] ?? 'Appointment',
                            style: AppTypography.titleMedium.copyWith(
                              color: isPast
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.vXs,
                          Text(
                            '${apt['petName']} • $userName',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppBadge(label: status, tone: _statusTone(status, isPast)),
                  ],
                ),
                AppSpacing.vLg,
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      AppSpacing.hSm,
                      Text(
                        explicitDate,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            AppSpacing.hXs,
                            Text(
                              apt['time'] ?? 'No time',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vLg,
                const Divider(color: AppColors.divider, height: 1),
                AppSpacing.vMd,
                _buildActionRow(apt, status, isPast),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(Map<String, dynamic> apt, String status, bool isPast) {
    final id = apt['id'];
    if (status == 'Pending' && !isPast) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _updateStatus(id, 'Declined'),
            child: Text(
              'Decline',
              style: AppTypography.labelLarge.copyWith(color: AppColors.danger),
            ),
          ),
          PrimaryButton(
            label: 'Confirm',
            size: AppButtonSize.small,
            isExpanded: false,
            backgroundColor: AppColors.success,
            onPressed: () => _updateStatus(id, 'Confirmed'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: AppRadii.rSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes_rounded,
                  size: 18,
                  color: AppColors.info,
                ),
                AppSpacing.hSm,
                Expanded(
                  child: Text(
                    apt['additionalInfo'] ?? 'No additional notes',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isPast && apt['userEmail'] != null)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddPetPage(prefilledOwnerEmail: apt['userEmail']),
              ),
            ),
            icon: const Icon(
              Icons.note_add_rounded,
              color: AppColors.textTertiary,
            ),
            tooltip: 'Add details to pet',
          ),
      ],
    );
  }
}
