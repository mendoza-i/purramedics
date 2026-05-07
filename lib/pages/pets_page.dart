import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:purramedics/pages/addpet_page.dart';
import 'package:purramedics/pages/intro_page.dart';
import 'package:purramedics/services/auth_service.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/pages/user_settings_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  final _firestoreService = FirestoreService();
  final _currentUser = AuthService().currentUser;

  int selectedPet = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Center(
        child: Text('Please log in to view pets.', style: AppTypography.bodyLarge),
      );
    }

    final isVet = AuthService().isVet;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isVet
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
                setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('Add patient'),
            )
          : null,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getUserPetsStream(_currentUser!.email ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading pets: ${snapshot.error}', style: AppTypography.bodyMedium),
              );
            }

            final pets = snapshot.data ?? [];
            if (pets.isEmpty) return _buildEmptyState(isVet);

            if (selectedPet >= pets.length) selectedPet = 0;
            return _buildContent(pets, isVet);
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> pets, bool isVet) {
    final currentPet = pets[selectedPet];
    final name = currentPet['name'] as String? ?? 'Unknown';
    final emoji = currentPet['emoji'] as String? ?? '🐾';
    final breed = currentPet['breed'] as String? ?? 'Unknown breed';
    final weight = currentPet['weight'] as String? ?? '--';
    final gender = currentPet['gender'] as String? ?? 'Unknown';
    final color = currentPet['color'] as String? ?? 'Unknown';
    final isNeutered = currentPet['isNeutered'] as bool? ?? false;

    String calculatedAge = '--';
    final birthdate = currentPet['birthdate']?.toString() ?? '';
    if (birthdate.isNotEmpty && birthdate != 'Unknown') {
      try {
        final dob = DateFormat('MMM d, yyyy').parse(birthdate);
        final now = DateTime.now();
        int years = now.year - dob.year;
        int months = now.month - dob.month;
        if (now.day < dob.day) months--;
        if (months < 0) {
          years--;
          months += 12;
        }
        calculatedAge = years > 0
            ? "$years yr${years > 1 ? 's' : ''}"
            : (months > 0 ? "$months mo${months > 1 ? 's' : ''}" : 'Newborn');
      } catch (_) {
        calculatedAge = birthdate;
      }
    } else if ((currentPet['age']?.toString() ?? '').isNotEmpty) {
      calculatedAge = currentPet['age'].toString();
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isVet) _buildPetRequests(),
            AppBadge(
              label: isVet ? 'MANAGE PATIENTS' : 'HEALTH RECORD',
              tone: isVet ? BadgeTone.info : BadgeTone.primary,
            ),
            AppSpacing.vMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My pets', style: AppTypography.displayLarge),
                if (!isVet)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.rMd,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                      tooltip: 'Account settings',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserSettingsPage()),
                      ),
                    ),
                  ),
              ],
            ),
            AppSpacing.vXl,
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pets.length,
                separatorBuilder: (_, __) => AppSpacing.hMd,
                itemBuilder: (context, index) {
                  final p = pets[index];
                  final isSelected = index == selectedPet;
                  return GestureDetector(
                    onTap: () => setState(() => selectedPet = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: AppRadii.rLg,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                        boxShadow: isSelected
                            ? AppShadows.colored(AppColors.primary, opacity: 0.25)
                            : AppShadows.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p['emoji'] as String? ?? '🐾', style: const TextStyle(fontSize: 24)),
                          AppSpacing.vXs,
                          Text(
                            p['name'] as String? ?? 'Pet',
                            style: AppTypography.titleSmall.copyWith(
                              color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().slideX(begin: 1.0, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
            AppSpacing.vXxxl,
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              shadow: AppShadows.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(emoji, style: const TextStyle(fontSize: 58)),
                        ),
                        AppSpacing.vLg,
                        Text(name, style: AppTypography.displaySmall),
                        AppSpacing.vXs,
                        AppBadge(label: breed, tone: BadgeTone.neutral),
                      ],
                    ),
                  ),
                  AppSpacing.vXxl,
                  const Divider(),
                  AppSpacing.vXl,
                  Row(
                    children: [
                      Expanded(child: _statItem('Age', calculatedAge, Icons.cake_outlined)),
                      _statDivider(),
                      Expanded(child: _statItem('Gender', gender, Icons.wc_outlined)),
                      _statDivider(),
                      Expanded(child: _statItem('Weight', weight, Icons.monitor_weight_outlined)),
                    ],
                  ),
                  AppSpacing.vLg,
                  const Divider(indent: AppSpacing.xl, endIndent: AppSpacing.xl),
                  AppSpacing.vLg,
                  Row(
                    children: [
                      Expanded(child: _statItem('Color', color, Icons.palette_outlined)),
                      _statDivider(),
                      Expanded(child: _statItem('Neutered', isNeutered ? 'Yes' : 'No', Icons.medical_services_outlined)),
                      _statDivider(),
                      Expanded(child: _statItem('Status', 'Healthy', Icons.health_and_safety_outlined)),
                    ],
                  ),
                  AppSpacing.vXl,
                  const Divider(),
                  AppSpacing.vXl,
                  Text('Health overview', style: AppTypography.headlineSmall),
                  AppSpacing.vLg,
                  _buildSessionNotes(currentPet['id'] as String),
                  if (!isVet) ...[
                    AppSpacing.vXl,
                    const Divider(),
                    AppSpacing.vLg,
                    Text('Manage profile', style: AppTypography.headlineSmall),
                    AppSpacing.vXs,
                    Text(
                      'Only verified veterinarians can edit or delete medical records. You can submit a request below.',
                      style: AppTypography.bodySmall,
                    ),
                    AppSpacing.vLg,
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Request change',
                            icon: Icons.edit_note_outlined,
                            size: AppButtonSize.medium,
                            onPressed: () => _showRequestDialog(context, currentPet['id'] as String, name, 'Edit Request'),
                          ),
                        ),
                        AppSpacing.hMd,
                        Expanded(
                          child: SecondaryButton(
                            label: 'Request deletion',
                            icon: Icons.delete_outline_rounded,
                            size: AppButtonSize.medium,
                            onPressed: () => _showRequestDialog(context, currentPet['id'] as String, name, 'Delete Request'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.vXl,
          ],
        ),
      ),
    );
  }

  Widget _statDivider() => Container(height: 40, width: 1, color: AppColors.divider);

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        AppSpacing.vSm,
        Text(
          value,
          style: AppTypography.titleLarge,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        AppSpacing.vXs,
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }

  Widget _buildSessionNotes(String petId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getSessionNotesStream(petId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.infoSurface.withOpacity(0.5),
              borderRadius: AppRadii.rMd,
              border: Border.all(color: AppColors.infoSurface),
            ),
            child: Text('No session notes recorded yet.', style: AppTypography.bodyMedium),
          );
        }

        final notes = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notes.length,
          separatorBuilder: (_, __) => AppSpacing.vMd,
          itemBuilder: (context, index) {
            final n = notes[index];
            String dateStr = 'Unknown date';
            if (n['createdAt'] != null) {
              final dt = (n['createdAt'] as dynamic).toDate() as DateTime;
              dateStr = DateFormat('MMM d, yyyy').format(dt);
            }
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadii.rMd,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr, style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                      Text(
                        n['vetName'] as String? ?? 'Attending vet',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                  AppSpacing.vSm,
                  Text(n['note'] as String? ?? '', style: AppTypography.bodyMedium),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isVet) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBadge(
            label: isVet ? 'MANAGE PATIENTS' : 'HEALTH RECORD',
            tone: isVet ? BadgeTone.info : BadgeTone.primary,
          ),
          AppSpacing.vMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My pets', style: AppTypography.displayLarge),
              if (!isVet)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.rMd,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
                    tooltip: 'Account settings',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserSettingsPage()),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Center(
              child: EmptyState(
                icon: Icons.pets_rounded,
                title: 'No companions yet',
                message: isVet ? 'Add your first patient to get started.' : 'Ask your vet to add your pets!',
                actionLabel: isVet ? 'Add patient' : null,
                onAction: isVet
                    ? () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPetPage()));
                        setState(() {});
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(BuildContext context, String petId, String petName, String requestType) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    Future<void> submit(BuildContext context, StateSetter setDialogState) async {
      if (reasonController.text.trim().isEmpty) return;
      setDialogState(() => isSubmitting = true);
      try {
        await _firestoreService.addPetRequest(
          petId: petId,
          petName: petName,
          ownerId: _currentUser!.uid,
          ownerEmail: _currentUser!.email ?? '',
          requestType: requestType,
          reason: reasonController.text.trim(),
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$requestType submitted to your vet for review.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          setDialogState(() => isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(requestType, style: AppTypography.headlineSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please state the reason for your request regarding $petName:', style: AppTypography.bodyMedium),
                AppSpacing.vLg,
                KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      submit(context, setDialogState);
                    }
                  },
                  child: AppTextField(
                    controller: reasonController,
                    hint: 'Reason...',
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => submit(context, setDialogState),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              PrimaryButton(
                label: 'Submit',
                size: AppButtonSize.medium,
                isExpanded: false,
                isLoading: isSubmitting,
                onPressed: () => submit(context, setDialogState),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPetRequests() {
    if (_currentUser == null) return const SizedBox.shrink();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getPetRequestsForOwnerStream(_currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final requests = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent requests', style: AppTypography.headlineMedium),
            AppSpacing.vMd,
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: requests.length,
                separatorBuilder: (_, __) => AppSpacing.hMd,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final status = req['status'] as String? ?? 'Pending';
                  final tone = status == 'Declined'
                      ? BadgeTone.danger
                      : status == 'Approved'
                          ? BadgeTone.success
                          : BadgeTone.warning;
                  return Container(
                    width: 260,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.rMd,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppBadge(label: status.toUpperCase(), tone: tone),
                            const Spacer(),
                            Text(
                              req['petName'] as String? ?? 'Pet',
                              style: AppTypography.labelLarge,
                            ),
                          ],
                        ),
                        AppSpacing.vSm,
                        Expanded(
                          child: Text(
                            (req['vetReply'] as String?)?.isNotEmpty == true
                                ? 'Reply: ${req['vetReply']}'
                                : (req['requestType'] as String? ?? 'General request'),
                            style: AppTypography.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            AppSpacing.vXl,
          ],
        );
      },
    );
  }
}
