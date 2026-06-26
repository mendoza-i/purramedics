import 'package:flutter/material.dart';
import 'package:purramedics/pages/home_page.dart';
import 'package:purramedics/pages/login_page.dart';
import 'package:purramedics/pages/signup_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: deviceHeight - 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: deviceHeight * 0.08),
                    Center(
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: child,
                          );
                        },
                        child: Container(
                          width: deviceHeight * 0.22,
                          height: deviceHeight * 0.22,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: AppRadii.rXl,
                          ),
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Image.asset('lib/images/logo2.png'),
                        ),
                      ),
                    ),
                    AppSpacing.vXxxl,
                    Text(
                      'Welcome to Purramedics',
                      style: AppTypography.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.vSm,
                    Text(
                      'Your trusted companion for pet healthcare',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: deviceHeight * 0.1),
                    PrimaryButton(
                      label: 'Log in',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                    AppSpacing.vMd,
                    SecondaryButton(
                      label: 'Create account',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      ),
                    ),
                    AppSpacing.vLg,
                    Center(
                      child: TextButton(
                        onPressed: _goToHome,
                        child: Text(
                          'Continue as guest',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.vXl,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
