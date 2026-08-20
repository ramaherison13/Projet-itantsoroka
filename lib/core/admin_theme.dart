import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN THEME — Design System centralisé
// ─────────────────────────────────────────────────────────────────────────────

class AdminTheme {
  AdminTheme._();

  // ── Couleurs primaires ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF098E00);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF04630A);
  static const Color accent = Color(0xFF4ADE80);

  // ── Palette sémantique ──────────────────────────────────────────────────────
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFEC4899);

  // ── Fond & Surfaces — Light ─────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // ── Texte — Light ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Fond & Surfaces — Dark ──────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surface2Dark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);

  // ── Texte — Dark ───────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // ── Breakpoints ────────────────────────────────────────────────────────────
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double desktopMin = 1280;

  // ── Radius ─────────────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 100.0;

  // ── Espacement ─────────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ── Ombres ─────────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF154D34), Color(0xFF0D3322)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Helpers responsive ─────────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMax;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileMax && w < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMin;

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileMax) return 16.0;
    if (w < tabletMax) return 24.0;
    return 32.0;
  }

  // ── Couleurs contextuelles ─────────────────────────────────────────────────
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? bgDark : bgLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceDark
          : surfaceLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textPrimaryDark
          : textPrimary;

  static Color textSub(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondaryDark
          : textSecondary;

  // ── Widget helpers ─────────────────────────────────────────────────────────

  /// Badge coloré générique
  static Widget badge(String label, Color color, {double fontSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Icône dans un conteneur arrondi coloré
  static Widget iconBox(IconData icon, Color color, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  /// Séparateur de section avec titre
  static Widget sectionHeader(String title, BuildContext context,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: text(context),
              letterSpacing: -0.2,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  /// Bouton d'action compact
  static Widget actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool iconOnly = false,
  }) {
    if (iconOnly) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusSm),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(radiusSm),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.06),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label,
          style:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  /// Skeleton loading block
  static Widget skeleton({double width = double.infinity, double height = 16, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXTENSIONS UTILES
// ─────────────────────────────────────────────────────────────────────────────

extension ContextExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isMobile => screenWidth < AdminTheme.mobileMax;
  bool get isTablet =>
      screenWidth >= AdminTheme.mobileMax && screenWidth < AdminTheme.tabletMax;
  bool get isDesktop => screenWidth >= AdminTheme.desktopMin;
}
