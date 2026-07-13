import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:purramedics/services/auth_service.dart';
import 'package:purramedics/pages/home_page.dart';
import 'package:purramedics/pages/login_page.dart';
import 'package:purramedics/pages/vet/vet_dashboard_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/responsive.dart';
import 'package:purramedics/widgets/widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = AuthService();
    final error = await auth.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      false,
      name: _nameController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Welcome to Purramedics 🎉'),
        backgroundColor: AppColors.success,
      ),
    );

    if (auth.isVet) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VetDashboardPage()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    }
  }

  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 56),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -120,
            child: Icon(
              Icons.circle_outlined,
              size: 420,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -60,
            child: Icon(
              Icons.circle_outlined,
              size: 620,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: AppRadii.rMd,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'lib/images/logo1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  AppSpacing.hMd,
                  Text(
                    'Purramedics',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.textInverse,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Join the\nFamily! 🐾',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 52,
                  color: AppColors.textInverse,
                  height: 1.1,
                ),
              ),
              AppSpacing.vXl,
              Text(
                'Create your free account in under\na minute. No credit card required.\nYour pets deserve the best care.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: 17,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                ),
              ),
              const Spacer(),
              _benefit(
                Icons.calendar_month_outlined,
                'Easy appointment booking',
              ),
              AppSpacing.vMd,
              _benefit(Icons.pets_rounded, 'Full pet health records'),
              AppSpacing.vMd,
              _benefit(
                Icons.chat_bubble_outline_rounded,
                'Direct vet communication',
              ),
              AppSpacing.vXxl,
              Text(
                '© ${DateTime.now().year} Purramedics. All rights reserved.',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: AppRadii.rSm,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        AppSpacing.hMd,
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isWide) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? AppSpacing.huge : AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide) AppSpacing.vXxl,
            Text('Create Account', style: AppTypography.displayMedium),
            AppSpacing.vSm,
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: AppTypography.bodyMedium,
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Text(
                    'Sign in',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.vHuge,
            AppTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'Jane Doe',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            AppSpacing.vLg,
            AppTextField(
              controller: _emailController,
              label: 'Email address',
              hint: 'jane@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            AppSpacing.vLg,
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'At least 6 characters',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signUp(),
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
            AppSpacing.vHuge,
            PrimaryButton(
              label: 'Create free account',
              onPressed: _signUp,
              isLoading: _isLoading,
            ),
            AppSpacing.vLg,
            Center(
              child: Text(
                'By signing up, you agree to our Terms & Privacy Policy.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            AppSpacing.vXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: AppRadii.rMd,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'lib/images/logo1.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  AppSpacing.hMd,
                  Text(
                    'Purramedics',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textInverse,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: _buildForm(false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = kIsWeb && Responsive.isWide(context);

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Row(
          children: [
            Expanded(child: _buildBrandPanel()),
            Expanded(child: Center(child: _buildForm(true))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _buildMobileLayout(),
    );
  }
}
