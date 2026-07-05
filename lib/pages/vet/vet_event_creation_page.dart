import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purramedics/models/event.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class VetEventCreationPage extends StatefulWidget {
  final Map<String, dynamic>? eventMap;
  final String? eventId;

  const VetEventCreationPage({super.key, this.eventMap, this.eventId});

  @override
  State<VetEventCreationPage> createState() => _VetEventCreationPageState();
}

class _VetEventCreationPageState extends State<VetEventCreationPage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedColorValue = AppColors.primary.value;
  String _selectedIconName = 'vaccine';
  bool _isSaving = false;

  final List<Color> _availableColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.info,
    AppColors.warning,
    AppColors.danger,
    AppColors.success,
  ];

  final List<Map<String, dynamic>> _iconOptions = const [
    {'name': 'vaccine', 'icon': Icons.vaccines_rounded, 'desc': 'Free vaccination drives'},
    {'name': 'adoption', 'icon': Icons.pets_rounded, 'desc': 'Pet adoption events'},
    {'name': 'checkup', 'icon': Icons.health_and_safety_rounded, 'desc': 'General health checkups'},
    {'name': 'community', 'icon': Icons.people_rounded, 'desc': 'Community meetups & education'},
    {'name': 'emergency', 'icon': Icons.warning_amber_rounded, 'desc': 'Emergency & rescue ops'},
  ];

  DateTime? _startDateTime;
  DateTime? _endDateTime;

  String _selectedLocationPreset = 'Main Clinic';
  final List<String> _locationPresets = const [
    'Main Clinic',
    'Barangay Hall',
    'City Plaza',
    'Community Center',
    'Custom Location',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventMap != null) {
      final data = widget.eventMap!;
      _titleController.text = data['title'] ?? '';

      final loc = data['location'] ?? '';
      if (_locationPresets.contains(loc)) {
        _selectedLocationPreset = loc;
      } else {
        _selectedLocationPreset = 'Custom Location';
        _locationController.text = loc;
      }

      final dateFull = data['date'] ?? '';
      if (dateFull.contains(' to ')) {
        final parts = dateFull.split(' to ');
        _startDateController.text = parts[0];
        _endDateController.text = parts[1];
      } else if (dateFull.contains(' at ')) {
        _startDateController.text = dateFull;
      }

      _descriptionController.text = data['description'] ?? '';
      _selectedColorValue = data['colorValue'] ?? AppColors.primary.value;
      _selectedIconName = data['iconName'] ?? 'vaccine';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      if (time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Can't select a past time for today"),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }
    }

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (!isStart && _startDateTime != null) {
      if (selectedDateTime.isBefore(_startDateTime!) || selectedDateTime.isAtSameMomentAs(_startDateTime!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("End date must be strictly after the start date"),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }
    }

    final formattedDate =
        "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}";
    final formattedTime = time.format(context);
    final combined = '$formattedDate at $formattedTime';

    setState(() {
      if (isStart) {
        _startDateController.text = combined;
        _startDateTime = selectedDateTime;
        // Reset end date if invalid
        if (_endDateTime != null && (_endDateTime!.isBefore(_startDateTime!) || _endDateTime!.isAtSameMomentAs(_startDateTime!))) {
          _endDateTime = null;
          _endDateController.text = '';
        }
      } else {
        _endDateController.text = combined;
        _endDateTime = selectedDateTime;
      }
    });
  }

  void _saveEvent() async {
    if (_isSaving) return;

    final finalLocation = _selectedLocationPreset == 'Custom Location'
        ? _locationController.text.trim()
        : _selectedLocationPreset;

    if (_titleController.text.isEmpty ||
        finalLocation.isEmpty ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please fill title, location, and start/end dates',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final firestoreService = FirestoreService();
    final fullDateString =
        '${_startDateController.text.trim()} to ${_endDateController.text.trim()}';

    if (widget.eventId != null) {
      await firestoreService.updateEvent(
        widget.eventId!,
        _titleController.text.trim(),
        finalLocation,
        fullDateString,
        _selectedColorValue,
        _descriptionController.text.trim(),
        _selectedIconName,
      );
    } else {
      final newEvent = Event(
        title: _titleController.text.trim(),
        location: finalLocation,
        date: fullDateString,
        colorValue: _selectedColorValue,
        description: _descriptionController.text.trim(),
        iconName: _selectedIconName,
      );
      await firestoreService.addEvent(newEvent);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventId != null ? 'Event updated' : 'Event published',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Event' : 'Create Event',
          style: AppTypography.headlineLarge,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(
                          'Event title',
                          'Shown publicly on the community calendar',
                        ),
                        AppSpacing.vSm,
                        AppTextField(
                          controller: _titleController,
                          hint: 'e.g. Free Vaccination Drive',
                          prefixIcon: Icons.event_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSpacing.vLg,
                        _label('Location', 'Where the event will be held'),
                        AppSpacing.vSm,
                        _buildLocationDropdown(),
                        if (_selectedLocationPreset == 'Custom Location') ...[
                          AppSpacing.vSm,
                          AppTextField(
                            controller: _locationController,
                            hint: 'Enter custom address',
                            prefixIcon: Icons.location_on_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                        AppSpacing.vLg,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Start', 'When it begins'),
                                  AppSpacing.vSm,
                                  _datePickerField(
                                    _startDateController,
                                    'Select start',
                                    true,
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.hMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('End', 'When it concludes'),
                                  AppSpacing.vSm,
                                    _startDateTime == null
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              AppTextField(
                                                controller: _endDateController,
                                                hint: 'Select end',
                                                readOnly: true,
                                                prefixIcon: Icons.calendar_today_rounded,
                                              ),
                                              AppSpacing.vXs,
                                              Text(
                                                'Select start time first',
                                                style: AppTypography.labelSmall.copyWith(color: AppColors.danger),
                                              ),
                                            ],
                                          )
                                        : _datePickerField(
                                            _endDateController,
                                            'Select end',
                                            false,
                                          ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vLg,
                        _label('Theme icon', 'Represents this event type'),
                        AppSpacing.vSm,
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _iconOptions.length,
                            separatorBuilder: (_, __) => AppSpacing.hSm,
                            itemBuilder: (context, i) {
                              final option = _iconOptions[i];
                              final selected = _selectedIconName == option['name'];
                              return Tooltip(
                                message: option['desc'],
                                preferBelow: false,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedIconName = option['name'],
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 68,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.surfaceAlt,
                                      borderRadius: AppRadii.rLg,
                                    ),
                                    child: Icon(
                                      option['icon'],
                                      size: 30,
                                      color: selected
                                          ? AppColors.textInverse
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        AppSpacing.vLg,
                        _label('Card color', 'Used for the event card accent'),
                        AppSpacing.vSm,
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: _availableColors.map((color) {
                            final selected = _selectedColorValue == color.value;
                            return GestureDetector(
                              onTap: () => setState(
                                () => _selectedColorValue = color.value,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.textPrimary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        AppSpacing.vLg,
                        _label(
                          'About this event',
                          'Short description; URLs auto-link',
                        ),
                        AppSpacing.vSm,
                        KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              _saveEvent();
                            }
                          },
                          child: AppTextField(
                            controller: _descriptionController,
                            hint: 'Enter detailed description…',
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _saveEvent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vLg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      AppSpacing.hMd,
                      PrimaryButton(
                        label: isEditing ? 'Save Event' : 'Publish Event',
                        backgroundColor: AppColors.success,
                        icon: isEditing
                            ? Icons.check_rounded
                            : Icons.cloud_upload_outlined,
                        onPressed: _saveEvent,
                        isLoading: _isSaving,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, String subtext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: AppTypography.titleSmall),
        AppSpacing.vXs,
        Text(
          subtext,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadii.rMd,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLocationPreset,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.textSecondary,
          ),
          style: AppTypography.bodyMedium,
          items: _locationPresets
              .map(
                (loc) => DropdownMenuItem(
                  value: loc,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      AppSpacing.hSm,
                      Text(loc, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedLocationPreset = val;
              if (val != 'Custom Location') _locationController.text = val;
            });
          },
        ),
      ),
    );
  }

  Widget _datePickerField(
    TextEditingController controller,
    String hint,
    bool isStart,
  ) {
    return GestureDetector(
      onTap: () => _pickDateTime(isStart),
      child: AbsorbPointer(
        child: AppTextField(
          controller: controller,
          hint: hint,
          prefixIcon: Icons.calendar_today_rounded,
        ),
      ),
    );
  }
}
