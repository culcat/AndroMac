import 'package:meta/meta.dart';

/// Design tokens and theme system for AndroMac (Bridge).
class BridgeColors {
  // Brand accents
  static const int primary = 0xFF007AFF; // Apple system blue
  static const int primaryDark = 0xFF0A84FF;
  static const int success = 0xFF34C759; // Green
  static const int warning = 0xFFFF9500; // Orange
  static const int error = 0xFFFF3B30; // Red

  // Light surfaces
  static const int surfaceLight = 0xFFFFFFFF;
  static const int backgroundLight = 0xFFF2F2F7;
  static const int borderLight = 0xFFE5E5EA;
  static const int textPrimaryLight = 0xFF000000;
  static const int textSecondaryLight = 0xFF8E8E93;

  // Dark surfaces
  static const int surfaceDark = 0xFF1C1C1E;
  static const int backgroundDark = 0xFF000000;
  static const int borderDark = 0xFF38383A;
  static const int textPrimaryDark = 0xFFFFFFFF;
  static const int textSecondaryDark = 0xFF8E8E93;
}

class BridgeSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class BridgeRadii {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 16.0;
  static const double full = 999.0;
}

/// Resolved theme palette configuration for light or dark appearance.
@immutable
class BridgeThemePalette {
  final bool isDark;
  final int primary;
  final int background;
  final int surface;
  final int border;
  final int textPrimary;
  final int textSecondary;
  final int success;
  final int warning;
  final int error;

  const BridgeThemePalette({
    required this.isDark,
    required this.primary,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.error,
  });

  factory BridgeThemePalette.light() => const BridgeThemePalette(
        isDark: false,
        primary: BridgeColors.primary,
        background: BridgeColors.backgroundLight,
        surface: BridgeColors.surfaceLight,
        border: BridgeColors.borderLight,
        textPrimary: BridgeColors.textPrimaryLight,
        textSecondary: BridgeColors.textSecondaryLight,
        success: BridgeColors.success,
        warning: BridgeColors.warning,
        error: BridgeColors.error,
      );

  factory BridgeThemePalette.dark() => const BridgeThemePalette(
        isDark: true,
        primary: BridgeColors.primaryDark,
        background: BridgeColors.backgroundDark,
        surface: BridgeColors.surfaceDark,
        border: BridgeColors.borderDark,
        textPrimary: BridgeColors.textPrimaryDark,
        textSecondary: BridgeColors.textSecondaryDark,
        success: BridgeColors.success,
        warning: BridgeColors.warning,
        error: BridgeColors.error,
      );
}
