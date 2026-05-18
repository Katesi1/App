import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Concrete color mapping per theme (light + dark).
///
/// Access from a widget: `context.colors.bgSurface`.
///
/// **Why use `context.colors.x` instead of `Theme.of(context).colorScheme.x`**:
/// Material 3 `ColorScheme` only defines ~30 fixed tokens — not enough for
/// design system v2, which adds `bgSurfaceElevated`, `textBrandWarm`,
/// `borderCoral`, `bgWarm` (limestone), etc. `AppColorScheme` (attached via
/// `ThemeExtension`) is the source of truth. `ColorScheme` only keeps tokens
/// that default Material widgets need (Button, AppBar, InputDecoration).
///
/// **QA contrast (see spec section 8.1)**:
/// - `textBrandAccent` light = `gold700` (NOT gold500 — gold500 fails 2.4 on white).
/// - `textOnCoral` light = white. Only applies to text ≥18px.
///   Small pill/badge → bg `coral50` + text `coral700` (not exposed via the
///   scheme — different semantic; devs must opt in explicitly).
@immutable
class AppColorScheme {
  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceContainer;
  final Color bgSurfaceElevated;
  final Color bgWarm;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textBrand;
  final Color textBrandAccent;
  final Color textBrandWarm;
  final Color textOnPrimary;
  final Color textOnSecondary;
  final Color textOnCoral;

  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderBrand;
  final Color borderGold;
  final Color borderCoral;

  final Color brand;
  final Color brandLight;
  final Color brandSecondary;
  final Color brandWarm;

  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;

  const AppColorScheme.light()
      : bgCanvas = AppColors.slate50,
        bgSurface = const Color(0xFFFFFFFF),
        bgSurfaceContainer = AppColors.slate100,
        bgSurfaceElevated = const Color(0xFFFFFFFF),
        bgWarm = AppColors.limestone50,
        textPrimary = AppColors.slate900,
        textSecondary = AppColors.slate600,
        textTertiary = AppColors.slate500,
        textDisabled = AppColors.slate400,
        textBrand = AppColors.jade500,
        textBrandAccent = AppColors.gold700,
        textBrandWarm = AppColors.coral700,
        textOnPrimary = const Color(0xFFFFFFFF),
        textOnSecondary = const Color(0xFFFFFFFF),
        textOnCoral = const Color(0xFFFFFFFF),
        borderSubtle = AppColors.slate100,
        borderDefault = AppColors.slate200,
        borderStrong = AppColors.slate300,
        borderBrand = AppColors.jade500,
        borderGold = AppColors.gold500,
        borderCoral = AppColors.coral500,
        brand = AppColors.jade500,
        brandLight = AppColors.jade300,
        brandSecondary = AppColors.gold500,
        brandWarm = AppColors.coral500,
        success = AppColors.success,
        successBg = AppColors.successBg,
        warning = AppColors.warning,
        warningBg = AppColors.warningBg,
        error = AppColors.error,
        errorBg = AppColors.errorBg,
        info = AppColors.jade500;

  /// Dark mode — CALM OPERATIONS palette.
  ///
  /// IMPORTANT rules (calm operations):
  /// - `brand` = `jadeText` (#B5D4DA, light blue) → used as BG for primary buttons;
  ///   text on it is `bgCanvas` (#16252B, dark). NOT bg jadeBright/text white like old v2.
  /// - `brandLight` = `jadeMuted` (#7AB5BD) → used for icon, accent, link.
  /// - Status text uses sage/mustard/rose, NO neon.
  const AppColorScheme.dark()
      : bgCanvas = AppColors.darkBg, // #16252B
        bgSurface = AppColors.darkSurface, // #1E343A
        bgSurfaceContainer = AppColors.darkContainer, // #243439
        bgSurfaceElevated = AppColors.darkElevated, // #243B42
        bgWarm = AppColors.darkSurface,
        textPrimary = AppColors.darkTextPrimary, // #D6DDE0
        textSecondary = AppColors.darkTextSecondary, // #A8B0B4
        textTertiary = AppColors.darkTextTertiary, // #8FB0B8
        textDisabled = AppColors.darkDisabled, // #6A7378
        textBrand = AppColors.jadeText, // #B5D4DA — brand text on dark
        textBrandAccent = AppColors.goldText, // #C9A567
        textBrandWarm = AppColors.coralText, // #C9A084
        textOnPrimary =
            AppColors.darkBg, // #16252B — text on the jadeText button BG
        textOnSecondary = AppColors.darkBg,
        textOnCoral = AppColors.darkBg,
        borderSubtle = AppColors.darkDivider, // #243439
        borderDefault = AppColors.darkBorder, // #2A4147
        borderStrong = const Color(0xFF3A5258),
        borderBrand = AppColors.jadeMuted, // #7AB5BD
        borderGold = AppColors.goldMuted,
        borderCoral = AppColors.coralMuted,
        brand = AppColors.jadeText, // #B5D4DA — primary button BG
        brandLight = AppColors.jadeMuted, // #7AB5BD — icon/accent
        brandSecondary = AppColors.goldText,
        brandWarm = AppColors.coralText,
        success = AppColors.successText, // sage #6FA88B
        successBg = AppColors.successBgDark, // #1F3A2D
        warning = AppColors.warningText, // mustard #C9A567
        warningBg = AppColors.warningBgDark, // #2A2419
        error = AppColors.errorText, // rose #C97A6F
        errorBg = AppColors.errorBgDark, // #3A2421
        info = AppColors.jadeMuted;
}

/// ThemeExtension that attaches `AppColorScheme` to `ThemeData.extensions`.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppColorScheme colors;
  const AppThemeExtension({required this.colors});

  @override
  AppThemeExtension copyWith({AppColorScheme? colors}) =>
      AppThemeExtension(colors: colors ?? this.colors);

  // Hard-cut on theme switch instead of interpolating (lerping between two
  // palettes produces hybrid colors with no design meaning).
  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) =>
      other == null ? this : (t < 0.5 ? this : other);
}

/// Extension on `BuildContext`: use `context.colors.bgSurface`.
extension AppThemeContext on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppThemeExtension>()?.colors ??
      const AppColorScheme.light();
}
