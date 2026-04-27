import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Mapping color cụ thể cho từng theme (light + dark).
///
/// Truy cập trong widget: `context.colors.bgSurface`.
///
/// **Tại sao dùng `context.colors.x` thay vì `Theme.of(context).colorScheme.x`**:
/// Material 3 `ColorScheme` chỉ định nghĩa ~30 token cố định, không đủ cho
/// design system v2 vốn có `bgSurfaceElevated`, `textBrandWarm`, `borderCoral`,
/// `bgWarm` (limestone), v.v. `AppColorScheme` (gắn qua `ThemeExtension`) là
/// nguồn truth chính. `ColorScheme` chỉ giữ token mà Material widget mặc định
/// cần (Button, AppBar, InputDecoration).
///
/// **QA contrast (xem section 8.1 spec)**:
/// - `textBrandAccent` light = `gold700` (KHÔNG phải gold500 — gold500 fail 2.4 trên trắng).
/// - `textOnCoral` light = white. Chỉ áp dụng cho text ≥18px.
///   Pill/badge nhỏ → bg `coral50` + text `coral700` (không expose qua scheme,
///   vì khác semantic — dev phải chọn chủ động).
@immutable
class AppColorScheme {
  // ── Backgrounds ──
  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceContainer;
  final Color bgSurfaceElevated;
  final Color bgWarm;

  // ── Text ──
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

  // ── Borders ──
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderBrand;
  final Color borderGold;
  final Color borderCoral;

  // ── Brand ──
  final Color brand;
  final Color brandLight;
  final Color brandSecondary;
  final Color brandWarm;

  // ── Semantic ──
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

  const AppColorScheme.dark()
      : bgCanvas = AppColors.darkBg,
        bgSurface = AppColors.darkSurface,
        bgSurfaceContainer = AppColors.darkContainer,
        bgSurfaceElevated = AppColors.darkElevated,
        bgWarm = AppColors.darkSurface,
        textPrimary = AppColors.darkTextPrimary,
        textSecondary = AppColors.darkTextSecondary,
        textTertiary = AppColors.darkHint,
        textDisabled = AppColors.darkSubtext,
        textBrand = AppColors.jadeBright,
        textBrandAccent = AppColors.goldBright,
        textBrandWarm = AppColors.coralBright,
        textOnPrimary = AppColors.jade900,
        textOnSecondary = AppColors.gold900,
        textOnCoral = AppColors.coral900,
        borderSubtle = AppColors.darkDivider,
        borderDefault = AppColors.darkBorder,
        borderStrong = const Color(0xFF2A6F80),
        borderBrand = AppColors.jadeBright,
        borderGold = AppColors.goldBright,
        borderCoral = AppColors.coralBright,
        brand = AppColors.jadeBright,
        brandLight = AppColors.jade300,
        brandSecondary = AppColors.goldBright,
        brandWarm = AppColors.coralBright,
        success = AppColors.successDark,
        successBg = const Color(0x294ADE80),
        warning = AppColors.warningDark,
        warningBg = const Color(0x29FBBF24),
        error = AppColors.errorDark,
        errorBg = const Color(0x29F87171),
        info = AppColors.jadeBright;
}

/// ThemeExtension gắn `AppColorScheme` vào `ThemeData.extensions`.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppColorScheme colors;
  const AppThemeExtension({required this.colors});

  @override
  AppThemeExtension copyWith({AppColorScheme? colors}) =>
      AppThemeExtension(colors: colors ?? this.colors);

  // Hard-cut khi switch theme thay vì interpolate (lerp giữa 2 palette
  // sẽ ra màu lai không có ý nghĩa thiết kế).
  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) =>
      other == null ? this : (t < 0.5 ? this : other);
}

/// Extension trên `BuildContext`: dùng `context.colors.bgSurface`.
extension AppThemeContext on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppThemeExtension>()!.colors;
}
