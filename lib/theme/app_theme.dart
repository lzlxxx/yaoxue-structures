import 'package:material_ui/material_ui.dart';

/// 双主题语义色板：日间“药典蓝图”与夜间“夜读墨蓝”护眼配色。
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.structureSurface,
    required this.structureInk,
    required this.border,
    required this.structureBorder,
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.primarySoftBorder,
    required this.revealedSurface,
    required this.highlightBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.badgeSurface,
    required this.progressTrack,
    required this.amber,
    required this.amberSoft,
    required this.amberBorder,
    required this.success,
    required this.successSoft,
    required this.successBorder,
    required this.danger,
    required this.dangerSoft,
    required this.cardShadow,
  });

  final bool isDark;
  final Color canvas;
  final Color surface;
  final Color structureSurface;
  final Color structureInk;
  final Color border;
  final Color structureBorder;
  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color primarySoftBorder;
  final Color revealedSurface;
  final Color highlightBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color badgeSurface;
  final Color progressTrack;
  final Color amber;
  final Color amberSoft;
  final Color amberBorder;
  final Color success;
  final Color successSoft;
  final Color successBorder;
  final Color danger;
  final Color dangerSoft;
  final Color cardShadow;

  static const AppPalette light = AppPalette(
    isDark: false,
    canvas: Color(0xFFF3F6FA),
    surface: Color(0xFFFFFFFF),
    structureSurface: Color(0xFFFAFBFD),
    structureInk: Color(0xFF172130),
    border: Color(0xFFE2E8F0),
    structureBorder: Color(0xFFEDF2F7),
    primary: Color(0xFF1D4ED8),
    primaryDeep: Color(0xFF1E3A5F),
    primarySoft: Color(0xFFEFF6FF),
    primarySoftBorder: Color(0xFFBFDBFE),
    revealedSurface: Color(0xFFF0F6FF),
    highlightBg: Color(0xFFDBEAFE),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    badgeSurface: Color(0xFFF1F5F9),
    progressTrack: Color(0xFFE2E8F0),
    amber: Color(0xFFD97706),
    amberSoft: Color(0xFFFEF3C7),
    amberBorder: Color(0xFFFCD34D),
    success: Color(0xFF15803D),
    successSoft: Color(0xFFECFDF5),
    successBorder: Color(0xFFA7F3D0),
    danger: Color(0xFFDC2626),
    dangerSoft: Color(0xFFFEF2F2),
    cardShadow: Color(0x0A0F172A),
  );

  // 低蓝光柔和深石板夜蓝，避免纯黑配纯白的夜间炫光重影。
  static const AppPalette dark = AppPalette(
    isDark: true,
    canvas: Color(0xFF0E141B),
    surface: Color(0xFF161F2A),
    structureSurface: Color(0xFF1B2635),
    structureInk: Color(0xFFE6EEF8),
    border: Color(0xFF263344),
    structureBorder: Color(0xFF2D3C50),
    primary: Color(0xFF60A5FA),
    primaryDeep: Color(0xFFDBEAFE),
    primarySoft: Color(0xFF17253D),
    primarySoftBorder: Color(0xFF26426B),
    revealedSurface: Color(0xFF16243A),
    highlightBg: Color(0xFF1E3A5F),
    textPrimary: Color(0xFFEDF2F7),
    textSecondary: Color(0xFFA0AEC0),
    textMuted: Color(0xFF7D8FA3),
    badgeSurface: Color(0xFF1F2B3A),
    progressTrack: Color(0xFF243244),
    amber: Color(0xFFF59E0B),
    amberSoft: Color(0xFF2E2412),
    amberBorder: Color(0xFF614719),
    success: Color(0xFF4ADE80),
    successSoft: Color(0xFF122B20),
    successBorder: Color(0xFF1F533A),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF2E171A),
    cardShadow: Color(0x28000000),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? light;
  }

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

abstract final class AppTheme {
  static ThemeData light() => _buildTheme(AppPalette.light, Brightness.light);

  static ThemeData dark() => _buildTheme(AppPalette.dark, Brightness.dark);

  static ThemeData _buildTheme(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
      surface: palette.surface,
      primary: palette.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.canvas,
      splashFactory: InkRipple.splashFactory,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.canvas,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: _buildNavBarTheme(palette),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.isDark
            ? const Color(0xFF243244)
            : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: const Color(0xFF93C5FD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: _buildTextTheme(palette),
    );
  }

  static NavigationBarThemeData _buildNavBarTheme(AppPalette palette) {
    return NavigationBarThemeData(
      height: 68,
      backgroundColor: palette.surface,
      indicatorColor: palette.primarySoft,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? palette.primary : palette.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22,
          color: selected ? palette.primary : palette.textMuted,
        );
      }),
    );
  }

  static TextTheme _buildTextTheme(AppPalette palette) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: palette.textPrimary,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
        height: 1.3,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: palette.textMuted,
      ),
    );
  }
}
