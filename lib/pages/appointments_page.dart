import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  static Future<void> showBookDialog(BuildContext context, {String? initialVisitType}) async {
    final _firestoreService = FirestoreService();
    final _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      final activeCount = await _firestoreService.getActiveBookingCount(_user.uid);
      if (activeCount >= 2 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only have up to 2 active bookings at a time.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    final formKey = GlobalKey<FormState>();
    final petController = TextEditingController();
    final otherVisitController = TextEditingController();
    final infoController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final visitTypes = const ['Checkup', 'Vaccination', 'Grooming', 'Surgery', 'Others'];
    
    String selectedVisitType = visitTypes[0];
    if (initialVisitType != null) {
      final match = visitTypes.firstWhere(
        (t) => t.toLowerCase() == initialVisitType.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        selectedVisitType = match;
      } else {
        selectedVisitType = 'Others';
        otherVisitController.text = initialVisitType;
      }
    }

    bool isBooking = false;
    final consultMethods = const ['In-Person Appointment', 'Online Consultation'];
    String selectedMethod = consultMethods[0];
    String? selectedTimeSlot;
    final allTimeSlots = <String>[
      for (var h = 8; h <= 21; h++)
        '${(h == 0 || h == 12) ? 12 : h % 12}'.padLeft(2, '0') +
            ':00 ${h < 12 ? 'AM' : 'PM'}'
    ];

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.93,
              minChildSize: 0.6,
              maxChildSize: 0.97,
              builder: (_, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
                    ),
                    child: Column(
                      children: [
                        AppSpacing.vMd,
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadii.rFull),
                        ),
                        AppSpacing.vLg,
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                          child: Row(
                            children: [
                              const IconAvatar(icon: Icons.pets_rounded, color: AppColors.primary, size: 44),
                              AppSpacing.hMd,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Book appointment', style: AppTypography.headlineMedium),
                                  Text('Pet Treasure Clinic',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.vSm,
                        const Divider(),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.xxl),
                            children: [
                              Form(
                                key: formKey,
                                autovalidateMode: AutovalidateMode.always,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _section('Pet information'),
                                    AppSpacing.vSm,
                                    AppTextField(
                                      controller: petController,
                                      label: 'Pet name',
                                      prefixIcon: Icons.pets_rounded,
                                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a pet name' : null,
                                    ),
                                    AppSpacing.vMd,
                                    const SizedBox(height: AppSpacing.lg),
                                    StreamBuilder<Map<String, String>>(
                                      stream: FirestoreService().getServicePricesStream(),
                                      builder: (context, priceSnap) {
                                        final prices = priceSnap.data ?? {};
                                        return DropdownButtonFormField<String>(
                                          value: selectedVisitType,
                                          decoration: const InputDecoration(
                                            labelText: 'Visit type',
                                            prefixIcon: Icon(Icons.medical_services_outlined),
                                          ),
                                          items: visitTypes.map((t) {
                                            final price = prices[t.toLowerCase()];
                                            final label = price != null ? '$t — ₱$price' : t;
                                            return DropdownMenuItem(value: t, child: Text(label));
                                          }).toList(),
                                          onChanged: (v) => setDialogState(() => selectedVisitType = v!),
                                        );
                                      },
                                    ),
                                    if (selectedVisitType == 'Others') ...[
                                      AppSpacing.vMd,
                                      AppTextField(
                                        controller: otherVisitController,
                                        label: 'Specify reason',
                                        prefixIcon: Icons.edit_outlined,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Please specify' : null,
                                      ),
                                    ],
                                    AppSpacing.vXl,
                                    _section('Select date'),
                                    AppSpacing.vSm,
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: AppRadii.rMd,
                                        border: Border.all(color: AppColors.divider),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Builder(
                                        builder: (context) {
                                          final now = DateTime.now();
                                          final today = DateTime(now.year, now.month, now.day);
                                          final safeInitialDate = selectedDate.isBefore(today) ? today : selectedDate;
                                          return CalendarDatePicker(
                                            initialDate: safeInitialDate,
                                            firstDate: today,
                                            lastDate: today.add(const Duration(days: 365)),
                                            onDateChanged: (date) {
                                              setDialogState(() {
                                                selectedDate = date;
                                                selectedTimeSlot = null;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    AppSpacing.vXl,
                                    _section('Available times'),
                                    AppSpacing.vSm,
                                    StreamBuilder<List<String>>(
                                      stream: FirestoreService()
                                          .getAvailableTimesStream("${selectedDate.toLocal()}".split(' ')[0]),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.all(AppSpacing.lg),
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        }
                                        final availableSlots = snapshot.data ?? [];
                                        if (availableSlots.isEmpty) {
                                          selectedTimeSlot = null;
                                          return Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                            decoration: BoxDecoration(
                                              color: AppColors.dangerSurface,
                                              borderRadius: AppRadii.rMd,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'No slots available for this date',
                                                style: AppTypography.labelLarge.copyWith(color: AppColors.danger),
                                              ),
                                            ),
                                          );
                                        }
                                        if (selectedTimeSlot != null && !availableSlots.contains(selectedTimeSlot)) {
                                          selectedTimeSlot = null;
                                        }
                                        return Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.sm,
                                          children: [
                                            for (final slot in allTimeSlots)
                                              if (availableSlots.contains(slot))
                                                FutureBuilder<bool>(
                                                  future: _firestoreService.isSlotTaken(
                                                    'Pet Treasure',
                                                    "${selectedDate.toLocal()}".split(' ')[0],
                                                    slot,
                                                    includePending: true,
                                                  ),
                                                  builder: (ctx, takenSnap) {
                                                    final taken = takenSnap.data ?? false;
                                                    if (taken) {
                                                      return _timeSlot(
                                                        slot,
                                                        available: false,
                                                        selected: false,
                                                        onTap: null,
                                                        labelOverride: 'Booked',
                                                      );
                                                    }
                                                    return _timeSlot(
                                                      slot,
                                                      available: true,
                                                      selected: selectedTimeSlot == slot,
                                                      onTap: () => setDialogState(() => selectedTimeSlot = slot),
                                                    );
                                                  },
                                                ),
                                          ],
                                        );
                                      },
                                    ),
                                    AppSpacing.vXl,
                                    _section('Additional notes'),
                                    AppSpacing.vSm,
                                    AppTextField(
                                      controller: infoController,
                                      hint: 'Describe symptoms or any relevant info (optional)',
                                      prefixIcon: Icons.note_alt_outlined,
                                      maxLines: 3,
                                    ),
                                    AppSpacing.vXxxl,
                                    PrimaryButton(
                                      label: 'Book appointment',
                                      isLoading: isBooking,
                                      onPressed: () async {
                                        if (_user == null) return;
                                        if (!formKey.currentState!.validate()) return;
                                        if (selectedTimeSlot == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please select an available time slot.')),
                                          );
                                          return;
                                        }
                                        final finalVisitType = selectedVisitType == 'Others'
                                            ? otherVisitController.text.trim()
                                            : selectedVisitType;
                                        final dateString = "${selectedDate.toLocal()}".split(' ')[0];

                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
                                            title: Row(
                                              children: [
                                                const Icon(Icons.event_available_rounded, color: AppColors.primary),
                                                AppSpacing.hSm,
                                                Text('Confirm booking?', style: AppTypography.headlineSmall),
                                              ],
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _confirmRow(Icons.pets_rounded, 'Pet', petController.text.trim()),
                                                _confirmRow(Icons.medical_services_outlined, 'Visit', finalVisitType),
                                                _confirmRow(Icons.calendar_today_outlined, 'Date', dateString),
                                                _confirmRow(Icons.access_time_outlined, 'Time', selectedTimeSlot!),
                                                _confirmRow(
                                                  selectedMethod.contains('Online') ? Icons.videocam_outlined : Icons.local_hospital_outlined,
                                                  'Method',
                                                  selectedMethod,
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: Text('Go back', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: Text('Confirm booking', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed != true) return;

                                        setDialogState(() => isBooking = true);
                                        try {
                                          await _firestoreService.addAppointment(
                                            'Pet Treasure',
                                            '',
                                            dateString,
                                            selectedTimeSlot!,
                                            petController.text.trim(),
                                            finalVisitType,
                                            _user.uid,
                                            _user.displayName ?? 'Pet Owner',
                                            _user.email ?? '',
                                            infoController.text.trim(),
                                            selectedMethod,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Appointment request submitted 🐾')),
                                            );
                                          }
                                        } catch (e) {
                                          setDialogState(() => isBooking = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static Widget _section(String label) => Text(label, style: AppTypography.labelLarge);

  static Widget _confirmRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          AppSpacing.hMd,
          Text('$label: ', style: AppTypography.labelMedium),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  static Widget _consultPill(String method, bool selected, VoidCallback onTap) {
    final isOnline = method == 'Online Consultation';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: AppRadii.rMd,
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(
              isOnline ? Icons.videocam_outlined : Icons.local_hospital_outlined,
              color: selected ? AppColors.textInverse : AppColors.textSecondary,
              size: 20,
            ),
            AppSpacing.vXs,
            Text(
              isOnline ? 'Online' : 'In-person',
              style: AppTypography.labelMedium.copyWith(
                color: selected ? AppColors.textInverse : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _timeSlot(String slot, {required bool available, required bool selected, VoidCallback? onTap, String? labelOverride}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: !available
              ? AppColors.surfaceAlt
              : selected
                  ? AppColors.primary
                  : AppColors.primarySurface,
          borderRadius: AppRadii.rSm,
          border: Border.all(
            color: !available
                ? AppColors.divider
                : selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot,
              style: AppTypography.labelMedium.copyWith(
                color: !available
                    ? AppColors.textTertiary
                    : selected
                        ? AppColors.textInverse
                        : AppColors.primaryDark,
                decoration: !available && labelOverride == null ? TextDecoration.lineThrough : null,
              ),
            ),
            if (labelOverride != null)
              Text(
                labelOverride,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.danger,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  final _user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Center(child: Text('Please log in to view appointments.', style: AppTypography.bodyLarge));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getUserAppointmentsStream(_user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: AppTypography.bodyMedium));
                }
                final appointments = snapshot.data ?? [];
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final upcoming = <Map<String, dynamic>>[];
                final past = <Map<String, dynamic>>[];
                for (final apt in appointments) {
                  try {
                    final parts = apt['date'].toString().split('-');
                    if (parts.length == 3) {
                      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                      if (d.isBefore(today)) {
                        past.add(apt);
                      } else {
                        upcoming.add(apt);
                      }
                    } else {
                      upcoming.add(apt);
                    }
                  } catch (_) {
                    upcoming.add(apt);
                  }
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => setState(() {}),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(upcoming, isPast: false),
                      _buildList(past, isPast: true),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppointmentsPage.showBookDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textInverse,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text('Book new', style: AppTypography.labelLarge.copyWith(color: AppColors.textInverse)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.huge, AppSpacing.xxl, AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadii.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppRadii.rFull,
            ),
            child: Text(
              'PET TREASURE CLINIC',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textInverse),
            ),
          ),
          AppSpacing.vSm,
          Text(
            'My visits',
            style: AppTypography.displayMedium.copyWith(color: AppColors.textInverse),
          ),
          AppSpacing.vLg,
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: AppRadii.rMd,
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.rSm,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              labelColor: AppColors.primaryDark,
              unselectedLabelColor: AppColors.textInverse,
              labelStyle: AppTypography.labelLarge,
              unselectedLabelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(height: 36, text: 'Upcoming'),
                Tab(height: 36, text: 'Past'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required bool isPast}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: EmptyState(
            icon: isPast ? Icons.history_toggle_off_outlined : Icons.event_available_outlined,
            title: isPast ? 'No past visits' : 'No upcoming visits',
            message: isPast
                ? 'Your appointment history will appear here.'
                : "Tap 'Book new' to schedule a visit.",
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, 96),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildAppointmentCard(items[i], isPast: isPast),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> apt, {bool isPast = false}) {
    final id = apt['id'] as String;
    final isConfirmed = apt['status'] == 'Confirmed';
    final date = apt['date'] as String? ?? 'N/A';
    final pet = apt['petName'] as String? ?? 'Pet';
    final clinic = apt['clinicName'] as String? ?? 'Clinic';
    final status = apt['status'] as String? ?? 'Pending';
    final type = apt['visitType'] as String? ?? 'Visit';
    final time = apt['time'] as String? ?? '--:--';
    final consultMethod = apt['consultationMethod'] as String? ?? 'In-Person Appointment';

    String dayMonth = '';
    String year = '';
    if (date != 'N/A') {
      final parts = date.split('-');
      if (parts.length == 3) {
        year = parts[0];
        final m = int.tryParse(parts[1]);
        if (m != null && m >= 1 && m <= 12) {
          const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          dayMonth = '${parts[2]} ${months[m - 1]}';
        }
      }
    }

    final statusTone = isPast
        ? BadgeTone.neutral
        : isConfirmed
            ? BadgeTone.success
            : BadgeTone.warning;
    final accent = isPast ? AppColors.textTertiary : AppColors.primary;
    final isOnline = consultMethod.toLowerCase().contains('online');

    final card = AppCard(
      padding: EdgeInsets.zero,
      onTap: () => _showDetailsSheet(apt, isPast: isPast),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppBadge(
                      label: '$dayMonth $year',
                      tone: isPast ? BadgeTone.neutral : BadgeTone.primary,
                      icon: Icons.calendar_today_outlined,
                    ),
                    AppBadge(label: status, tone: statusTone),
                  ],
                ),
                AppSpacing.vMd,
                Row(
                  children: [
                    IconAvatar(
                      icon: Icons.pets_rounded,
                      color: accent,
                      size: 48,
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet,
                            style: AppTypography.titleLarge.copyWith(
                              color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
                              decoration: isPast ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          AppSpacing.vXs,
                          Text(type, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vMd,
                const Divider(height: 1),
                AppSpacing.vMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _infoChip(Icons.access_time_outlined, time),
                    _infoChip(isOnline ? Icons.videocam_outlined : Icons.local_hospital_outlined,
                        isOnline ? 'Online' : 'In-person'),
                    _infoChip(Icons.business_outlined, clinic),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.horizontal,
      background: _dismissBg(alignment: Alignment.centerLeft),
      secondaryBackground: _dismissBg(alignment: Alignment.centerRight),
      confirmDismiss: (_) async {
        bool confirm = false;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
            title: const Text('Delete appointment?'),
            content: Text('Are you sure you want to delete the appointment for $pet?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep')),
              TextButton(
                onPressed: () {
                  confirm = true;
                  Navigator.pop(context);
                },
                child: Text('Delete', style: AppTypography.labelLarge.copyWith(color: AppColors.danger)),
              ),
            ],
          ),
        );
        if (confirm) {
          await _firestoreService.deleteAppointment(id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Appointment deleted for $pet.')),
            );
          }
        }
        return confirm;
      },
      child: card,
    );
  }

  Widget _dismissBg({required Alignment alignment}) => Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: AppRadii.rLg),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      );

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadii.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          AppSpacing.hXs,
          Text(label, style: AppTypography.labelMedium.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  void _showDetailsSheet(Map<String, dynamic> apt, {required bool isPast}) {
    final isConfirmed = apt['status'] == 'Confirmed';
    final pet = apt['petName'] as String? ?? 'Pet';
    final clinic = apt['clinicName'] as String? ?? 'Clinic';
    final status = apt['status'] as String? ?? 'Pending';
    final type = apt['visitType'] as String? ?? 'Visit';
    final date = apt['date'] as String? ?? 'N/A';
    final time = apt['time'] as String? ?? '--:--';
    final consultMethod = apt['consultationMethod'] as String? ?? 'In-Person Appointment';
    final info = apt['additionalInfo'] as String? ?? 'No additional notes.';
    final statusTone = isPast
        ? BadgeTone.neutral
        : isConfirmed
            ? BadgeTone.success
            : BadgeTone.warning;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadii.rFull),
              ),
            ),
            AppSpacing.vXl,
            Row(
              children: [
                const IconAvatar(icon: Icons.pets_rounded, color: AppColors.primary, size: 48),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet, style: AppTypography.headlineMedium),
                      Text(type, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                AppBadge(label: status, tone: statusTone),
              ],
            ),
            AppSpacing.vXl,
            const Divider(),
            AppSpacing.vLg,
            _detailRow('Date', date, Icons.calendar_today_outlined),
            AppSpacing.vMd,
            _detailRow('Time', time, Icons.access_time_outlined),
            AppSpacing.vMd,
            _detailRow('Clinic', clinic, Icons.business_outlined),
            AppSpacing.vMd,
            _detailRow('Method', consultMethod, Icons.videocam_outlined),
            AppSpacing.vXl,
            Text('Notes', style: AppTypography.labelLarge),
            AppSpacing.vSm,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(info, style: AppTypography.bodyMedium),
            ),
            AppSpacing.vXl,
            PrimaryButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
            AppSpacing.vSm,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: AppRadii.rSm),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        AppSpacing.hMd,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall),
            Text(value, style: AppTypography.titleMedium),
          ],
        ),
      ],
    );
  }

}
