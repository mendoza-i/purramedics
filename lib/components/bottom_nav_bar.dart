import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../theme/app_theme.dart';

class MyBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onTabChange;

  const MyBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: GNav(
          selectedIndex: selectedIndex,
          color: AppColors.textTertiary,
          activeColor: AppColors.primaryDark,
          tabBackgroundColor: AppColors.primarySurface,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          tabBorderRadius: AppRadii.full,
          gap: AppSpacing.sm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          iconSize: 22,
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.primaryDark,
          ),
          onTabChange: (value) => onTabChange?.call(value),
          tabs: const [
            GButton(icon: Icons.home_rounded, text: 'Home'),
            GButton(icon: Icons.calendar_today_rounded, text: 'Appointments'),
            GButton(icon: Icons.healing_rounded, text: 'Symptoms'),
            GButton(icon: Icons.pets_rounded, text: 'Pets'),
          ],
        ),
      ),
    );
  }
}
