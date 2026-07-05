import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'Unknown')
      return 'Unknown';
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
      stream: _firestoreService.getOwnersStream(),
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
          stream: _firestoreService.getAllPetsStream(),
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
          if (expanded) ...[
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
    final birthDisplay = ageStr.isNotEmpty ? '$birthdate ($ageStr)' : birthdate;
    final gender = pet['gender'] ?? '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadii.rLg,
          onTap: () => _showViewPetDialog(context, pet),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppSpacing.vXs,
                          Text(
                            breed,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textTertiary,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') _showEditPetDialog(context, pet);
                        if (value == 'delete')
                          _showDeleteConfirmation(context, pet['id'], name);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              AppSpacing.hSm,
                              Text('Edit', style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              AppSpacing.hSm,
                              Text(
                                'Delete',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AppSpacing.vMd,
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _chip(Icons.pets_rounded, breed),
                    _chip(
                      gender == 'Female'
                          ? Icons.female_rounded
                          : Icons.male_rounded,
                      gender,
                    ),
                    _chip(Icons.cake_outlined, birthDisplay),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadii.rSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          AppSpacing.hXs,
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
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
            style: AppTypography.labelLarge.copyWith(color: Colors.white),
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
                  style: AppTypography.bodyMedium.copyWith(
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
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            size: AppButtonSize.small,
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            isExpanded: true,
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              _showEditPetDialog(context, pet);
                            },
                          ),
                        ),
                        AppSpacing.vSm,
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _showDeleteConfirmation(
                              context,
                              pet['id'],
                              pet['name'] ?? 'this pet',
                            );
                          },
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white.withOpacity(0.85),
                            size: 16,
                          ),
                          label: Text(
                            'Delete',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
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
                    maxLines: 4,
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

  void _showDeleteConfirmation(
    BuildContext context,
    String petId,
    String petName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete pet?', style: AppTypography.titleLarge),
        content: Text(
          "Permanently delete $petName's records? This cannot be undone.",
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
              await _firestoreService.deletePet(petId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$petName deleted'),
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

  void _showEditPetDialog(BuildContext context, Map<String, dynamic> pet) {
    final nameCtrl = TextEditingController(text: pet['name']);
    final weightCtrl = TextEditingController(
      text: (pet['weight'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final colorCtrl = TextEditingController(text: pet['color'] ?? '');
    final notesCtrl = TextEditingController(text: pet['notes'] ?? '');

    bool isNeutered = pet['isNeutered'] ?? false;
    String selectedEmoji = pet['emoji'] ?? '🐶';
    String selectedSpecies = pet['species'] ?? 'Dog';
    String selectedBreed = pet['breed'] ?? '';
    String selectedGender = pet['gender'] ?? 'Male';
    String weightUnit =
        (pet['weight'] ?? '').toString().toLowerCase().contains('lb')
        ? 'lbs'
        : 'kg';
    DateTime? selectedBirthdate;

    try {
      final stored = pet['birthdate']?.toString() ?? '';
      if (stored.isNotEmpty) {
        selectedBirthdate =
            DateTime.tryParse(stored) ?? DateFormat('MM/dd/yyyy').parse(stored);
      }
    } catch (_) {}

    final Map<String, List<String>> breedsBySpecies = {
      'Dog': [
        'Aspin (Asong Pinoy)',
        'Shih Tzu',
        'Beagle',
        'Golden Retriever',
        'Labrador',
        'Poodle',
        'Chihuahua',
        'German Shepherd',
        'Dachshund',
        'Siberian Husky',
        'Other',
      ],
      'Cat': [
        'Puspin (Pusang Pinoy)',
        'Persian',
        'Siamese',
        'Maine Coon',
        'Ragdoll',
        'British Shorthair',
        'Scottish Fold',
        'Domestic Shorthair',
        'Other',
      ],
      'Other': ['Guinea Pig', 'Rabbit', 'Turtle', 'Hamster', 'Bird', 'Other'],
    };

    final speciesOptions = [
      {'label': 'Dog', 'emoji': '🐶'},
      {'label': 'Cat', 'emoji': '🐱'},
      {'label': 'Other', 'emoji': '🐾'},
    ];
    final speciesEmoji = {'Dog': '🐶', 'Cat': '🐱', 'Other': '🐾'};

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: StatefulBuilder(
          builder: (context, setSB) {
            final breeds = breedsBySpecies[selectedSpecies] ?? ['Other'];
            if (!breeds.contains(selectedBreed)) selectedBreed = breeds.first;

            Widget chips(
              List<String> opts,
              String sel,
              void Function(String) onTap,
            ) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: opts.map((o) {
                final active = sel == o;
                return GestureDetector(
                  onTap: () => setSB(() => onTap(o)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surfaceAlt,
                      borderRadius: AppRadii.rFull,
                    ),
                    child: Text(
                      o,
                      style: AppTypography.labelMedium.copyWith(
                        color: active
                            ? AppColors.textInverse
                            : AppColors.textPrimary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.rXl,
                  boxShadow: AppShadows.lg,
                ),
                child: ClipRRect(
                  borderRadius: AppRadii.rXl,
                  child: Column(
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
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: AppRadii.rMd,
                              ),
                              child: Center(
                                child: Text(
                                  selectedEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            AppSpacing.hMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Pet Profile',
                                    style: AppTypography.titleLarge,
                                  ),
                                  AppSpacing.vXs,
                                  Text(
                                    nameCtrl.text.isEmpty
                                        ? 'Unnamed'
                                        : nameCtrl.text,
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
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('Species'),
                              AppSpacing.vSm,
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: speciesOptions.map((s) {
                                  final active = selectedSpecies == s['label'];
                                  return GestureDetector(
                                    onTap: () => setSB(() {
                                      selectedSpecies = s['label']!;
                                      selectedEmoji =
                                          speciesEmoji[s['label']] ?? '🐾';
                                      selectedBreed =
                                          (breedsBySpecies[s['label']] ??
                                                  ['Other'])
                                              .first;
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppColors.primary
                                            : AppColors.surfaceAlt,
                                        borderRadius: AppRadii.rFull,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            s['emoji']!,
                                            style: const TextStyle(
                                              fontSize: 17,
                                            ),
                                          ),
                                          AppSpacing.hXs,
                                          Text(
                                            s['label']!,
                                            style: AppTypography.labelMedium
                                                .copyWith(
                                                  color: active
                                                      ? AppColors.textInverse
                                                      : AppColors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              AppSpacing.vLg,
                              _sectionLabel('Pet Name'),
                              AppSpacing.vSm,
                              AppTextField(
                                controller: nameCtrl,
                                hint: 'e.g. Athena',
                                prefixIcon: Icons.pets_rounded,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => setSB(() {}),
                              ),
                              AppSpacing.vLg,
                              _sectionLabel('Breed'),
                              AppSpacing.vSm,
                              chips(
                                breeds,
                                selectedBreed,
                                (b) => selectedBreed = b,
                              ),
                              AppSpacing.vLg,
                              _sectionLabel('Gender'),
                              AppSpacing.vSm,
                              chips(
                                ['Male', 'Female'],
                                selectedGender,
                                (g) => selectedGender = g,
                              ),
                              AppSpacing.vLg,
                              _sectionLabel('Birthday'),
                              AppSpacing.vSm,
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedBirthdate ?? DateTime(2020),
                                    firstDate: DateTime(1990),
                                    lastDate: DateTime.now(),
                                    initialDatePickerMode: DatePickerMode.year,
                                  );
                                  if (picked != null)
                                    setSB(() => selectedBirthdate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceAlt,
                                    borderRadius: AppRadii.rMd,
                                    border: Border.all(
                                      color: selectedBirthdate != null
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: selectedBirthdate != null
                                            ? AppColors.primary
                                            : AppColors.textTertiary,
                                      ),
                                      AppSpacing.hMd,
                                      Text(
                                        selectedBirthdate != null
                                            ? DateFormat(
                                                'MMMM d, yyyy',
                                              ).format(selectedBirthdate!)
                                            : 'Select date',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: selectedBirthdate != null
                                                  ? AppColors.textPrimary
                                                  : AppColors.textTertiary,
                                            ),
                                      ),
                                      const Spacer(),
                                      if (selectedBirthdate != null)
                                        GestureDetector(
                                          onTap: () => setSB(
                                            () => selectedBirthdate = null,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              AppSpacing.vLg,
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Weight'),
                                        AppSpacing.vSm,
                                        Row(
                                          children: [
                                            Expanded(
                                              child: AppTextField(
                                                controller: weightCtrl,
                                                hint: 'e.g. 4.5',
                                                prefixIcon: Icons
                                                    .monitor_weight_outlined,
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                textInputAction:
                                                    TextInputAction.next,
                                              ),
                                            ),
                                            AppSpacing.hSm,
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceAlt,
                                                borderRadius: AppRadii.rFull,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: ['kg', 'lbs'].map((
                                                  u,
                                                ) {
                                                  final active =
                                                      weightUnit == u;
                                                  return GestureDetector(
                                                    onTap: () => setSB(
                                                      () => weightUnit = u,
                                                    ),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal:
                                                                AppSpacing.md,
                                                            vertical: 12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: active
                                                            ? AppColors.primary
                                                            : Colors
                                                                  .transparent,
                                                        borderRadius:
                                                            AppRadii.rFull,
                                                      ),
                                                      child: Text(
                                                        u,
                                                        style: AppTypography
                                                            .labelMedium
                                                            .copyWith(
                                                              color: active
                                                                  ? AppColors
                                                                        .textInverse
                                                                  : AppColors
                                                                        .textSecondary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppSpacing.hLg,
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Coat Color'),
                                        AppSpacing.vSm,
                                        AppTextField(
                                          controller: colorCtrl,
                                          hint: 'Color',
                                          prefixIcon: Icons.palette_outlined,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.vLg,
                              _sectionLabel('Spayed / Neutered'),
                              AppSpacing.vSm,
                              chips(
                                ['Yes', 'No'],
                                isNeutered ? 'Yes' : 'No',
                                (v) => isNeutered = v == 'Yes',
                              ),
                              AppSpacing.vLg,
                              _sectionLabel('Additional Notes'),
                              AppSpacing.vSm,
                              KeyboardListener(
                                focusNode: FocusNode(),
                                onKeyEvent: (event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.enter &&
                                      !HardwareKeyboard
                                          .instance
                                          .isShiftPressed) {
                                    _savePetEdit(
                                      context,
                                      pet,
                                      nameCtrl,
                                      selectedBreed,
                                      selectedBirthdate,
                                      weightCtrl,
                                      weightUnit,
                                      colorCtrl,
                                      isNeutered,
                                      selectedEmoji,
                                      notesCtrl,
                                      dialogCtx,
                                    );
                                  }
                                },
                                child: AppTextField(
                                  controller: notesCtrl,
                                  hint: 'Allergies, surgeries, conditions…',
                                  maxLines: 3,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _savePetEdit(
                                    context,
                                    pet,
                                    nameCtrl,
                                    selectedBreed,
                                    selectedBirthdate,
                                    weightCtrl,
                                    weightUnit,
                                    colorCtrl,
                                    isNeutered,
                                    selectedEmoji,
                                    notesCtrl,
                                    dialogCtx,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.md,
                          AppSpacing.xxl,
                          AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: Text(
                                'Cancel',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            AppSpacing.hSm,
                            PrimaryButton(
                              label: 'Save Changes',
                              onPressed: () => _savePetEdit(
                                context,
                                pet,
                                nameCtrl,
                                selectedBreed,
                                selectedBirthdate,
                                weightCtrl,
                                weightUnit,
                                colorCtrl,
                                isNeutered,
                                selectedEmoji,
                                notesCtrl,
                                dialogCtx,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _savePetEdit(
    BuildContext context,
    Map<String, dynamic> pet,
    TextEditingController nameCtrl,
    String breed,
    DateTime? birthdate,
    TextEditingController weightCtrl,
    String weightUnit,
    TextEditingController colorCtrl,
    bool isNeutered,
    String emoji,
    TextEditingController notesCtrl,
    BuildContext dialogCtx,
  ) async {
    if (nameCtrl.text.trim().isEmpty) return;
    Navigator.pop(dialogCtx);
    final weightStr = weightCtrl.text.trim().isEmpty
        ? ''
        : '${weightCtrl.text.trim()} $weightUnit';
    final birthdateStr = birthdate != null
        ? DateFormat('MM/dd/yyyy').format(birthdate)
        : (pet['birthdate'] ?? '');
    await _firestoreService.updatePet(
      pet['id'],
      name: nameCtrl.text.trim(),
      breed: breed,
      birthdate: birthdateStr,
      weight: weightStr,
      color: colorCtrl.text.trim(),
      isNeutered: isNeutered,
      emoji: emoji,
      notes: notesCtrl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pet updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
