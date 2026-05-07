import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/services/auth_service.dart';
import 'package:purramedics/pages/intro_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    if (_user == null) return;
    _firestoreService.getUserProfileStream(_user!.uid).first.then((snap) {
      if (!mounted) return;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? _user!.displayName ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      } else {
        setState(() {
          _nameController.text = _user!.displayName ?? '';
        });
      }
    });
  }

  Future<void> _save() async {
    if (_user == null) return;
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final error = await AuthService().updateUserName(_nameController.text.trim());
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    await _firestoreService.updateUserContactDetails(
      _user!.uid,
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _addressController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
        title: Text('Log out', style: AppTypography.headlineSmall),
        content: Text(
          'Are you sure you want to log out of Purramedics?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const IntroPage()),
                (_) => false,
              );
            },
            child: Text('Log out', style: AppTypography.labelLarge.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Please sign in', style: AppTypography.bodyLarge),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Settings & Profile', style: AppTypography.headlineLarge),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Personal Information', style: AppTypography.titleLarge),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isEditing = !_isEditing),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: _isEditing ? AppColors.surfaceAlt : AppColors.primarySurface,
                                borderRadius: AppRadii.rFull,
                              ),
                              child: Text(
                                _isEditing ? 'Cancel' : 'Edit info',
                                style: AppTypography.labelMedium.copyWith(
                                  color: _isEditing ? AppColors.textSecondary : AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vSm,
                      Text(
                        'This information is used by veterinarians to contact you regarding your pets.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, height: 1.5),
                      ),
                      AppSpacing.vXxl,

                      AppTextField(
                        label: 'Email address',
                        prefixIcon: Icons.lock_outline_rounded,
                        controller: TextEditingController(text: _user!.email),
                        readOnly: true,
                        enabled: false,
                      ),
                      AppSpacing.vLg,
                      AppTextField(
                        label: 'Display name',
                        prefixIcon: Icons.person_outline_rounded,
                        controller: _nameController,
                        readOnly: !_isEditing,
                        textInputAction: TextInputAction.next,
                      ),
                      AppSpacing.vLg,
                      AppTextField(
                        label: 'Phone number',
                        prefixIcon: Icons.phone_outlined,
                        controller: _phoneController,
                        readOnly: !_isEditing,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.next,
                      ),
                      AppSpacing.vLg,
                      AppTextField(
                        label: 'Physical address',
                        prefixIcon: Icons.location_on_outlined,
                        controller: _addressController,
                        readOnly: !_isEditing,
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      ),

                      if (_isEditing) ...[
                        AppSpacing.vXxl,
                        PrimaryButton(
                          label: 'Save changes',
                          onPressed: _save,
                          isLoading: _isSaving,
                        ),
                      ],
                    ],
                  ),
                ),

                AppSpacing.vHuge,

                AppCard(
                  padding: EdgeInsets.zero,
                  borderColor: AppColors.dangerSurface,
                  child: InkWell(
                    borderRadius: AppRadii.rLg,
                    onTap: _confirmSignOut,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Row(
                        children: [
                          IconAvatar(
                            icon: Icons.logout_rounded,
                            color: AppColors.danger,
                            background: AppColors.dangerSurface,
                          ),
                          AppSpacing.hLg,
                          Text(
                            'Sign out securely',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.danger),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.danger),
                        ],
                      ),
                    ),
                  ),
                ),

                AppSpacing.vHuge,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
