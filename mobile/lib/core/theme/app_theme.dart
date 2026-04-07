import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

export 'app_colors.dart';
export 'app_spacing.dart';

// ─── Text Themes ───────────────────────────────────────────────────────────────
TextTheme _buildTextTheme({Color? bodyColor, Color? displayColor}) {
  final base = TextTheme(
    displayLarge: GoogleFonts.beVietnamPro(
        fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: GoogleFonts.beVietnamPro(
        fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: GoogleFonts.beVietnamPro(
        fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: GoogleFonts.beVietnamPro(
        fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.beVietnamPro(
        fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall: GoogleFonts.beVietnamPro(
        fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.beVietnamPro(
        fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.beVietnamPro(
        fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.beVietnamPro(
        fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.beVietnamPro(
        fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: GoogleFonts.beVietnamPro(
        fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: GoogleFonts.beVietnamPro(
        fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.beVietnamPro(
        fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: GoogleFonts.beVietnamPro(
        fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.beVietnamPro(
        fontSize: 11, fontWeight: FontWeight.w500),
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
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ocean,
      onPrimary: Colors.white,
      primaryContainer: AppColors.oceanLight,
      onPrimaryContainer: AppColors.oceanDeep,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: Color(0xFF3E2000),
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.slateLight,
      error: AppColors.coral,
      onError: Colors.white,
      outline: AppColors.slate,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ocean,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.beVietnamPro(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ocean,
          foregroundColor: Colors.white,
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
          foregroundColor: AppColors.ocean,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.oceanMid, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.coral, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 14, color: AppColors.muted),
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: AppColors.slate,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slateLight,
        selectedColor: AppColors.oceanLight,
        checkmarkColor: AppColors.ocean,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: AppColors.ink),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.ocean,
        foregroundColor: Colors.white,
        elevation: 4,
        extendedTextStyle: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.ocean,
        unselectedItemColor: AppColors.slate,
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
                ? AppColors.ocean
                : AppColors.slate),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.oceanLight
                : AppColors.slateLight),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy),
        contentTextStyle: GoogleFonts.beVietnamPro(
            fontSize: 14, color: AppColors.muted),
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.oceanBright,
      onPrimary: AppColors.darkBackground,
      primaryContainer: Color(0xFF0D3348),
      onPrimaryContainer: AppColors.tealLight,
      secondary: AppColors.goldBright,
      onSecondary: AppColors.darkBackground,
      secondaryContainer: Color(0xFF3D2A00),
      onSecondaryContainer: Color(0xFFFFDDB3),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkContainer,
      surfaceContainerHigh: AppColors.darkElevated,
      error: AppColors.darkError,
      onError: AppColors.darkBackground,
      outline: AppColors.darkSubtext,
      outlineVariant: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: GoogleFonts.beVietnamPro(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Buttons ─────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.oceanBright,
          foregroundColor: AppColors.darkBackground,
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
          backgroundColor: AppColors.oceanBright,
          foregroundColor: AppColors.darkBackground,
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
          foregroundColor: AppColors.oceanBright,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.oceanBright,
          textStyle: GoogleFonts.beVietnamPro(
              fontSize: 14, fontWeight: FontWeight.w600),
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
          borderSide:
              const BorderSide(color: AppColors.oceanBright, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: AppColors.darkError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 14, color: AppColors.darkTextSecondary),
        hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 14, color: AppColors.darkHint),
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
        selectedColor: const Color(0xFF0D3348),
        checkmarkColor: AppColors.oceanBright,
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.oceanBright,
        foregroundColor: AppColors.darkBackground,
        elevation: 4,
        extendedTextStyle: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.w600,
          color: AppColors.darkBackground,
        ),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.oceanBright,
        unselectedItemColor: AppColors.darkSubtext,
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
                ? AppColors.oceanBright
                : AppColors.darkSubtext),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? const Color(0xFF0D3348)
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
        return AppColors.hold;
      case 'CONFIRMED':
        return AppColors.confirmed;
      case 'CANCELLED':
        return AppColors.cancelled;
      case 'COMPLETED':
        return AppColors.completed;
      default:
        return AppColors.available;
    }
  }
}
