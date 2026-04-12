// lib/core/theme/app_theme.dart
//
// Instrutor em Casa Brasil — AppThemeData
// Gerado com base no UI Style Guide v1.0
// Março de 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP COLORS
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary — Azul
  static const Color primary600    = Color(0xFF1D6EF5);
  static const Color primary500    = Color(0xFF3B82F6);
  static const Color primary400    = Color(0xFF60A5FA);
  static const Color primary200    = Color(0xFFBFDBFE);
  static const Color primary100    = Color(0xFFDBEAFE);
  static const Color primary50     = Color(0xFFEFF6FF);

  // Secondary — Verde (sucesso / conclusão)
  static const Color secondary600  = Color(0xFF0F9D76);
  static const Color secondary500  = Color(0xFF10B981);
  static const Color secondary400  = Color(0xFF34D399);
  static const Color secondary100  = Color(0xFFD1FAE5);

  // Warning — Âmbar
  static const Color warning500    = Color(0xFFF59E0B);
  static const Color warning100    = Color(0xFFFEF3C7);

  // Danger — Vermelho
  static const Color danger600     = Color(0xFFDC2626);
  static const Color danger500     = Color(0xFFEF4444);
  static const Color danger100     = Color(0xFFFEE2E2);

  // Neutros
  static const Color gray950       = Color(0xFF060B16);
  static const Color gray900       = Color(0xFF0F172A);
  static const Color gray800       = Color(0xFF1E293B);
  static const Color gray700       = Color(0xFF334155);
  static const Color gray600       = Color(0xFF475569);
  static const Color gray500       = Color(0xFF64748B);
  static const Color gray400       = Color(0xFF94A3B8);
  static const Color gray300       = Color(0xFFCBD5E1);
  static const Color gray200       = Color(0xFFE2E8F0);
  static const Color gray100       = Color(0xFFF1F5F9);
  static const Color gray50        = Color(0xFFF8FAFC);
  static const Color white         = Color(0xFFFFFFFF);

  // Semânticas / aliases
  static const Color primary       = primary600;
  static const Color success       = secondary600;
  static const Color warning       = warning500;
  static const Color danger        = danger500;
  static const Color emergency     = danger600;

  // Texto
  static const Color textPrimary   = gray900;
  static const Color textSecondary = gray600;
  static const Color textMuted     = gray400;
  static const Color textInverse   = white;

  // Superfícies
  static const Color surface       = white;
  static const Color surfaceRaised = gray50;
  static const Color background    = white; // fundo geral do app

  // Bordas
  static const Color border        = gray200;
  static const Color borderStrong  = gray300;

  // Sombra de botão primário
  static const Color shadowBrand   = Color(0x471D6EF5); // 28% opacidade
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SPACING
// ─────────────────────────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const double xs          = 4.0;
  static const double sm          = 8.0;
  static const double md          = 16.0;
  static const double lg          = 24.0;
  static const double xl          = 32.0;
  static const double xxl         = 48.0;
  static const double xxxl        = 64.0;

  // Uso específico
  static const double pagePadding = 20.0;
  static const double cardPadding = 16.0;
  static const double inputPadding = 12.0;
  static const double sectionGap  = 28.0;
  static const double itemGap     = 12.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// APP RADIUS
