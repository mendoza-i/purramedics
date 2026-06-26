import 'package:flutter/material.dart';

/// ============================================================================
/// RESPONSIVE UTILITY
/// ----------------------------------------------------------------------------
/// A centralized helper that determines the current platform layout type
/// based on the device's screen width.
///
/// BREAKPOINTS (industry standard):
///   Mobile  → width < 768px   (phones)
///   Tablet  → 768px–1099px    (iPads, small laptops)
///   Desktop → 1100px+         (web browsers, large monitors)
///
/// USAGE EXAMPLE:
///   int columns = Responsive.isDesktop(context) ? 3 : 2;
///   double padding = Responsive.value(context, mobile: 16, desktop: 40);
/// ============================================================================
class Responsive {
  // ── Breakpoint checks ──────────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 768 && w < 1100;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Returns true for anything wider than a phone (tablet + desktop / web).
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768;

  // ── Convenience value picker ───────────────────────────────────────────────
  /// Returns a different value depending on screen size.
  /// Falls back to [mobile] if [tablet] or [desktop] are not provided.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  // ── Layout helpers ─────────────────────────────────────────────────────────

  /// Horizontal page padding — more breathing room on web.
  static double pagePadding(BuildContext context) =>
      value(context, mobile: 20.0, tablet: 40.0, desktop: 64.0);

  /// Content max-width — prevents content stretching to 2000px on big screens.
  static double contentMaxWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 720.0, desktop: 1150.0);

  /// Number of grid columns for tool/card grids.
  static int gridColumns(
    BuildContext context, {
    int mobileCount = 2,
    int desktopCount = 3,
  }) => isWide(context) ? desktopCount : mobileCount;
}
