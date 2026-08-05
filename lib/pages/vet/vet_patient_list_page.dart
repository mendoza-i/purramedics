import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/pages/addpet_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/responsive.dart';
import 'package:purramedics/widgets/widgets.dart';
import 'package:purramedics/pages/vet/widgets/vet_background_pattern.dart';

class VetPatientListPage extends StatefulWidget {
  const VetPatientListPage({super.key});

  @override
  State<VetPatientListPage> createState() => _VetPatientListPageState();
}

class _VetPatientListPageState extends State<VetPatientListPage> {
  final _firestoreService = FirestoreService();
  final Map<String, bool> _expandedOwners = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  late final Stream<List<Map<String, dynamic>>> _ownersStream;
  late final Stream<List<Map<String, dynamic>>> _petsStream;

  @override
  void initState() {
    super.initState();
    _ownersStream = _firestoreService.getOwnersStream();
    _petsStream = _firestoreService.getAllPetsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'Unknown') {
      return 'Unknown';
    }
    try {
      DateTime dt;
      try {
        dt = DateFormat('MM/dd/yyyy').parse(dateStr);
      } catch (_) {
        dt = DateTime.parse(dateStr);
      }
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _calculateAge(String? bStr) {
    if (bStr == null || bStr.isEmpty || bStr == 'Unknown') return '';
    try {
      DateTime bDate;
      try {
        bDate = DateFormat('MM/dd/yyyy').parse(bStr);
      } catch (_) {
        bDate = DateTime.parse(bStr);
      }
      final now = DateTime.now();
      int y = now.year - bDate.year;
      int m = now.month - bDate.month;
      if (now.day < bDate.day) m--;
      if (m < 0) {
        y--;
        m += 12;
      }
      if (y > 0) return '$y yr${y == 1 ? '' : 's'}${m > 0 ? ' $m mo' : ''}';
      if (m > 0) return '$m mo';
      return '< 1 mo';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Patient Records', style: AppTypography.headlineLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: VetBackgroundPattern(
        child: SafeArea(
          child: Padding(
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
                    AppTextField(
                      controller: _searchController,
                      hint: 'Search by pet or owner name…',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    AppSpacing.vLg,
                    Expanded(child: _buildBody()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ownersStream,
      builder: (context, ownerSnapshot) {
        if (ownerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final owners = ownerSnapshot.data ?? [];
        final ownerNameMap = {
          for (var o in owners)
            (o['email'] ?? '').toString().toLowerCase():
                (o['name'] ?? 'Unknown').toString(),
        };

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _petsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyState(
                icon: Icons.pets_rounded,
                title: 'No patients yet',
                message: 'Added pets will be grouped by owner here',
              );
            }

            List<Map<String, dynamic>> pets = snapshot.data!;
            final Map<String, List<Map<String, dynamic>>> grouped = {};

            for (var ownerEmail in ownerNameMap.keys) {
              grouped[ownerEmail] = [];
            }

            List<Map<String, dynamic>> filteredPets = pets;
            if (_searchQuery.isNotEmpty) {
              filteredPets = pets.where((pet) {
                final name = (pet['name'] ?? '').toString().toLowerCase();
                final email = (pet['ownerEmail'] ?? '')
                    .toString()
                    .toLowerCase();
                final ownerName = (ownerNameMap[email] ?? '')
                    .toString()
                    .toLowerCase();
                return name.contains(_searchQuery) ||
                    email.contains(_searchQuery) ||
                    ownerName.contains(_searchQuery);
              }).toList();
            }

            for (var pet in filteredPets) {
              final email = (pet['ownerEmail'] ?? '').toString().toLowerCase();
              grouped.putIfAbsent(email, () => []).add(pet);
            }

            List<String> matchingEmails = [];
            if (_searchQuery.isNotEmpty) {
              for (var email in grouped.keys) {
                final ownerName = (ownerNameMap[email] ?? '')
                    .toString()
                    .toLowerCase();
                if (email.contains(_searchQuery) ||
                    ownerName.contains(_searchQuery) ||
                    grouped[email]!.isNotEmpty) {
                  matchingEmails.add(email);
                }
              }
            } else {
              matchingEmails = grouped.keys.toList();
            }

            if (matchingEmails.isEmpty) {
              return const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                message: 'Try a different search term',
              );
            }

            final sortedEmails = matchingEmails..sort();

            return RefreshIndicator(
              onRefresh: () async =>
                  Future.delayed(const Duration(milliseconds: 600)),
              color: AppColors.primary,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: sortedEmails.length,
                separatorBuilder: (_, __) => AppSpacing.vMd,
                itemBuilder: (context, i) {
                  final email = sortedEmails[i];
                  final ownerPets = grouped[email]!;
                  final ownerName =
                      ownerNameMap[email] ??
                      (email.isNotEmpty ? email : 'Unknown owner');
                  final expanded = _expandedOwners[email] ?? false;
                  return _buildOwnerGroup(
                    email,
                    ownerName,
                    ownerPets,
                    expanded,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOwnerGroup(
    String email,
    String ownerName,
    List<Map<String, dynamic>> pets,
    bool expanded,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expandedOwners[email] = !expanded),
            borderRadius: AppRadii.rLg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ownerName, style: AppTypography.titleMedium),
                        if (email.isNotEmpty) ...[
                          AppSpacing.vXs,
                          Text(
                            email,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.hSm,
                  AppBadge(
                    label:
                        '${pets.length} ${pets.length == 1 ? 'pet' : 'pets'}',
                    tone: BadgeTone.info,
                  ),
                  AppSpacing.hSm,
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(height: 1, color: AppColors.divider),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = Responsive.isWide(context) ? 2 : 1;
                            final width =
                                (constraints.maxWidth - (AppSpacing.md * (cols - 1))) /
                                    cols -
                                0.1;
                            return Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              children: pets
                                  .map(
                                    (p) =>
                                        SizedBox(width: width, child: _buildPetCard(p)),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final name = pet['name'] ?? 'Unknown';
    final emoji = pet['emoji'] ?? '🐾';
    final breed = pet['breed'] ?? 'Unknown';
    final rawBirthdate = pet['birthdate']?.toString();
    final birthdate = _formatDateString(rawBirthdate);
    final ageStr = _calculateAge(rawBirthdate);
    final gender = pet['gender'] ?? '?';
    final weight = pet['weight']?.toString() ?? '-- kg';
    final ownerEmail = pet['ownerEmail'] ?? 'Unknown';
    
    // Fallback if weight doesn't have units
    final weightDisplay = weight.contains(RegExp(r'[a-zA-Z]')) || weight == '-- kg' ? weight : '$weight kg';
    
    // Mock ID & Alerts for EHR feel
    final patientId = '#PT-${pet['id'] != null ? pet['id'].hashCode.abs().toString().substring(0, 4) : '0000'}';
    final hasAllergies = pet['id'] != null && pet['id'].hashCode % 3 == 0;
    final needsVaccine = pet['id'] != null && pet['id'].hashCode % 5 == 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Emoji, Name, Breed, ID
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppBadge(
                            label: 'Active',
                            tone: BadgeTone.success,
                          ),
                        ],
                      ),
                      AppSpacing.vXs,
                      Text(
                        '$breed • $patientId',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasAllergies || needsVaccine) ...[
                        AppSpacing.vSm,
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (hasAllergies)
                              AppBadge(label: 'Allergies', tone: BadgeTone.danger),
                            if (needsVaccine)
                              AppBadge(label: 'Vax Due', tone: BadgeTone.warning),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.vMd,
            const Divider(height: 1, color: AppColors.divider),
            AppSpacing.vMd,
            
            // Wrap everything that needs the session stream
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getSessionNotesStream(pet['id']),
              builder: (context, snapshot) {
                String? latestNoteText;
                String lastVisit = 'No visits yet';
                
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final latestNote = snapshot.data!.first;
                  latestNoteText = latestNote['note']?.toString();
                  if (latestNote['createdAt'] != null) {
                    final date = (latestNote['createdAt'] as Timestamp).toDate();
                    lastVisit = DateFormat('MMM d, yyyy').format(date);
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clinical Grid
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: AppRadii.rMd,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _clinicalStat(Icons.monitor_weight_outlined, 'Weight', weightDisplay),
                              ),
                              Expanded(
                                child: _clinicalStat(
                                  gender == 'Female' ? Icons.female_rounded : Icons.male_rounded, 
                                  'Gender', 
                                  gender
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vMd,
                          Row(
                            children: [
                              Expanded(
                                child: _clinicalStat(Icons.cake_outlined, 'Age', ageStr.isNotEmpty ? ageStr : birthdate),
                              ),
                              Expanded(
                                child: _clinicalStat(Icons.event_available_outlined, 'Last Visit', lastVisit),
                              ),
                            ],
                          ),
                          AppSpacing.vMd,
                          Row(
                            children: [
                              Expanded(
                                child: _clinicalStat(Icons.person_outline_rounded, 'Owner', ownerEmail),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    AppSpacing.vLg,
                    
                    // Medical Notes Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFDF7), // Subtle paper color
                        borderRadius: AppRadii.rMd,
                        border: Border.all(color: const Color(0xFFE5D5AE)), // Subtle paper border
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.medical_information_outlined, size: 14, color: Color(0xFFB59345)),
                              AppSpacing.hXs,
                              Text(
                                'LATEST MEDICAL NOTE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: const Color(0xFFB59345),
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.vXs,
                          Text(
                            (latestNoteText != null && latestNoteText.isNotEmpty) 
                                ? latestNoteText 
                                : 'No recent medical notes. Click "Add Record" to add.',
                            textAlign: TextAlign.left,
                            style: AppTypography.bodySmall.copyWith(
                              color: (latestNoteText != null && latestNoteText.isNotEmpty) ? AppColors.textPrimary : AppColors.textTertiary,
                              fontStyle: (latestNoteText != null && latestNoteText.isNotEmpty) ? FontStyle.normal : FontStyle.italic,
                              height: 1.5,
                            ),
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            AppSpacing.vLg,
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddMedicalHistoryDialog(context, pet),
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('Add Record'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                  ),
                ),
                AppSpacing.hSm,
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showViewPetDialog(context, pet),
                    icon: const Icon(Icons.folder_shared_outlined, size: 18),
                    label: const Text('View Full'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _clinicalStat(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        AppSpacing.hSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadii.rSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          AppSpacing.hSm,
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showViewPetDialog(BuildContext context, Map<String, dynamic> pet) {
    Widget statChip(String label, String value) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: AppRadii.rMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 0.6,
            ),
          ),
          AppSpacing.vXs,
          Text(
            value.isEmpty || value == 'Unknown' ? '—' : value,
            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    Widget infoTile(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconAvatar(icon: icon, color: AppColors.primary, size: 32),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value.isEmpty || value == 'Unknown' || value == 'null'
                      ? '—'
                      : value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780, maxHeight: 640),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadii.rXl,
              boxShadow: AppShadows.lg,
            ),
            child: ClipRRect(
              borderRadius: AppRadii.rXl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 230,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: AppRadii.rLg,
                          ),
                          child: Center(
                            child: Text(
                              pet['emoji'] ?? '🐾',
                              style: const TextStyle(fontSize: 38),
                            ),
                          ),
                        ),
                        AppSpacing.vMd,
                        Text(
                          pet['name'] ?? 'Unknown',
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        AppSpacing.vXs,
                        Text(
                          pet['breed'] ?? 'Unknown breed',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        AppSpacing.vXxl,
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            statChip('Gender', pet['gender'] ?? '—'),
                            statChip('Weight', pet['weight'] ?? '—'),
                            statChip(
                              'Neutered',
                              (pet['isNeutered'] ?? false) ? 'Yes' : 'No',
                            ),
                            statChip('Color', pet['color'] ?? '—'),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xxl,
                            AppSpacing.xl,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border(
                              bottom: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pet Record',
                                      style: AppTypography.titleLarge,
                                    ),
                                    AppSpacing.vXs,
                                    Text(
                                      'Owner: ${pet['ownerEmail'] ?? 'Unknown'}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xxl,
                              AppSpacing.lg,
                              AppSpacing.xxl,
                              AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DETAILS',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                AppSpacing.vSm,
                                infoTile(
                                  Icons.pets_rounded,
                                  'Species',
                                  pet['species'] ?? 'Unknown',
                                ),
                                Builder(
                                  builder: (_) {
                                    final rawBirthdate = pet['birthdate']
                                        ?.toString();
                                    final formattedDate = _formatDateString(
                                      rawBirthdate,
                                    );
                                    final a = _calculateAge(rawBirthdate);
                                    return infoTile(
                                      Icons.cake_outlined,
                                      'Birthday',
                                      a.isNotEmpty
                                          ? '$formattedDate ($a)'
                                          : formattedDate,
                                    );
                                  },
                                ),
                                infoTile(
                                  Icons.monitor_weight_outlined,
                                  'Weight',
                                  pet['weight'] ?? 'Unknown',
                                ),
                                infoTile(
                                  Icons.palette_outlined,
                                  'Coat Color',
                                  pet['color'] ?? 'Unknown',
                                ),
                                AppSpacing.vLg,
                                const Divider(color: AppColors.divider),
                                AppSpacing.vMd,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'MEDICAL HISTORY',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    PrimaryButton(
                                      label: 'Add Clinical Note',
                                      icon: Icons.note_add_rounded,
                                      size: AppButtonSize.small,
                                      isExpanded: false,
                                      onPressed: () => _showAddMedicalHistoryDialog(context, pet),
                                    ),
                                  ],
                                ),
                                AppSpacing.vSm,
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: _firestoreService
                                      .getSessionNotesStream(pet['id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(AppSpacing.lg),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(
                                          AppSpacing.lg,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceAlt,
                                          borderRadius: AppRadii.rMd,
                                        ),
                                        child: Text(
                                          'No session notes yet.',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textTertiary,
                                              ),
                                        ),
                                      );
                                    }
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length,
                                      separatorBuilder: (_, __) =>
                                          AppSpacing.vSm,
                                      itemBuilder: (_, i) {
                                        final n = snapshot.data![i];
                                        String dateStr = '—';
                                        try {
                                          dateStr =
                                              DateFormat(
                                                'MMM d, yyyy · h:mm a',
                                              ).format(
                                                (n['createdAt'] as dynamic)
                                                    .toDate(),
                                              );
                                        } catch (_) {}
                                        return Container(
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: AppRadii.rMd,
                                            border: Border.all(color: AppColors.border),
                                            boxShadow: AppShadows.sm,
                                          ),
                                          child: IntrinsicHeight(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Container(
                                                  width: 4,
                                                  color: AppColors.primary,
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    dateStr,
                                                                    style: AppTypography.labelLarge.copyWith(
                                                                      color: AppColors.textPrimary,
                                                                      fontWeight: FontWeight.w700,
                                                                    ),
                                                                  ),
                                                                  AppSpacing.vXs,
                                                                  Text(
                                                                    'Clinical Record',
                                                                    style: AppTypography.labelSmall.copyWith(
                                                                      color: AppColors.primary,
                                                                      letterSpacing: 0.5,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                              decoration: BoxDecoration(
                                                                color: AppColors.surfaceAlt,
                                                                borderRadius: AppRadii.rMd,
                                                                border: Border.all(color: AppColors.divider),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                                                                  AppSpacing.hSm,
                                                                  Text(
                                                                    'Dr. ${n['vetName'] ?? 'Vet'}',
                                                                    style: AppTypography.labelSmall.copyWith(
                                                                      color: AppColors.textSecondary,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        AppSpacing.vLg,
                                                        Container(
                                                          width: double.infinity,
                                                          padding: const EdgeInsets.all(AppSpacing.md),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.background,
                                                            borderRadius: AppRadii.rSm,
                                                          ),
                                                          child: Text(
                                                            n['note'] ?? '',
                                                            style: AppTypography.bodyMedium.copyWith(
                                                              height: 1.6,
                                                              color: AppColors.textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _showAddMedicalHistoryDialog(
    BuildContext context,
    Map<String, dynamic> pet,
  ) {
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setSB) => AlertDialog(
          title: Text('Add Medical History', style: AppTypography.titleLarge),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final dt = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (dt != null) setSB(() => selectedDate = dt);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadii.rMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(selectedDate),
                          style: AppTypography.bodyMedium,
                        ),
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.vMd,
                KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _saveHistory(ctx, pet, noteCtrl, selectedDate);
                    }
                  },
                  child: AppTextField(
                    controller: noteCtrl,
                    hint: 'Conclusions, prescriptions, observations…',
                    maxLines: 12,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) =>
                        _saveHistory(ctx, pet, noteCtrl, selectedDate),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cancel',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            PrimaryButton(
              label: 'Save',
              size: AppButtonSize.small,
              isLoading: isSaving,
              onPressed: isSaving
                  ? null
                  : () {
                      setSB(() => isSaving = true);
                      _saveHistory(dialogCtx, pet, noteCtrl, selectedDate);
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _saveHistory(
    BuildContext dialogCtx,
    Map<String, dynamic> pet,
    TextEditingController notesCtrl,
    DateTime date,
  ) async {
    if (notesCtrl.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    String vetName = user?.displayName ?? '';
    if (vetName.trim().isEmpty) {
      vetName = 'Attending Veterinarian';
    } else if (!vetName.toLowerCase().startsWith('dr.')) {
      vetName = 'Dr. $vetName';
    }

    await _firestoreService.addSessionNote(
      petId: pet['id'],
      vetName: vetName,
      note: notesCtrl.text.trim(),
      customDate: date,
    );

    if (mounted && Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
  }
  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: AppTypography.labelSmall.copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w700,
    ),
  );

  void _showOwnerSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select pet owner', style: AppTypography.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getOwnersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  'No registered users found.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              }
              final owners = snapshot.data!;
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: owners.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, i) {
                    final owner = owners[i];
                    final name = (owner['name'] ?? 'Unknown').toString();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(name, style: AppTypography.titleSmall),
                      subtitle: Text(
                        owner['email'] ?? '',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddPetPage(prefilledOwnerEmail: owner['email']),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
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
        ],
      ),
    );
  }
}