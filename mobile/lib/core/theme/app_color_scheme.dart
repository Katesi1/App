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

  /// Dark mode — CALM OPERATIONS palette.
  ///
  /// Quy tắc QUAN TRỌNG (calm operations):
  /// - `brand` = `jadeText` (#B5D4DA, light blue) → dùng làm BG cho button primary,
  ///   text trên đó là `bgCanvas` (#16252B, dark). KHÔNG phải bg jadeBright/text white như v2 cũ.
  /// - `brandLight` = `jadeMuted` (#7AB5BD) → dùng cho icon, accent, link.
  /// - Status text dùng sage/mustard/rose, KHÔNG neon.
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
        textBrand = AppColors.jadeText, // #B5D4DA — text brand on dark
        textBrandAccent = AppColors.goldText, // #C9A567
        textBrandWarm = AppColors.coralText, // #C9A084
        textOnPrimary = AppColors.darkBg, // #16252B — text on jadeText button BG
        textOnSecondary = AppColors.darkBg,
        textOnCoral = AppColors.darkBg,
        borderSubtle = AppColors.darkDivider, // #243439
        borderDefault = AppColors.darkBorder, // #2A4147
        borderStrong = const Color(0xFF3A5258),
        borderBrand = AppColors.jadeMuted, // #7AB5BD
        borderGold = AppColors.goldMuted,
        borderCoral = AppColors.coralMuted,
        brand = AppColors.jadeText, // #B5D4DA — button primary BG
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
