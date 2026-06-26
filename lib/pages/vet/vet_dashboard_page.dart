import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/pages/vet/vet_patient_list_page.dart';
import 'package:purramedics/pages/vet/vet_event_list_page.dart';
import 'package:purramedics/pages/vet/vet_appointment_list_page.dart';
import 'package:purramedics/pages/vet/vet_requests_page.dart';
import 'package:purramedics/pages/vet/vet_inbox_page.dart';
import 'package:purramedics/pages/vet/vet_settings_page.dart';
import 'package:purramedics/pages/vet/vet_availability_page.dart';
import 'package:purramedics/pages/vet/widgets/seasonal_forecast_widget.dart';
import 'package:purramedics/pages/vet/widgets/descriptive_analytics_widget.dart';
import 'package:purramedics/pages/vet/widgets/revenue_stats_widget.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/responsive.dart';
import 'package:purramedics/utils/audio_utils.dart';
import 'package:purramedics/widgets/widgets.dart';

class VetDashboardPage extends StatefulWidget {
  const VetDashboardPage({super.key});

  @override
  State<VetDashboardPage> createState() => _VetDashboardPageState();
}

class _VetDashboardPageState extends State<VetDashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  int _lastPendingCount = -1;
  int _lastUnreadCount = -1;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<int>? _unreadSub;
  StreamSubscription<int>? _cancelledSub;
  int _lastCancelledCount = -1;

  @override
  void initState() {
    super.initState();
    _pendingSub = _firestoreService.getPendingAppointmentsCountStream().listen((count) {
      if (_lastPendingCount >= 0 && count > _lastPendingCount && mounted) {
        AudioUtils.playNotificationSound();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('🔔 New appointment has been booked!')),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      _lastPendingCount = count;
    });

    _cancelledSub = _firestoreService.getCancelledAppointmentsCountStream().listen((count) {
      if (_lastCancelledCount >= 0 && count > _lastCancelledCount && mounted) {
        AudioUtils.playNotificationSound();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_presentation_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('❌ An appointment has been cancelled by the pet owner.')),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      _lastCancelledCount = count;
    });

    _unreadSub = _firestoreService.getVetUnreadCountStream().listen((count) {
      if (_lastUnreadCount >= 0 && count > _lastUnreadCount && mounted) {
        AudioUtils.playNotificationSound();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('💬 You have a new message!')),
              ],
            ),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      _lastUnreadCount = count;
    });
  }

  @override
  void dispose() {
    _pendingSub?.cancel();
    _unreadSub?.cancel();
    _cancelledSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  _buildSidebar(),
                  Expanded(child: _buildMainContent()),
                ],
              )
            : _buildMainContent(),
      ),
    );
  }

  Widget _buildSidebar() {
    final items = [
      _SidebarItem('Dashboard', Icons.dashboard_rounded, null),
      _SidebarItem('Appointments', Icons.calendar_today_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetAppointmentListPage()));
      }, badgeStream: _firestoreService.getPendingAppointmentsCountStream()),
      _SidebarItem('My Patients', Icons.pets_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetPatientListPage()));
      }),
      _SidebarItem('Availability', Icons.event_available_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetAvailabilityPage()));
      }),
      _SidebarItem('Events', Icons.event_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetEventListPage()));
      }),
      _SidebarItem('Requests', Icons.medical_services_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetRequestsPage()));
      }),
      _SidebarItem('Inbox', Icons.inbox_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetInboxPage()));
      }, badgeStream: _firestoreService.getVetUnreadCountStream()),
      _SidebarItem('Settings', Icons.settings_rounded, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetSettingsPage()));
      }),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Text(
                    'Purramedics',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: items.map((item) {
                final isActive = item.onTap == null;
                return Material(
                  color: isActive ? AppColors.primarySurface : Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md + 2,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                          AppSpacing.hMd,
                          Expanded(
                            child: Text(
                              item.label,
                              style: AppTypography.titleSmall.copyWith(
                                color: isActive ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.badgeStream != null)
                            StreamBuilder<int>(
                              stream: item.badgeStream,
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                if (count == 0) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                          if (isActive)
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.pagePadding(context),
          vertical: AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                AppSpacing.vXxl,
                Text('Practice Tools', style: AppTypography.headlineMedium),
                AppSpacing.vMd,
                _buildToolsGrid(),
                AppSpacing.vXxl,
                if (Responsive.isWide(context)) _buildWideLayout() else _buildMobileLayout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              currentUser?.displayName ?? 'Dr. Vet',
              style: AppTypography.displaySmall,
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.sm,
          ),
          child: IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VetSettingsPage()),
            ),
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            tooltip: 'Settings',
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Revenue Overview', Icons.attach_money_rounded, AppColors.success),
              AppSpacing.vMd,
              const RevenueStatsWidget(),
              AppSpacing.vXxl,
              Row(
                children: [
                  Expanded(child: SizedBox(height: 226, child: _todayVisitsCard())),
                  AppSpacing.hLg,
                  Expanded(child: SizedBox(height: 226, child: _inboxCard())),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.hXxl,
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Patient Traffic', Icons.bar_chart_rounded, AppColors.success),
              AppSpacing.vMd,
              const DescriptiveAnalyticsWidget(),
              AppSpacing.vXxxl,
              _sectionTitle('Weather Forecast', Icons.show_chart_rounded, AppColors.info),
              AppSpacing.vMd,
              const SeasonalForecastWidget(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SizedBox(height: 140, child: _todayVisitsCard())),
            AppSpacing.hLg,
            Expanded(child: SizedBox(height: 140, child: _inboxCard())),
          ],
        ),
        AppSpacing.vXxxl,
        _sectionTitle('Revenue Overview', Icons.attach_money_rounded, AppColors.success),
        AppSpacing.vMd,
        const RevenueStatsWidget(),
        AppSpacing.vXxl,
        _sectionTitle('Patient Traffic', Icons.bar_chart_rounded, AppColors.success),
        AppSpacing.vMd,
        const DescriptiveAnalyticsWidget(),
        AppSpacing.vXxxl,
        _sectionTitle('Weather Forecast', Icons.show_chart_rounded, AppColors.info),
        AppSpacing.vMd,
        const SeasonalForecastWidget(),
      ],
    );
  }

  Widget _todayVisitsCard() => _statCard(
        title: "Today's Visits",
        icon: Icons.calendar_month_rounded,
        color: AppColors.warning,
        stream: _firestoreService.getTodayAppointmentsCountStream(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VetAppointmentListPage()),
        ),
      );

  Widget _inboxCard() => _statCard(
        title: 'Inbox',
        icon: Icons.mark_chat_unread_rounded,
        color: AppColors.info,
        stream: _firestoreService.getVetUnreadCountStream(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VetInboxPage()),
        ),
      );

  Widget _statCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<int> stream,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconAvatar(icon: icon, color: color, size: 40, circle: true),
              StreamBuilder<int>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  final count = snapshot.data ?? 0;
                  return Text(
                    '$count',
                    style: AppTypography.displaySmall.copyWith(
                      color: count > 0 ? color : AppColors.textTertiary,
                    ),
                  );
                },
              ),
            ],
          ),
          Text(title, style: AppTypography.titleSmall),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        IconAvatar(icon: icon, color: color, size: 36, circle: true),
        AppSpacing.hMd,
        Text(title, style: AppTypography.headlineSmall),
      ],
    );
  }

  Widget _buildToolsGrid() {
    final tools = [
      _Tool('Availability', 'Manage schedule', Icons.event_available_rounded, AppColors.secondary, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetAvailabilityPage()));
      }),
      _Tool('Appointments', 'View schedule', Icons.calendar_today_rounded, AppColors.warning, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetAppointmentListPage()));
      }, badgeStream: _firestoreService.getPendingAppointmentsCountStream()),
      _Tool('My Patients', 'Manage records', Icons.pets_rounded, AppColors.info, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetPatientListPage()));
      }),
      _Tool('Manage Events', 'Create drives', Icons.event_rounded, AppColors.secondaryDark, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetEventListPage()));
      }),
      _Tool('Requests', 'Review & approve', Icons.medical_services_rounded, AppColors.primary, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetRequestsPage()));
      }),
      _Tool('Inbox', 'Client messages', Icons.inbox_rounded, AppColors.info, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VetInboxPage()));
      }),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.gridColumns(context, mobileCount: 2, desktopCount: 3),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.0,
      children: tools.map(_buildToolCard).toList(),
    );
  }

  Widget _buildToolCard(_Tool t) {
    final card = AppCard(
      onTap: t.onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconAvatar(icon: t.icon, color: t.color, size: 56),
          AppSpacing.vMd,
          Text(t.title, textAlign: TextAlign.center, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          AppSpacing.vXs,
          Text(
            t.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );

    if (t.badgeStream == null) return card;

    return StreamBuilder<int>(
      stream: t.badgeStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            card,
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.colored(AppColors.danger, opacity: 0.4),
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Center(
                    child: Text(
                      '$count',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Stream<int>? badgeStream;
  _Tool(this.title, this.subtitle, this.icon, this.color, this.onTap, {this.badgeStream});
}

class _SidebarItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Stream<int>? badgeStream;
  _SidebarItem(this.label, this.icon, this.onTap, {this.badgeStream});
}
