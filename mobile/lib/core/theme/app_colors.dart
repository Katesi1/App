import 'package:flutter/material.dart';

/// Halong24h color tokens v2.0 — Jade Bay palette.
///
/// Tham chiếu spec: `halong24h-color-system-v2.md`.
///
/// QA notes (xem section 8.1 của spec):
/// - `gold500` (#E5B547) FAIL contrast 2.4 trên trắng → text gold luôn dùng `gold700`.
/// - White text trên `coral500` chỉ pass cho text ≥18px. Pill/badge nhỏ → bg `coral50` + text `coral700`.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════
  // BRAND — Jade (primary, brand identity, không đổi giữa light/dark)
  // ═══════════════════════════════════════════════════════════════
  static const jade50 = Color(0xFFE6F4F5);
  static const jade100 = Color(0xFFC9E5E8);
  static const jade200 = Color(0xFFA6D2D8);
  static const jade300 = Color(0xFF5BA8B5);
  static const jade500 = Color(0xFF0F5A6B); // MAIN
  static const jade700 = Color(0xFF0A3F4B);
  static const jade900 = Color(0xFF052830);

  // ═══════════════════════════════════════════════════════════════
  // BRAND — Gold (premium accent)
  // ═══════════════════════════════════════════════════════════════
  static const gold50 = Color(0xFFFEF9E8);
  static const gold100 = Color(0xFFFCEFC4);
  static const gold300 = Color(0xFFF4CD7A);
  static const gold500 = Color(0xFFE5B547); // MAIN — chỉ dùng làm bg/icon, KHÔNG dùng cho text trên trắng
  static const gold700 = Color(0xFFA8821F); // text gold trên light (contrast 4.7 ✓)
  static const gold900 = Color(0xFF5C4500);

  // ═══════════════════════════════════════════════════════════════
  // BRAND — Coral (warm accent — NEW v2)
  // ═══════════════════════════════════════════════════════════════
  static const coral50 = Color(0xFFFFEFE8);
  static const coral100 = Color(0xFFFED4C4);
  static const coral300 = Color(0xFFF7AB94);
  static const coral500 = Color(0xFFF2856B); // MAIN — white text chỉ pass khi ≥18px
  static const coral700 = Color(0xFFB85A3F); // text coral trên light (cho pill nhỏ)
  static const coral900 = Color(0xFF6B2B17);

  // ═══════════════════════════════════════════════════════════════
  // NEUTRAL — Slate scale (text, structure)
  // ═══════════════════════════════════════════════════════════════
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0); // border default
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B); // muted text
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155); // ink
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A); // navy strongest

  // Limestone (warm bg option — NEW v2)
  static const limestone50 = Color(0xFFFAF7F0);
  static const limestone100 = Color(0xFFF5EFE3);

  // ═══════════════════════════════════════════════════════════════
  // DARK MODE — Deep Jade base
  // ═══════════════════════════════════════════════════════════════
  static const darkBg = Color(0xFF0A1F26);
  static const darkSurface = Color(0xFF0F2F38);
  static const darkContainer = Color(0xFF143E48);
  static const darkElevated = Color(0xFF1A4D58);
  static const darkBorder = Color(0xFF1B5664);
  static const darkDivider = Color(0xFF143E48);
  static const darkHint = Color(0xFF8FB8C2);
  static const darkSubtext = Color(0xFF6F9AA5);
  static const darkTextPrimary = Color(0xFFE6F4F7);
  static const darkTextSecondary = Color(0xFFB5C9D0);

  // Bright accents on dark
  static const jadeBright = Color(0xFF5BCEDC);
  static const goldBright = Color(0xFFF4CD7A);
  static const coralBright = Color(0xFFF7AB94);

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC
  // ═══════════════════════════════════════════════════════════════
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFEAB308);
  static const warningBg = Color(0xFFFEF9C3);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEE2E2);
  static const info = jade500;

  // Dark variants
  static const successDark = Color(0xFF4ADE80);
  static const warningDark = Color(0xFFFBBF24);
  static const errorDark = Color(0xFFF87171);
  static const infoDark = jadeBright;

  // ═══════════════════════════════════════════════════════════════
  // STATUS — Booking
  // (Lưu ý: status booking giữ hex amber/emerald nguyên bản #F59E0B/#22C55E
  //  vì user đã quen pill màu này. Semantic warning/success thì dùng EAB308/16A34A.)
  // ═══════════════════════════════════════════════════════════════
  static const statusHold = Color(0xFFF59E0B);
  static const statusConfirmed = Color(0xFF22C55E);
  static const statusCancelled = Color(0xFFEF4444);
  static const statusCompleted = Color(0xFF7B1FA2);
  static const statusPending = jade500;

  static const statusHoldBg = Color(0xFFFEF3C7);
  static const statusConfirmedBg = Color(0xFFDCFCE7);
  static const statusCancelledBg = Color(0xFFFEE2E2);
  static const statusCompletedBg = Color(0xFFF3E8FF);
  static const statusPendingBg = jade50;

  // Dark variants
  static const statusHoldDark = Color(0xFFFBBF24);
  static const statusConfirmedDark = Color(0xFF4ADE80);
  static const statusCancelledDark = Color(0xFFF87171);
  static const statusCompletedDark = Color(0xFFC084FC);

  // ═══════════════════════════════════════════════════════════════
  // EXTRA accents (calendar weekday/holiday — giữ từ V1)
  // ═══════════════════════════════════════════════════════════════
  static const brownDark = Color(0xFF92400E);
  static const greenDark = Color(0xFF065F46);
  static const greenForest = Color(0xFF166534);
  static const purple = Color(0xFF7B1FA2);
  static const blueWeekday = Color(0xFF1976D2);
  static const orangeHoliday = Color(0xFFE65100);

  // ═══════════════════════════════════════════════════════════════
  // BACKWARD COMPAT (deprecated — sẽ xoá ở v2.1, sau 2 sprint)
  //
  // Mục đích: 46 file dùng AppColors.ocean/gold/teal/... vẫn compile.
  // Mỗi alias generate 1 analyzer warning để dev search-replace dần.
  // Đừng xoá block này cho đến khi `flutter analyze` không còn cảnh báo nào
  // về deprecated AppColors trong toàn codebase.
  // ═══════════════════════════════════════════════════════════════

  // Brand renames (visual sẽ shift sang V2 — đó là intent của migration)
  @Deprecated('Use AppColors.jade500 (or context.colors.brand). Will be removed in v2.1')
  static const ocean = jade500;
  @Deprecated('Use AppColors.jade300 (or context.colors.brandLight). Will be removed in v2.1')
  static const oceanMid = jade300;
  @Deprecated('Use AppColors.jade900. Will be removed in v2.1')
  static const oceanDeep = jade900;
  @Deprecated('Use AppColors.jade50. Will be removed in v2.1')
  static const oceanLight = jade50;
  @Deprecated('Use AppColors.jade50. Will be removed in v2.1')
  static const oceanPale = jade50;
  @Deprecated('Use AppColors.gold500 (or context.colors.brandSecondary). Will be removed in v2.1')
  static const gold = gold500;
  @Deprecated('Use AppColors.gold50. Will be removed in v2.1')
  static const goldLight = gold50;
  @Deprecated('Removed in v2 (was duplicate of jade300). Will be removed in v2.1')
  static const teal = jade300;
  @Deprecated('Use AppColors.jade100. Will be removed in v2.1')
  static const tealLight = jade100;
  @Deprecated('Use AppColors.jadeBright. Will be removed in v2.1')
  static const oceanBright = jadeBright;
  @Deprecated('Removed in v2 (was duplicate of jadeBright). Will be removed in v2.1')
  static const tealBright = jadeBright;

  // Aliases
  @Deprecated('Use AppColors.jade500. Will be removed in v2.1')
  static const primary = jade500;
  @Deprecated('Use AppColors.jade300. Will be removed in v2.1')
  static const primaryLight = jade300;
  @Deprecated('Use AppColors.jade900. Will be removed in v2.1')
  static const primaryDark = jade900;
  @Deprecated('Use AppColors.gold500. Will be removed in v2.1')
  static const secondary = gold500;
  @Deprecated('Use AppColors.gold50. Will be removed in v2.1')
  static const secondaryLight = gold50;

  // Neutrals
  @Deprecated('Use AppColors.slate900. Will be removed in v2.1')
  static const navy = slate900;
  @Deprecated('Use AppColors.slate800. Will be removed in v2.1')
  static const ink = slate800;
  @Deprecated('Use AppColors.slate500. Will be removed in v2.1')
  static const muted = slate500;
  @Deprecated('Use AppColors.slate400. Will be removed in v2.1')
  static const slate = slate400;
  @Deprecated('Use AppColors.slate100. Will be removed in v2.1')
  static const slateLight = slate100;
  @Deprecated('Use AppColors.slate200 (or context.colors.borderDefault). Will be removed in v2.1')
  static const border = slate200;
  @Deprecated('Use AppColors.slate200. Will be removed in v2.1')
  static const divider = slate200;
  @Deprecated('Use AppColors.slate50 (or context.colors.bgCanvas). Will be removed in v2.1')
  static const background = slate50;
  @Deprecated('Use AppColors.darkBg. Will be removed in v2.1')
  static const backgroundDark = darkBg;
  @Deprecated('Use Color(0xFFFFFFFF) directly or context.colors.bgSurface. Will be removed in v2.1')
  static const surface = Color(0xFFFFFFFF);
  @Deprecated('Use AppColors.darkSurface. Will be removed in v2.1')
  static const surfaceDark = darkSurface;

  // Semantic V1 names — CAUTION: V1 `coral` was the error red (#EF4444).
  // V2 reassigns "coral" to a peachy warm accent (coral500=#F2856B).
  // Để KHÔNG đổi ngẫu nhiên error badge thành cam, V1 `coral` giữ hex
  // gốc (alias sang `error`), không redirect sang `coral500`.
  @Deprecated('Use AppColors.error for errors, or AppColors.coral500 for warm accent. Will be removed in v2.1')
  static const coral = error;
  @Deprecated('Use AppColors.errorBg for errors, or AppColors.coral50 for warm accent. Will be removed in v2.1')
  static const coralLight = errorBg;
  @Deprecated('Use AppColors.success (note: hex shifted 22C55E → 16A34A). Will be removed in v2.1')
  static const emerald = success;
  @Deprecated('Use AppColors.successBg. Will be removed in v2.1')
  static const emeraldLight = successBg;
  @Deprecated('Use AppColors.warning (note: hex shifted F59E0B → EAB308). Will be removed in v2.1')
  static const amber = warning;
  @Deprecated('Use AppColors.warningBg. Will be removed in v2.1')
  static const amberLight = warningBg;

  // Booking status V1 names
  @Deprecated('Use AppColors.statusHold. Will be removed in v2.1')
  static const hold = statusHold;
  @Deprecated('Use AppColors.statusConfirmed. Will be removed in v2.1')
  static const confirmed = statusConfirmed;
  @Deprecated('Use AppColors.statusCancelled. Will be removed in v2.1')
  static const cancelled = statusCancelled;
  @Deprecated('Use AppColors.statusCompleted. Will be removed in v2.1')
  static const completed = statusCompleted;
  @Deprecated('Use AppColors.successBg. Will be removed in v2.1')
  static const available = successBg;

  // Room status V1 names
  @Deprecated('Use AppColors.success. Will be removed in v2.1')
  static const vacant = success;
  @Deprecated('Use AppColors.successBg. Will be removed in v2.1')
  static const vacantBg = successBg;
  @Deprecated('Use AppColors.statusHold. Will be removed in v2.1')
  static const booked = statusHold;
  @Deprecated('Use AppColors.statusHoldBg. Will be removed in v2.1')
  static const bookedBg = statusHoldBg;
  @Deprecated('Use AppColors.jade500. Will be removed in v2.1')
  static const occupied = jade500;
  @Deprecated('Use AppColors.jade50. Will be removed in v2.1')
  static const occupiedBg = jade50;
  @Deprecated('Use AppColors.slate400. Will be removed in v2.1')
  static const maintenance = slate400;
  @Deprecated('Use AppColors.slate100. Will be removed in v2.1')
  static const maintenanceBg = slate100;

  // Dark V1 names
  @Deprecated('Use AppColors.darkBg. Will be removed in v2.1')
  static const darkBackground = darkBg;
  @Deprecated('Use AppColors.errorDark. Will be removed in v2.1')
  static const darkError = errorDark;
  @Deprecated('Use AppColors.darkTextPrimary. Will be removed in v2.1')
  static const darkOnSurface = darkTextPrimary;
  @Deprecated('Use AppColors.gold700. Will be removed in v2.1')
  static const darkSecondaryContainer = gold700;
  @Deprecated('Use AppColors.gold50. Will be removed in v2.1')
  static const darkOnSecondaryContainer = gold50;
  @Deprecated('Use AppColors.darkBg. Will be removed in v2.1')
  static const darkGradientStart = darkBg;
  @Deprecated('Use AppColors.darkBorder. Will be removed in v2.1')
  static const darkGradientEnd = darkBorder;
}
