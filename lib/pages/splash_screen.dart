import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:purramedics/pages/home_page.dart';
import 'package:purramedics/pages/intro_page.dart';
import 'package:purramedics/pages/login_page.dart';
import 'package:purramedics/pages/vet/vet_dashboard_page.dart';
import 'package:purramedics/services/auth_service.dart';
import 'package:purramedics/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), 
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward().then((_) {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    
    final auth = AuthService();
    
    // Auto-login routing! If the user is already authenticated from a previous session,
    // they bypass the IntroPage entirely.
    if (auth.isLoggedIn) {
      if (auth.isVet) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VetDashboardPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } else {
      // On web, skip the grey IntroPage and go straight to the split login page
      if (kIsWeb) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const IntroPage()));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadii.rXl,
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Image.asset('lib/images/logo1.png', fit: BoxFit.contain),
            ),
            AppSpacing.vXl,
            Text('Purramedics', style: AppTypography.headlineLarge),
            AppSpacing.vXs,
            Text(
              'Caring for your pets',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 200,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.huge),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: AppRadii.rFull,
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _animation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: AppRadii.rFull,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
