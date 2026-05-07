import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/pages/intro_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class VetSettingsPage extends StatefulWidget {
  const VetSettingsPage({super.key});

  @override
  State<VetSettingsPage> createState() => _VetSettingsPageState();
}

class _VetSettingsPageState extends State<VetSettingsPage> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('clinic_profile')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone, email, and address cannot be empty'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateClinicSettings(
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Clinic settings saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmSignOut() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IntroPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Settings & Profile', style: AppTypography.headlineLarge),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Align(
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
                                  child: Text('Contact Information', style: AppTypography.titleLarge),
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
                              "This data is securely displayed on the Emergency page 'Contact Us' module.",
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, height: 1.5),
                            ),
                            AppSpacing.vXxl,
                            AppTextField(
                              controller: _phoneController,
                              label: 'Clinic phone',
                              prefixIcon: Icons.phone_outlined,
                              readOnly: !_isEditing,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textInputAction: TextInputAction.next,
                            ),
                            AppSpacing.vLg,
                            AppTextField(
                              controller: _emailController,
                              label: 'Support email',
                              prefixIcon: Icons.email_outlined,
                              readOnly: !_isEditing,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            AppSpacing.vLg,
                            AppTextField(
                              controller: _addressController,
                              label: 'Physical address',
                              prefixIcon: Icons.location_on_outlined,
                              readOnly: !_isEditing,
                              keyboardType: TextInputType.streetAddress,
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _saveSettings(),
                            ),
                            if (_isEditing) ...[
                              AppSpacing.vXxl,
                              PrimaryButton(
                                label: 'Save changes',
                                onPressed: _saveSettings,
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