// ─────────────────────────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double sm          = 6.0;
  static const double md          = 10.0;
  static const double lg          = 16.0;
  static const double xl          = 24.0;
  static const double full        = 9999.0;

  static BorderRadius get radiusSm   => BorderRadius.circular(sm);
  static BorderRadius get radiusMd   => BorderRadius.circular(md);
  static BorderRadius get radiusLg   => BorderRadius.circular(lg);
  static BorderRadius get radiusXl   => BorderRadius.circular(xl);
  static BorderRadius get radiusFull => BorderRadius.circular(full);
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SHADOWS
// ─────────────────────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
    BoxShadow(color: Colors.black.withAlpha(20),  blurRadius: 3,  offset: const Offset(0, 1)),  // 0.08 × 255 ≈ 20
    BoxShadow(color: Colors.black.withAlpha(13),  blurRadius: 2,  offset: const Offset(0, 1)),  // 0.05 × 255 ≈ 13
  ];

  static List<BoxShadow> get md => [
    BoxShadow(color: Colors.black.withAlpha(20),  blurRadius: 12, offset: const Offset(0, 4)),  // 0.08 × 255 ≈ 20
    BoxShadow(color: Colors.black.withAlpha(13),  blurRadius: 6,  offset: const Offset(0, 2)),  // 0.05 × 255 ≈ 13
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(color: Colors.black.withAlpha(26),  blurRadius: 32, offset: const Offset(0, 12)), // 0.10 × 255 ≈ 26
    BoxShadow(color: Colors.black.withAlpha(15),  blurRadius: 12, offset: const Offset(0, 4)),  // 0.06 × 255 ≈ 15
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(color: Colors.black.withAlpha(31),  blurRadius: 56, offset: const Offset(0, 24)), // 0.12 × 255 ≈ 31
    BoxShadow(color: Colors.black.withAlpha(20),  blurRadius: 20, offset: const Offset(0, 8)),  // 0.08 × 255 ≈ 20
  ];

  static List<BoxShadow> get brand => [
    BoxShadow(color: AppColors.primary600.withAlpha(71), blurRadius: 24, offset: const Offset(0, 8)), // 0.28 × 255 ≈ 71
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// APP TEXT STYLES
// ─────────────────────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  // Display — Sora 800 · 40px
  static TextStyle get displayLarge => GoogleFonts.sora(
    fontSize: 40, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.1,
  );

  // H1 — Sora 700 · 28px
  static TextStyle get h1 => GoogleFonts.sora(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  // H2 — Sora 600 · 22px
  static TextStyle get h2 => GoogleFonts.sora(
    fontSize: 22, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.25,
  );

  // H3 — Sora 600 · 17px
  static TextStyle get h3 => GoogleFonts.sora(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.3,
  );

  // Body Large — DM Sans 400 · 16px
  static TextStyle get bodyLarge => GoogleFonts.dmSans(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.6,
  );

  // Body — DM Sans 400 · 14px
  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.6,
  );

  // Body Medium — DM Sans 500 · 14px
  static TextStyle get bodyMedium => GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, height: 1.6,
  );

  // Caption — DM Sans 500 · 12px
  static TextStyle get caption => GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textMuted, height: 1.5,
  );

  // Label — DM Sans 700 · 11px · Uppercase
  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: AppColors.textMuted, letterSpacing: 0.10 * 11,
    height: 1.4,
  );

  // Button — DM Sans 600 · 15px
  static TextStyle get button => GoogleFonts.dmSans(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textInverse, height: 1.0,
  );

  // Button SM — DM Sans 600 · 13px
  static TextStyle get buttonSm => GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textInverse, height: 1.0,
  );

  // Button LG — DM Sans 600 · 17px
  static TextStyle get buttonLg => GoogleFonts.dmSans(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textInverse, height: 1.0,
  );

  // Price — Sora 700 · 22px
  static TextStyle get price => GoogleFonts.sora(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  // Price SM — Sora 700 · 17px
  static TextStyle get priceSm => GoogleFonts.sora(
    fontSize: 17, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  // Timer — JetBrains Mono 700 · 40px
  static TextStyle get timer => GoogleFonts.jetBrainsMono(
    fontSize: 40, fontWeight: FontWeight.w700,
    color: AppColors.primary600, height: 1.1, letterSpacing: 0.04 * 40,
  );

  // Timer SM — JetBrains Mono 500 · 24px
  static TextStyle get timerSm => GoogleFonts.jetBrainsMono(
    fontSize: 24, fontWeight: FontWeight.w500,
    color: AppColors.primary600, height: 1.1,
  );

  // Mono — JetBrains Mono 400 · 13px
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  // Nav Label — DM Sans 600 · 10px
  static TextStyle get navLabel => GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: AppColors.textMuted, height: 1.2,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME DATA
// ─────────────────────────────────────────────────────────────────────────────

class AppThemeData {
  AppThemeData._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // ── Color Scheme ──────────────────────────────────────────────────────────
    colorScheme: const ColorScheme.light(
      primary:          AppColors.primary600,
      onPrimary:        AppColors.white,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary600,

      secondary:        AppColors.secondary600,
      onSecondary:      AppColors.white,
      secondaryContainer: AppColors.secondary100,
      onSecondaryContainer: AppColors.secondary600,

      error:            AppColors.danger500,
      onError:          AppColors.white,
      errorContainer:   AppColors.danger100,
      onErrorContainer: AppColors.danger600,

      surface:          AppColors.surface,
      onSurface:        AppColors.textPrimary,
      surfaceContainerHighest: AppColors.gray100,

      outline:          AppColors.border,
      outlineVariant:   AppColors.borderStrong,
    ),

    // ── Scaffold ──────────────────────────────────────────────────────────────
    scaffoldBackgroundColor: AppColors.background,

    // ── App Bar ───────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor:    AppColors.surface,
      foregroundColor:    AppColors.textPrimary,
      elevation:          0,
      scrolledUnderElevation: 1,
      shadowColor:        Colors.black.withAlpha(15), // 0.06 × 255 ≈ 15
      surfaceTintColor:   Colors.transparent,
      centerTitle:        true,
      titleTextStyle:     AppTextStyles.h3,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // ── Bottom Navigation Bar ─────────────────────────────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:      AppColors.surface,
      selectedItemColor:    AppColors.primary600,
      unselectedItemColor:  AppColors.textMuted,
      selectedLabelStyle:   AppTextStyles.navLabel.copyWith(color: AppColors.primary600),
      unselectedLabelStyle: AppTextStyles.navLabel,
      showSelectedLabels:   true,
      showUnselectedLabels: true,
      type:                 BottomNavigationBarType.fixed,
      elevation:            8,
    ),

    // ── Elevated Button ───────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:    AppColors.primary600,
        foregroundColor:    AppColors.white,
        disabledBackgroundColor: AppColors.gray200,
        disabledForegroundColor: AppColors.textMuted,
        elevation:          0,
        shadowColor:        Colors.transparent,
        textStyle:          AppTextStyles.button,
        padding:            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        minimumSize:        const Size(0, 48),
      ),
    ),

    // ── Outlined Button ───────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:    AppColors.primary600,
        side: const BorderSide(color: AppColors.primary200, width: 1.5),
        textStyle:          AppTextStyles.button.copyWith(color: AppColors.primary600),
        padding:            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        minimumSize:        const Size(0, 48),
      ),
    ),

    // ── Text Button ───────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:    AppColors.textSecondary,
        textStyle:          AppTextStyles.button.copyWith(color: AppColors.textSecondary),
        padding:            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
    ),

    // ── Floating Action Button ────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor:    AppColors.primary600,
      foregroundColor:    AppColors.white,
      elevation:          0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusFull),
    ),

    // ── Input Decoration ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled:             true,
      fillColor:          AppColors.surface,
      contentPadding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle:          AppTextStyles.body.copyWith(color: AppColors.textMuted),
      labelStyle:         AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      errorStyle:         AppTextStyles.caption.copyWith(color: AppColors.danger500),
      helperStyle:        AppTextStyles.caption,
      floatingLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.primary600),
      prefixIconColor:          AppColors.primary,

      border: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: const BorderSide(color: AppColors.danger500, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: const BorderSide(color: AppColors.danger500, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.radiusMd,
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
    ),

    // ── Card ──────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color:        AppColors.surface,
      elevation:    0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLg,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Chip ──────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor:    AppColors.background,
      labelStyle:         AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary, fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary100,
      side: const BorderSide(color: AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusFull),
      checkmarkColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),

    // ── Dialog ────────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor:    AppColors.surface,
      elevation:          0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
      titleTextStyle:     AppTextStyles.h2,
      contentTextStyle:   AppTextStyles.body,
    ),

    // ── Bottom Sheet ──────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor:    AppColors.surface,
      elevation:          0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: AppColors.gray300,
      dragHandleSize: Size(40, 4),
    ),

    // ── Snack Bar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor:    AppColors.gray900,
      contentTextStyle:   AppTextStyles.body.copyWith(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      behavior:           SnackBarBehavior.floating,
      elevation:          0,
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color:     AppColors.border,
      thickness: 1,
      space:     1,
    ),

    // ── Switch ────────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.white;
        return AppColors.gray300;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary600;
        return AppColors.gray200;
      }),
    ),

    // ── Checkbox ──────────────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary600;
        return AppColors.surface;
      }),
      checkColor: WidgetStateProperty.all(AppColors.white),
      side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
    ),

    // ── Radio ─────────────────────────────────────────────────────────────────
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary600;
        return AppColors.borderStrong;
      }),
    ),

    // ── Progress Indicator ────────────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:                AppColors.primary600,
      linearTrackColor:     AppColors.gray200,
      linearMinHeight:      8,
      circularTrackColor:   AppColors.primary100,
    ),

    // ── List Tile ─────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding:       const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      titleTextStyle:       AppTextStyles.bodyMedium,
      subtitleTextStyle:    AppTextStyles.caption,
      iconColor:            AppColors.primary,
      tileColor:            Colors.transparent,
    ),

    // ── Tab Bar ───────────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor:           AppColors.primary600,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle:           AppTextStyles.bodyMedium,
      unselectedLabelStyle: AppTextStyles.body,
      indicatorColor:       AppColors.primary600,
      indicatorSize:        TabBarIndicatorSize.label,
      dividerColor:         AppColors.border,
    ),

    // ── Typography ────────────────────────────────────────────────────────────
    textTheme: TextTheme(
      displayLarge:  AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.h1,
      displaySmall:  AppTextStyles.h2,
      headlineLarge: AppTextStyles.h2,
      headlineMedium:AppTextStyles.h3,
      headlineSmall: AppTextStyles.h3,
      titleLarge:    AppTextStyles.h3,
      titleMedium:   AppTextStyles.bodyMedium,
      titleSmall:    AppTextStyles.bodyMedium,
      bodyLarge:     AppTextStyles.bodyLarge,
      bodyMedium:    AppTextStyles.body,
      bodySmall:     AppTextStyles.caption,
      labelLarge:    AppTextStyles.button,
      labelMedium:   AppTextStyles.buttonSm,
      labelSmall:    AppTextStyles.label,
    ),
  );
}