import 'package:flutter/material.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/responsive.dart';

class VetAvailabilityPage extends StatefulWidget {
  const VetAvailabilityPage({super.key});

  @override
  State<VetAvailabilityPage> createState() => _VetAvailabilityPageState();
}

class _VetAvailabilityPageState extends State<VetAvailabilityPage> {
  DateTime _selectedDate = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _allTimeSlots = const [
    "12:00 AM", "01:00 AM", "02:00 AM", "03:00 AM",
    "04:00 AM", "05:00 AM", "06:00 AM", "07:00 AM",
    "08:00 AM", "09:00 AM", "10:00 AM", "11:00 AM",
    "12:00 PM", "01:00 PM", "02:00 PM", "03:00 PM",
    "04:00 PM", "05:00 PM", "06:00 PM", "07:00 PM",
    "08:00 PM", "09:00 PM", "10:00 PM", "11:00 PM",
  ];

  void _toggleSlot(String dateString, String timeSlot, bool isAvailable) async {
    await _firestoreService.toggleAvailability(dateString, timeSlot, !isAvailable);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slot $timeSlot marked ${!isAvailable ? 'open' : 'closed'}'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: !isAvailable ? AppColors.success : AppColors.textPrimary,
        ),
      );
    }
  }

  void _bulkSet(String dateString, bool openAll) async {
    final slots = openAll ? List<String>.from(_allTimeSlots) : <String>[];
    await _firestoreService.setAllAvailability(dateString, slots);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(openAll ? 'All slots opened' : 'All slots closed'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: openAll ? AppColors.success : AppColors.textPrimary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = "${_selectedDate.toLocal()}".split(' ')[0];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manage Availability', style: AppTypography.headlineLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.pagePadding(context),
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select date', style: AppTypography.titleMedium),
                  AppSpacing.vSm,
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 30,
                      separatorBuilder: (_, __) => AppSpacing.hSm,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        final isSelected = _selectedDate.year == date.year &&
                            _selectedDate.month == date.month &&
                            _selectedDate.day == date.day;
                        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                        final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 72,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: AppRadii.rLg,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                              boxShadow: isSelected ? AppShadows.colored(AppColors.primary) : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayName, $monthName',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected ? Colors.white.withOpacity(0.85) : AppColors.textTertiary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                AppSpacing.vXs,
                                Text(
                                  '${date.day}',
                                  style: AppTypography.headlineSmall.copyWith(
                                    color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  AppSpacing.vXxxl,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time slots', style: AppTypography.titleMedium),
                          AppSpacing.vXs,
                          Text(
                            'Tap to toggle availability',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _bulkSet(formattedDate, true),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text('Open all'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.success),
                          ),
                          TextButton.icon(
                            onPressed: () => _bulkSet(formattedDate, false),
                            icon: const Icon(Icons.block_rounded, size: 18),
                            label: const Text('Close all'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.vMd,
                  Expanded(
                    child: StreamBuilder<List<String>>(
                      stream: _firestoreService.getAvailableTimesStream(formattedDate),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading slots.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                            ),
                          );
                        }
                        final availableSlots = snapshot.data ?? [];

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.gridColumns(context, mobileCount: 3, desktopCount: 6),
                            childAspectRatio: 2.2,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                          ),
                          itemCount: _allTimeSlots.length,
                          itemBuilder: (context, index) {
                            final slot = _allTimeSlots[index];
                            final isAvailable = availableSlots.contains(slot);

                            return InkWell(
                              onTap: () => _toggleSlot(formattedDate, slot, isAvailable),
                              borderRadius: AppRadii.rMd,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isAvailable ? AppColors.successSurface : AppColors.surface,
                                  borderRadius: AppRadii.rMd,
                                  border: Border.all(
                                    color: isAvailable ? AppColors.success : AppColors.border,
                                    width: isAvailable ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  slot,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: isAvailable ? AppColors.success : AppColors.textTertiary,
                                    fontWeight: isAvailable ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
