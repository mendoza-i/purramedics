import 'package:flutter/material.dart';
import 'package:purramedics/pages/vet/vet_dashboard_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class VetLoginPage extends StatefulWidget {
  const VetLoginPage({super.key});

  @override
  State<VetLoginPage> createState() => _VetLoginPageState();
}

class _VetLoginPageState extends State<VetLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VetDashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Veterinarian Login', style: AppTypography.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: AppRadii.rXl,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.vXxl,
                  Text('Welcome back, Doc!', style: AppTypography.displaySmall),
                  AppSpacing.vXs,
                  Text(
                    'Sign in to manage your practice',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.vXxl,
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'vet@clinic.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  AppSpacing.vLg,
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  AppSpacing.vXxl,
                  PrimaryButton(label: 'Sign in', onPressed: _login),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
