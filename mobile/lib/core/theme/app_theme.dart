import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color_scheme.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

export 'app_color_scheme.dart';
export 'app_colors.dart';
export 'app_spacing.dart';

// ─── Text Themes ───────────────────────────────────────────────────────────────
TextTheme _buildTextTheme({Color? bodyColor, Color? displayColor}) {
  final base = TextTheme(
    displayLarge:
        GoogleFonts.beVietnamPro(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium:
        GoogleFonts.beVietnamPro(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall:
        GoogleFonts.beVietnamPro(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge:
        GoogleFonts.beVietnamPro(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium:
        GoogleFonts.beVietnamPro(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall:
        GoogleFonts.beVietnamPro(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge:
        GoogleFonts.beVietnamPro(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium:
        GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall:
        GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge:
        GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium:
        GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall:
        GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge:
        GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium:
        GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall:
        GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w500),
  );
  if (bodyColor == null && displayColor == null) return base;
  return base.apply(
    bodyColor: bodyColor,
    displayColor: displayColor ?? bodyColor,
  );
}

// ─── AppTheme ──────────────────────────────────────────────────────────────────
class AppTheme {
  // ── Light Theme ──────────────────────────────────────────────────────────────
  static ThemeData get light {
    const scheme = AppColorScheme.light();

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.jade500,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: AppColors.jade50,
      onPrimaryContainer: AppColors.jade900,
      secondary: AppColors.gold500,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: AppColors.gold50,
      onSecondaryContainer: AppColors.gold900,
      tertiary: AppColors.coral500,
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: AppColors.coral50,
      onTertiaryContainer: AppColors.coral900,
      surface: Color(0xFFFFFFFF),
      onSurface: AppColors.slate900,
      surfaceContainerHighest: AppColors.slate100,
      error: AppColors.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: AppColors.errorBg,
      onErrorContainer: Color(0xFF7F1D1D),
      outline: AppColors.slate300,
      outlineVariant: AppColors.slate200,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(),
      scaffoldBackgroundColor: scheme.bgCanvas,
      extensions: const [AppThemeExtension(colors: scheme)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.bgSurface,
        foregroundColor: scheme.textBrand,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.textBrand),
        titleTextStyle: GoogleFonts.beVietnamPro(
          color: scheme.textBrand,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.jade500,
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.jade500,
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.jade500,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: const BorderSide(color: AppColors.jade500, width: 1.5),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.jade500,
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.jade500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        labelStyle:
            GoogleFonts.beVietnamPro(fontSize: 14, color: scheme.textSecondary),
        hintStyle:
            GoogleFonts.beVietnamPro(fontSize: 14, color: scheme.textTertiary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.borderDefault),
        ),
        color: scheme.bgSurface,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.bgSurface,
        selectedColor: AppColors.jade50,
        checkmarkColor: AppColors.jade500,
        side: const BorderSide(color: AppColors.slate300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: scheme.textPrimary),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.borderDefault,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.jade500,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 4,
        extendedTextStyle: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.bgSurface,
        selectedItemColor: AppColors.jade500,
        unselectedItemColor: scheme.textTertiary,
        selectedLabelStyle: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.beVietnamPro(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.jade500
                : AppColors.slate400),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.jade50
                : AppColors.slate100),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.textPrimary),
        contentTextStyle:
            GoogleFonts.beVietnamPro(fontSize: 14, color: scheme.textSecondary),
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const scheme = AppColorScheme.dark();

    // CALM OPERATIONS palette: primary = jadeText (light blue) làm bg,
    // text on primary = darkBg (dark canvas). KHÔNG dùng jadeMuted+white.
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.jadeText, // #B5D4DA — light, dùng làm BG button
      onPrimary: AppColors.darkBg, // #16252B — dark text trên primary
      primaryContainer: AppColors.jadeBg,
      onPrimaryContainer: AppColors.jadeText,
      secondary: AppColors.goldText,
      onSecondary: AppColors.darkBg,
      secondaryContainer: AppColors.goldBg,
      onSecondaryContainer: AppColors.goldText,
      tertiary: AppColors.coralText,
      onTertiary: AppColors.darkBg,
      tertiaryContainer: AppColors.coralBg,
      onTertiaryContainer: AppColors.coralText,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkContainer,
      surfaceContainerHigh: AppColors.darkElevated,
      error: AppColors.errorText,
      onError: AppColors.darkBg,
      errorContainer: AppColors.errorBgDark,
      onErrorContainer: AppColors.errorText,
      outline: AppColors.darkTextTertiary,
      outlineVariant: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: scheme.bgCanvas,
      extensions: const [AppThemeExtension(colors: scheme)],

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.bgSurface,
        foregroundColor: scheme.textBrand,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.textBrand),
        titleTextStyle: GoogleFonts.beVietnamPro(
          color: scheme.textBrand,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Buttons ─────────────────────────────────────────────────────────
      // CALM OPERATIONS: bg jadeText (#B5D4DA, light) + text darkBg (#16252B).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.jadeText,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.jadeText,
          foregroundColor: AppColors.darkBg,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.jadeText,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: const BorderSide(color: AppColors.jadeText, width: 1.5),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.jadeMuted,
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      // ── Input ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.jadeMuted, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.errorText),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.errorText, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 14, color: AppColors.darkTextSecondary),
        hintStyle:
            GoogleFonts.beVietnamPro(fontSize: 14, color: AppColors.darkHint),
        prefixIconColor: AppColors.darkHint,
        suffixIconColor: AppColors.darkHint,
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkContainer,
        selectedColor: AppColors.jadeBg,
        checkmarkColor: AppColors.jadeText,
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextPrimary),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      // FAB là widget duy nhất ĐƯỢC PHÉP có glow shadow trong calm operations.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.jadeText,
        foregroundColor: AppColors.darkBg,
        elevation: 4,
        extendedTextStyle: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.w700,
          color: AppColors.darkBg,
        ),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        selectedItemColor: AppColors.jadeText,
        unselectedItemColor: AppColors.darkTextTertiary,
        selectedLabelStyle: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.beVietnamPro(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Switch ──────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.jadeText
                : AppColors.darkTextTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.jadeBg
                : AppColors.darkContainer),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary),
        contentTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 14, color: AppColors.darkTextSecondary),
      ),

      // ── BottomSheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkElevated,
        modalBackgroundColor: AppColors.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: AppColors.darkBorder,
      ),

      // ── IconTheme ───────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),

      // ── ListTile ────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.darkTextPrimary,
        iconColor: AppColors.darkTextSecondary,
      ),

      // ── Popup Menu ──────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        textStyle: GoogleFonts.beVietnamPro(
            fontSize: 14, color: AppColors.darkTextPrimary),
      ),
    );
  }

  // ── Booking status color helper ──────────────────────────────────────────────
  static Color bookingStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HOLD':
        return AppColors.statusHold;
      case 'CONFIRMED':
        return AppColors.statusConfirmed;
      case 'CANCELLED':
        return AppColors.statusCancelled;
      case 'COMPLETED':
        return AppColors.statusCompleted;
      default:
        return AppColors.successBg;
    }
  }
}
