import 'package:flutter/material.dart';
import 'package:purramedics/services/auth_service.dart';
import 'package:purramedics/pages/home_page.dart';
import 'package:purramedics/pages/vet/vet_dashboard_page.dart';
import 'package:purramedics/pages/signup_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/responsive.dart';
import 'package:purramedics/widgets/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    setState(() => _isLoading = true);

    final auth = AuthService();
    final error = await auth.login(_emailController.text.trim(), _passwordController.text.trim());

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

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
            child: Icon(Icons.circle_outlined, size: 420, color: Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            bottom: -160,
            left: -60,
            child: Icon(Icons.circle_outlined, size: 620, color: Colors.white.withOpacity(0.05)),
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
                    child: Image.asset('lib/images/logo1.png', fit: BoxFit.contain),
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
                'Hello,\nWelcome! 👋',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 52,
                  color: AppColors.textInverse,
                  height: 1.1,
                ),
              ),
              AppSpacing.vXl,
              Text(
                'Your all-in-one veterinary platform.\nManage appointments, pet records,\nand clinic communications — effortlessly.',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: 17,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _trustBadge(Icons.verified_outlined, 'Trusted Clinic'),
                  AppSpacing.hXl,
                  _trustBadge(Icons.pets_rounded, 'Pet-Focused'),
                  AppSpacing.hXl,
                  _trustBadge(Icons.lock_outline_rounded, 'Secure'),
                ],
              ),
              AppSpacing.vXxl,
              Text(
                '© ${DateTime.now().year} Purramedics. All rights reserved.',
                style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
        AppSpacing.hXs,
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildFormPanel(bool isWide) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isWide) ...[
                Text('Purramedics', style: AppTypography.displaySmall),
                AppSpacing.vHuge,
              ] else
                AppSpacing.vXxl,
              Text('Welcome Back', style: AppTypography.displayMedium),
              AppSpacing.vSm,
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppTypography.bodyMedium),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    ),
                    child: Text(
                      'Create one for free',
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
                controller: _emailController,
                label: 'Email address',
                hint: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.vLg,
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              AppSpacing.vHuge,
              PrimaryButton(
                label: 'Log in',
                onPressed: _login,
                isLoading: _isLoading,
              ),
              AppSpacing.vXxl,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: isWide
          ? Row(
              children: [
                Expanded(child: _buildBrandPanel()),
                Expanded(child: _buildFormPanel(true)),
              ],
            )
          : SafeArea(child: _buildFormPanel(false)),
    );
  }
}
