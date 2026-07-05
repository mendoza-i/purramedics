import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/responsive.dart';
import 'package:purramedics/widgets/widgets.dart';
import 'vet_event_creation_page.dart';

class VetEventListPage extends StatefulWidget {
  const VetEventListPage({super.key});

  @override
  State<VetEventListPage> createState() => _VetEventListPageState();
}

class _VetEventListPageState extends State<VetEventListPage> {
  final _firestoreService = FirestoreService();
  int _currentTab = 0;

  void _deleteEvent(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete event?', style: AppTypography.titleLarge),
        content: Text(
          "Permanently delete '$title'?",
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteEvent(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Event deleted'),
                    backgroundColor: AppColors.textPrimary,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: AppTypography.labelLarge.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _editEvent(Map<String, dynamic> eventData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VetEventCreationPage(eventMap: eventData, eventId: eventData['id']),
      ),
    );
  }

  IconData _iconFor(String? name) {
    const icons = {
      'vaccine': Icons.vaccines_rounded,
      'adoption': Icons.pets_rounded,
      'checkup': Icons.health_and_safety_rounded,
      'community': Icons.people_rounded,
      'emergency': Icons.warning_amber_rounded,
    };
    return icons[name] ?? Icons.event_rounded;
  }

  (List<Map<String, dynamic>>, List<Map<String, dynamic>>) _splitEvents(
    List<Map<String, dynamic>> events,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = <Map<String, dynamic>>[];
    final past = <Map<String, dynamic>>[];

    for (var event in events) {
      bool isPast = false;
      try {
        final dateStr = event['date'].toString();
        String compareStr = dateStr;
        if (dateStr.contains(' to '))
          compareStr = dateStr.split(' to ')[1].trim();
        final parts = compareStr.split(' at ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('/');
          if (dateParts.length == 3) {
            final timeParts = parts[1].trim().split(' ');
            final hm = timeParts[0].split(':');
            int hour = int.parse(hm[0]);
            int minute = int.parse(hm[1]);
            if (timeParts.length > 1) {
              if (timeParts[1] == 'PM' && hour < 12) hour += 12;
              if (timeParts[1] == 'AM' && hour == 12) hour = 0;
            }
            final d = DateTime(
              int.parse(dateParts[2]),
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              hour,
              minute,
            );
            if (d.isBefore(now)) isPast = true;
          }
        } else {
          final dateParts = compareStr.split('/');
          if (dateParts.length == 3) {
            final d = DateTime(
              int.parse(dateParts[2]),
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
            );
            if (d.isBefore(today)) isPast = true;
          }
        }
      } catch (_) {}
      if (isPast) {
        past.add(event);
      } else {
        upcoming.add(event);
      }
    }
    return (upcoming, past);
  }

  String _formatDate(String raw) {
    try {
      if (raw.contains(' to ')) {
        final parts = raw.split(' to ');
        final startParts = parts[0].split(' at ');
        final endParts = parts[1].split(' at ');
        final startD = DateFormat('MM/dd/yyyy').parse(startParts[0]);
        final endD = DateFormat('MM/dd/yyyy').parse(endParts[0]);
        if (startD.year == endD.year &&
            startD.month == endD.month &&
            startD.day == endD.day) {
          return "${DateFormat('MMMM d, yyyy').format(startD)} • ${startParts[1]} to ${endParts.length > 1 ? endParts[1] : ''}";
        }
        return "${DateFormat('MMM d').format(startD)}, ${startParts[1]} to ${DateFormat('MMM d').format(endD)}, ${endParts.length > 1 ? endParts[1] : ''}";
      }
      if (raw.contains(' at ')) {
        final startParts = raw.split(' at ');
        final d = DateFormat('MM/dd/yyyy').parse(startParts[0]);
        return "${DateFormat('MMMM d, yyyy').format(d)} • ${startParts[1]}";
      }
      final d = DateFormat('MM/dd/yyyy').parse(raw);
      return DateFormat('MMMM d, yyyy').format(d);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Events', style: AppTypography.headlineLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: PrimaryButton(
              label: 'Publish',
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VetEventCreationPage()),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getEventsStreamMap(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final events = snapshot.data ?? [];
            final (upcoming, past) = _splitEvents(events);
            final active = _currentTab == 0 ? upcoming : past;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  Future.delayed(const Duration(milliseconds: 600)),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.pagePadding(context),
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.contentMaxWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSegmentedControl(upcoming.length, past.length),
                        AppSpacing.vXxl,
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: active.isEmpty
                              ? SizedBox(
                                  key: ValueKey('empty_$_currentTab'),
                                  width: double.infinity,
                                  child: EmptyState(
                                    icon: _currentTab == 0
                                        ? Icons.event_available_rounded
                                        : Icons.history_rounded,
                                    title: _currentTab == 0
                                        ? 'No upcoming events'
                                        : 'No past events',
                                    message: _currentTab == 0
                                        ? 'Create your first event to get started'
                                        : 'Completed events will show up here',
                                    actionLabel: _currentTab == 0
                                        ? 'Create event'
                                        : null,
                                    onAction: _currentTab == 0
                                        ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const VetEventCreationPage(),
                                            ),
                                          )
                                        : null,
                                  ),
                                )
                              : _buildGrid(
                                  active,
                                  key: ValueKey('grid_$_currentTab'),
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
      ),
    );
  }

  Widget _buildSegmentedControl(int upCount, int pastCount) {
    Widget tab(int idx, String label, int count) {
      final active = _currentTab == idx;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _currentTab = idx),
          borderRadius: AppRadii.rLg,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: AppRadii.rLg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: active
                        ? AppColors.textInverse
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacing.hXs,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withOpacity(0.25)
                        : AppColors.divider,
                    borderRadius: AppRadii.rFull,
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.labelSmall.copyWith(
                      color: active
                          ? AppColors.textInverse
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadii.rLg,
      ),
      child: Row(
        children: [tab(0, 'Upcoming', upCount), tab(1, 'Past', pastCount)],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> events, {Key? key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final cols = Responsive.isWide(context) ? 2 : 1;
        final width =
            (constraints.maxWidth - (AppSpacing.lg * (cols - 1))) / cols - 0.1;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: events
              .map(
                (e) => SizedBox(
                  width: width,
                  child: _buildEventCard(e, _currentTab == 1),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isPast) {
    final id = event['id'];
    final title = event['title'] ?? 'Untitled';
    final location = event['location'] ?? 'Unknown location';
    final raw = event['date'] ?? '';
    final colorVal = event['colorValue'] ?? AppColors.primary.value;
    final accent = isPast ? AppColors.textTertiary : Color(colorVal);
    final formatted = _formatDate(raw);

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
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async {
        _deleteEvent(id, title);
        return false;
      },
      child: AppCard(
        onTap: isPast ? null : () => _editEvent(event),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        color: isPast ? AppColors.surfaceAlt : AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconAvatar(
                  icon: _iconFor(event['iconName']),
                  color: accent,
                  background: accent.withOpacity(0.12),
                  size: 48,
                ),
                const Spacer(),
                AppBadge(
                  label: isPast ? 'Past' : 'Upcoming',
                  tone: isPast ? BadgeTone.neutral : BadgeTone.success,
                ),
              ],
            ),
            AppSpacing.vLg,
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            AppSpacing.vMd,
            _infoRow(Icons.calendar_today_rounded, formatted),
            AppSpacing.vXs,
            _infoRow(Icons.location_on_outlined, location),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        AppSpacing.hSm,
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
