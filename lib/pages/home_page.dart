import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:purramedics/components/bottom_nav_bar.dart';
import 'package:purramedics/pages/symptoms_page.dart';
import 'package:purramedics/pages/appointments_page.dart';
import 'package:purramedics/pages/pets_page.dart';
import 'package:purramedics/pages/chat_room_page.dart';
import 'package:purramedics/pages/vet/widgets/seasonal_forecast_widget.dart';
import '../services/firestore_service.dart';
import '../../models/event.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/widgets.dart';
import 'dart:async';
import '../utils/audio_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _lastConfirmedCount = -1;
  int _lastUnreadCount = -1;
  StreamSubscription<List<Map<String, dynamic>>>? _appointmentsSub;
  StreamSubscription<int>? _unreadSub;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _appointmentsSub = FirestoreService().getUserAppointmentsStream(user.uid).listen((appointments) {
        final confirmedCount = appointments.where((a) => a['status'] == 'Confirmed').length;
        if (_lastConfirmedCount >= 0 && confirmedCount > _lastConfirmedCount && mounted) {
          AudioUtils.playNotificationSound();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('✅ Your appointment has been confirmed!')),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        _lastConfirmedCount = confirmedCount;
      });

      _unreadSub = FirestoreService().getUserUnreadCountStream(user.uid).listen((count) {
        if (_lastUnreadCount >= 0 && count > _lastUnreadCount && mounted) {
          AudioUtils.playNotificationSound();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('💬 You have a new message from the clinic!')),
                ],
              ),
              backgroundColor: AppColors.info,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        _lastUnreadCount = count;
      });
    }
  }

  @override
  void dispose() {
    _appointmentsSub?.cancel();
    _unreadSub?.cancel();
    super.dispose();
  }

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHome() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@')[0] ?? 'Friend';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 800));
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
                const AppBadge(label: 'OVERVIEW', tone: BadgeTone.secondary),
                AppSpacing.vMd,
                Text('Hello, $name 👋', style: AppTypography.displayLarge),
                AppSpacing.vXs,
                Text(
                  "Manage your pet's health and upcoming appointments.",
                  style: AppTypography.bodyMedium,
                ),
                AppSpacing.vXxl,

                _buildVetChatCta(),
                AppSpacing.vXxl,

                const SeasonalForecastWidget(),
                AppSpacing.vXxl,

                const SectionHeader(
                  title: 'Our Services',
                  subtitle: 'Tap a service to book an appointment',
                ),
                AppSpacing.vLg,
                _buildServices(),
                AppSpacing.vXxxl,

                const SectionHeader(title: 'Upcoming Events'),
                AppSpacing.vLg,
                _buildEventsList(isUpcoming: true),
                AppSpacing.vXxxl,

                Center(child: Text('Daily Tip', style: AppTypography.headlineMedium)),
                AppSpacing.vLg,
                Center(child: _buildDailyTip()),
                AppSpacing.vXxxl,

                const SectionHeader(title: 'Past Events'),
                AppSpacing.vLg,
                _buildEventsList(isUpcoming: false),
                AppSpacing.vXxl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVetChatCta() {
    return GestureDetector(
      onTap: () {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              chatId: user.uid,
              chatUserName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
              isVet: false,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadii.rLg,
          boxShadow: AppShadows.colored(AppColors.primary, opacity: 0.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 24),
            ),
            AppSpacing.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat with Vet',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.textInverse),
                  ),
                  AppSpacing.vXs,
                  Text(
                    'Ask a professional directly',
                    style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(delay: 4000.ms, duration: 1500.ms, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildServices() {
    final services = [
      (title: "General\nCheckup", icon: Icons.health_and_safety_outlined, color: AppColors.primary, type: 'General Checkup'),
      (title: 'Vaccination', icon: Icons.vaccines_outlined, color: AppColors.info, type: 'Vaccination'),
      (title: "Surgery\n& Procedure", icon: Icons.medical_services_outlined, color: AppColors.secondary, type: 'Surgery'),
      (title: "Deworming\n& Parasite", icon: Icons.bug_report_outlined, color: AppColors.success, type: 'Deworming'),
      (title: "Grooming\nSession", icon: Icons.shower_outlined, color: AppColors.warning, type: 'Grooming'),
    ];

    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final s in services)
            ServiceCard(
              title: s.title,
              icon: s.icon,
              color: s.color,
              onTap: () {
                navigateBottomBar(1);
                AppointmentsPage.showBookDialog(context, initialVisitType: s.title);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDailyTip() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final currentWeek = dayOfYear ~/ 7;

    final tips = <Map<String, dynamic>>[
      {
        'hook': 'Why does your cat suddenly hate their water bowl? 💧',
        'detail': "Cats are notoriously bad drinkers, but it might just be the bowl! Their whiskers are super sensitive. Learn why a wider bowl or a running fountain can prevent kidney issues.",
        'url': 'https://cats.com/whisker-fatigue',
        'icon': Icons.water_drop_outlined,
        'color': AppColors.info,
      },
      {
        'hook': 'The silent danger lurking in your kitchen! 🍫',
        'detail': "We all know chocolate is bad, but did you know Xylitol (sugar substitute) in peanut butter is legally lethal to dogs? Always check the ingredients before sharing a snack.",
        'url': 'https://vcahospitals.com/know-your-pet/xylitol-toxicity-in-dogs',
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.danger,
      },
      {
        'hook': "Is your pet 'too old' to play? Think again! 🎾",
        'detail': 'Cognitive decline affects pets too. Mental stimulation through puzzle toys and short training sessions can keep their brain young and active for years longer.',
        'url': 'https://vcahospitals.com/know-your-pet/senior-dog-care-special-considerations-for-dogs',
        'icon': Icons.psychology_outlined,
        'color': AppColors.warning,
      },
      {
        'hook': 'The hidden cost of skipping the annual vet visit. 🩺',
        'detail': 'Pets age 7 times faster than we do. Catching dental disease or early renal failure during a routine checkup can literally save thousands of dollars and extend their life.',
        'url': 'https://www.avma.org/resources-tools/pet-owners/petcare/regular-veterinary-visits',
        'icon': Icons.medical_services_outlined,
        'color': AppColors.primary,
      },
      {
        'hook': 'Why is your dog eating grass? 🌱',
        'detail': "It's a common myth that they only do it when sick! Often, they just like the texture or need more fiber. However, if they vomit frequently after, it's time for a vet visit.",
        'url': 'https://vcahospitals.com/know-your-pet/why-do-dogs-eat-grass',
        'icon': Icons.grass_outlined,
        'color': AppColors.success,
      },
      {
        'hook': "Purring doesn't always mean your cat is happy! 🙀",
        'detail': 'Cats also purr to self-soothe when they are in pain, stressed, or frightened. Pay attention to their body language to decode what their purr actually means.',
        'url': 'https://www.scientificamerican.com/article/why-do-cats-purr/',
        'icon': Icons.hearing_outlined,
        'color': AppColors.secondary,
      },
      {
        'hook': "Are you trimming your pet's nails wrong? ✂️",
        'detail': "Long nails aren't just loud on hardwood; they actually change how your dog walks, leading to severe joint pain and arthritis over time. Learn the 'quick' way to trim!",
        'url': 'https://www.akc.org/expert-advice/health/how-to-trim-dogs-nails-safely/',
        'icon': Icons.content_cut_outlined,
        'color': AppColors.primaryDark,
      },
    ];

    final tip = tips[currentWeek % tips.length];
    final color = tip['color'] as Color;

    return AppCard(
      onTap: () async {
        final uri = Uri.parse(tip['url'] as String);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Could not launch URL: $uri');
        }
      },
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: AppColors.divider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconAvatar(icon: tip['icon'] as IconData, color: color, circle: true, size: 48),
              AppSpacing.hLg,
              Expanded(
                child: Text(tip['hook'] as String, style: AppTypography.titleLarge),
              ),
            ],
          ),
          AppSpacing.vLg,
          Text(tip['detail'] as String, style: AppTypography.bodyMedium),
          AppSpacing.vLg,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Read article',
                style: AppTypography.labelMedium.copyWith(color: color),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: color),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _parseCustomDate(String dateStr) {
    try {
      final parts = dateStr.trim().split(' at ');
      if (parts.length == 2) {
        final dateParts = parts[0].split('/');
        if (dateParts.length == 3) {
          final timeStr = parts[1].trim();
          final timeParts = timeStr.split(' ');
          final hm = timeParts[0].split(':');
          int hour = int.parse(hm[0]);
          int minute = int.parse(hm[1]);
          if (timeParts.length > 1) {
            if (timeParts[1].toUpperCase() == 'PM' && hour < 12) hour += 12;
            if (timeParts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
          }
          return DateTime(int.parse(dateParts[2]), int.parse(dateParts[0]), int.parse(dateParts[1]), hour, minute);
        }
      } else if (dateStr.contains('/')) {
        final dateParts = dateStr.split('/');
        if (dateParts.length == 3) {
          return DateTime(int.parse(dateParts[2]), int.parse(dateParts[0]), int.parse(dateParts[1]));
        }
      }
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Widget _buildEventsList({required bool isUpcoming}) {
    return SizedBox(
      height: 160,
      child: StreamBuilder<List<Event>>(
        stream: FirestoreService().getEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: AppTypography.bodyMedium));
          }

          final allEvents = snapshot.data ?? [];
          if (allEvents.isEmpty) {
            return EmptyState(
              compact: true,
              icon: isUpcoming ? Icons.event_busy_outlined : Icons.history_toggle_off_outlined,
              title: isUpcoming ? 'No upcoming events' : 'No past events',
            );
          }

          final now = DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);

          final parsed = <Map<String, dynamic>>[];
          for (final e in allEvents) {
            try {
              var startStr = e.date;
              if (e.date.contains(' to ')) startStr = e.date.split(' to ')[0].trim();
              final dt = _parseCustomDate(startStr);
              if (dt == null) continue;
              parsed.add({'event': e, 'startDate': dt});
            } catch (_) {}
          }

          final filtered = parsed.where((m) {
            final d = m['startDate'] as DateTime;
            return isUpcoming
                ? (d.isAfter(startOfToday) || d.isAtSameMomentAs(startOfToday))
                : d.isBefore(startOfToday);
          }).toList()
            ..sort((a, b) => (a['startDate'] as DateTime).compareTo(b['startDate'] as DateTime));

          if (filtered.isEmpty) {
            return EmptyState(
              compact: true,
              icon: isUpcoming ? Icons.event_busy_outlined : Icons.history_toggle_off_outlined,
              title: isUpcoming ? 'No upcoming events' : 'No past events',
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final item = filtered[i];
              final event = item['event'] as Event;
              final startDate = item['startDate'] as DateTime;
              final badgeDate = DateFormat('MMM\nd').format(startDate);

              String popupDate;
              if (event.date.contains(' to ')) {
                try {
                  final endStr = event.date.split(' to ')[1];
                  final endDate = _parseCustomDate(endStr);
                  final s = DateFormat("MMMM d, yyyy 'at' h:mm a").format(startDate);
                  final e = endDate != null
                      ? DateFormat("MMMM d, yyyy 'at' h:mm a").format(endDate)
                      : 'Unknown End Time';
                  popupDate = '$s\nto\n$e';
                } catch (_) {
                  popupDate = DateFormat('MMMM d, yyyy').format(startDate);
                }
              } else {
                popupDate = (event.date.contains('at') || event.date.contains(':'))
                    ? DateFormat("MMMM d, yyyy 'at' h:mm a").format(startDate)
                    : DateFormat('MMMM d, yyyy').format(startDate);
              }

              return _buildEventCard(
                title: event.title,
                location: event.location,
                badgeDate: badgeDate,
                popupDate: popupDate,
                description: event.description,
                color: Color(event.colorValue),
                isPast: !isUpcoming,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String location,
    required String badgeDate,
    required String popupDate,
    required String description,
    required Color color,
    bool isPast = false,
  }) {
    final activeColor = isPast ? AppColors.textTertiary : color;
    return GestureDetector(
      onTap: () => _showEventSheet(title, popupDate, location, description, color, isPast),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.rLg,
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.12),
                    borderRadius: AppRadii.rSm,
                  ),
                  child: Text(
                    badgeDate,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(color: activeColor, height: 1.2),
                  ),
                ),
                const Spacer(),
                Icon(Icons.touch_app_outlined, color: AppColors.textTertiary, size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                ),
                AppSpacing.vXs,
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                    AppSpacing.hXs,
                    Expanded(
                      child: Text(
                        location,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventSheet(String title, String popupDate, String location, String description, Color color, bool isPast) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadii.rFull,
                    ),
                  ),
                ),
                AppSpacing.vXl,
                Row(
                  children: [
                    IconAvatar(
                      icon: Icons.event_note_outlined,
                      color: isPast ? AppColors.textTertiary : color,
                      size: 48,
                    ),
                    AppSpacing.hLg,
                    Expanded(child: Text(title, style: AppTypography.displaySmall)),
                  ],
                ),
                AppSpacing.vXl,
                if (isPast)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppBadge(
                      label: 'This event has already ended',
                      tone: BadgeTone.danger,
                      icon: Icons.history,
                    ),
                  ),
                AppCard(
                  color: AppColors.surfaceAlt,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  shadow: const [],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconAvatar(
                        icon: Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        circle: true,
                        size: 40,
                      ),
                      AppSpacing.hLg,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DATE & TIME', style: AppTypography.labelSmall),
                            AppSpacing.vXs,
                            Text(popupDate, style: AppTypography.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vMd,
                AppCard(
                  color: AppColors.surfaceAlt,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  shadow: const [],
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconAvatar(
                        icon: Icons.location_on_outlined,
                        color: AppColors.secondary,
                        circle: true,
                        size: 40,
                      ),
                      AppSpacing.hLg,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('LOCATION', style: AppTypography.labelSmall),
                            AppSpacing.vXs,
                            Text(location, style: AppTypography.bodyLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vXl,
                Text('About this Event', style: AppTypography.headlineSmall),
                AppSpacing.vSm,
                Text(
                  description.isEmpty ? 'No description provided.' : description,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
                AppSpacing.vXxl,
                PrimaryButton(
                  label: isPast ? 'Got it' : 'Remind me',
                  icon: isPast ? Icons.check_rounded : Icons.notifications_active_outlined,
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isPast) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Event saved to your calendar')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHome(),
      const AppointmentsPage(),
      const SymptomsPage(),
      const PetsPage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: MyBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: navigateBottomBar,
      ),
      body: SafeArea(child: pages[_selectedIndex]),
    );
  }
}
