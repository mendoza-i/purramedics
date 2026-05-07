/// ============================================================================
/// ADD PET PAGE (FIRESTORE EDITION)
/// Registers a new pet and (vet-only) links it to an owner account.
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/services/auth_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';
import 'package:intl/intl.dart';

class AddPetPage extends StatefulWidget {
  final String? prefilledOwnerEmail;
  const AddPetPage({super.key, this.prefilledOwnerEmail});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final nameCtrl = TextEditingController();
  final breedCtrl = TextEditingController();
  final birthdateCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final vetNameCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  late TextEditingController ownerEmailCtrl;

  String selectedSpecies = 'Dog';
  String selectedGender = 'Male';
  bool isNeutered = false;
  bool _isLoading = false;
  String selectedEmoji = '🐶';

  @override
  void initState() {
    super.initState();
    ownerEmailCtrl = TextEditingController(text: widget.prefilledOwnerEmail ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    breedCtrl.dispose();
    birthdateCtrl.dispose();
    weightCtrl.dispose();
    vetNameCtrl.dispose();
    colorCtrl.dispose();
    ownerEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePet() async {
    if (nameCtrl.text.trim().isEmpty) {
      _showSnack('Pet name is required', AppColors.danger);
      return;
    }
    if (AuthService().isVet && ownerEmailCtrl.text.trim().isEmpty) {
      _showSnack('Owner email is required', AppColors.danger);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirestoreService();
      final targetOwnerEmail = AuthService().isVet
          ? ownerEmailCtrl.text.trim()
          : AuthService().currentUser?.email ?? '';

      await firestore.addPet(
        name: nameCtrl.text.trim(),
        species: selectedSpecies,
        breed: breedCtrl.text.isEmpty ? 'Unknown' : breedCtrl.text.trim(),
        birthdate: birthdateCtrl.text.isEmpty ? 'Unknown' : birthdateCtrl.text.trim(),
        weight: weightCtrl.text.isEmpty ? '--' : weightCtrl.text.trim(),
        gender: selectedGender,
        color: colorCtrl.text.isEmpty ? 'Unknown' : colorCtrl.text.trim(),
        isNeutered: isNeutered,
        ownerEmail: targetOwnerEmail,
        emoji: selectedEmoji,
        vetName: vetNameCtrl.text.trim(),
      );

      if (mounted) {
        _showSnack('Pet registered successfully', AppColors.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentName = nameCtrl.text.trim().isEmpty ? 'New patient' : nameCtrl.text.trim();
    final currentBreed = breedCtrl.text.trim().isEmpty ? selectedSpecies : breedCtrl.text.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.rXl,
                boxShadow: AppShadows.md,
              ),
              child: ClipRRect(
                borderRadius: AppRadii.rXl,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;
                    return isMobile
                        ? Column(children: [_buildSidebar(currentName, currentBreed, true), _buildForm()])
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSidebar(currentName, currentBreed, false),
                                Expanded(child: _buildForm()),
                              ],
                            ),
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(String name, String breed, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: AppRadii.rLg,
            ),
            child: Text(selectedEmoji, style: const TextStyle(fontSize: 44)),
          ),
          AppSpacing.vMd,
          Text(
            name,
            style: AppTypography.titleLarge.copyWith(color: AppColors.textInverse),
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
          AppSpacing.vXs,
          Text(
            breed,
            style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.7)),
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isMobile) ...[
            const Spacer(),
            Divider(color: Colors.white.withOpacity(0.15)),
            AppSpacing.vSm,
            Text(
              'Fill out the clinical record to register this new patient. Changes sync to the cloud.',
              style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.55), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm() {
    final isVet = AuthService().isVet;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Register Patient', style: AppTypography.displaySmall),
          AppSpacing.vXs,
          Text(
            isVet ? 'Link this pet to an existing owner account' : 'Add a new pet to your profile',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.vXl,

          if (isVet) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildOwnerPicker()),
                AppSpacing.hMd,
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: vetNameCtrl,
                    label: 'Clinic assignment',
                    prefixIcon: Icons.local_hospital_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            AppSpacing.vLg,
            const Divider(color: AppColors.divider),
            AppSpacing.vLg,
          ],

          Text('Species', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              {'label': 'Dog', 'emoji': '🐶'},
              {'label': 'Cat', 'emoji': '🐱'},
              {'label': 'Other', 'emoji': '🐾'},
            ].map((s) {
              final label = s['label']!;
              final emoji = s['emoji']!;
              final active = selectedSpecies == label;
              return GestureDetector(
                onTap: () => setState(() {
                  selectedSpecies = label;
                  selectedEmoji = emoji;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surfaceAlt,
                    borderRadius: AppRadii.rFull,
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      AppSpacing.hXs,
                      Text(
                        label,
                        style: AppTypography.labelMedium.copyWith(
                          color: active ? AppColors.textInverse : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          AppSpacing.vLg,

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppTextField(
                  controller: nameCtrl,
                  label: 'Pet name',
                  hint: 'Whiskers',
                  prefixIcon: Icons.badge_outlined,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: breedCtrl,
                  label: 'Breed',
                  hint: 'Mixed',
                  prefixIcon: Icons.category_outlined,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          AppSpacing.vLg,

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gender', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                    AppSpacing.vSm,
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: ['Male', 'Female'].map((g) {
                        final active = selectedGender == g;
                        return GestureDetector(
                          onTap: () => setState(() => selectedGender = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.surfaceAlt,
                              borderRadius: AppRadii.rFull,
                              border: Border.all(color: active ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(
                              g,
                              style: AppTypography.labelMedium.copyWith(
                                color: active ? AppColors.textInverse : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: GestureDetector(
                  onTap: _pickBirthdate,
                  child: AbsorbPointer(
                    child: AppTextField(
                      controller: birthdateCtrl,
                      label: 'Birthdate (optional)',
                      prefixIcon: Icons.calendar_today_outlined,
                      hint: 'Tap to select',
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vLg,

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: colorCtrl,
                  label: 'Coat color',
                  prefixIcon: Icons.palette_outlined,
                  textInputAction: TextInputAction.next,
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                child: AppTextField(
                  controller: weightCtrl,
                  label: 'Weight (kg)',
                  prefixIcon: Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _savePet(),
                ),
              ),
            ],
          ),
          AppSpacing.vLg,

          Row(
            children: [
              Text('Neutered?', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Switch(
                value: isNeutered,
                onChanged: (v) => setState(() => isNeutered = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          AppSpacing.vXxl,

          PrimaryButton(
            label: 'Save patient record',
            onPressed: _savePet,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => birthdateCtrl.text = DateFormat('MMM d, yyyy').format(picked));
    }
  }

  Widget _buildOwnerPicker() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getOwnersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80);
        }
        final owners = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
            AppSpacing.vSm,
            Autocomplete<Map<String, dynamic>>(
              initialValue: TextEditingValue(text: ownerEmailCtrl.text),
              displayStringForOption: (o) => "${o['name'] ?? 'Unknown'} (${o['email'] ?? ''})",
              optionsBuilder: (tev) {
                if (tev.text.isEmpty) return owners;
                final q = tev.text.toLowerCase();
                return owners.where((o) {
                  final e = (o['email'] ?? '').toString().toLowerCase();
                  final n = (o['name'] ?? '').toString().toLowerCase();
                  return e.contains(q) || n.contains(q);
                });
              },
              onSelected: (selection) {
                ownerEmailCtrl.text = selection['email'] ?? '';
                FocusScope.of(context).unfocus();
              },
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                if (ownerEmailCtrl.text.isNotEmpty && controller.text.isEmpty) {
                  try {
                    final m = owners.firstWhere((o) => o['email'] == ownerEmailCtrl.text);
                    controller.text = "${m['name']} (${m['email']})";
                  } catch (_) {
                    controller.text = ownerEmailCtrl.text;
                  }
                }
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    hintText: 'Search / select owner',
                    prefixIcon: const Icon(Icons.person_search_rounded, color: AppColors.textTertiary, size: 20),
                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Material(
                      elevation: 8,
                      color: AppColors.surface,
                      borderRadius: AppRadii.rLg,
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250, maxWidth: 360),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.primarySurface,
                                      child: Text(
                                        (option['name'] ?? '?').toString()[0].toUpperCase(),
                                        style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                                      ),
                                    ),
                                    AppSpacing.hMd,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option['name'] ?? 'Unknown',
                                            style: AppTypography.titleSmall,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            option['email'] ?? '',
                                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
