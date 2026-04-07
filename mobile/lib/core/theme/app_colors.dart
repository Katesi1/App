import 'package:flutter/material.dart';

class AppColors {
  // Primary — Ocean blue (Hạ Long bay feel)
  static const ocean = Color(0xFF0A4F6E);
  static const oceanMid = Color(0xFF0D6E96);
  static const oceanDeep = Color(0xFF062D42);
  static const oceanLight = Color(0xFFE8F4FA);
  static const oceanPale = Color(0xFFF0F8FC);

  // Aliases cho theme system
  static const primary = ocean;
  static const primaryLight = oceanMid;
  static const primaryDark = oceanDeep;

  // Teal accent
  static const teal = Color(0xFF00B4D8);
  static const tealLight = Color(0xFFCAF0F8);

  // Gold premium accent
  static const gold = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFFDF6E3);

  // Secondary — gold
  static const secondary = gold;
  static const secondaryLight = goldLight;

  // Neutrals
  static const navy = Color(0xFF0F172A);
  static const ink = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const slate = Color(0xFF94A3B8);
  static const slateLight = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const background = Color(0xFFF8FAFC);
  static const backgroundDark = Color(0xFF0F172A);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E293B);
  static const divider = Color(0xFFE2E8F0);

  // Semantic
  static const emerald = Color(0xFF22C55E);
  static const emeraldLight = Color(0xFFDCFCE7);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);
  static const coral = Color(0xFFEF4444);
  static const coralLight = Color(0xFFFEE2E2);

  static const error = coral;
  static const warning = amber;
  static const success = emerald;
  static const info = oceanMid;

  // Booking status
  static const hold = Color(0xFFF59E0B);
  static const confirmed = Color(0xFF22C55E);
  static const cancelled = Color(0xFFEF4444);
  static const completed = Color(0xFF7B1FA2);
  static const available = Color(0xFFDCFCE7);

  // Room status colors
  static const vacant = emerald;
  static const vacantBg = emeraldLight;
  static const booked = amber;
  static const bookedBg = amberLight;
  static const occupied = oceanMid;
  static const occupiedBg = oceanLight;
  static const maintenance = slate;
  static const maintenanceBg = slateLight;

  // Semantic accent colors (previously hardcoded)
  static const brownDark = Color(0xFF92400E);
  static const greenDark = Color(0xFF065F46);
  static const greenForest = Color(0xFF166534);
  static const purple = Color(0xFF7B1FA2);
  static const blueWeekday = Color(0xFF1976D2);
  static const orangeHoliday = Color(0xFFE65100);

  // Dark theme specific colors
  static const darkSurface = Color(0xFF152231);       // card/surface
  static const darkBackground = Color(0xFF0C1823);    // scaffold bg
  static const darkContainer = Color(0xFF1C2E3F);     // elevated container
  static const darkElevated = Color(0xFF223347);      // modal/sheet
  static const darkBorder = Color(0xFF2B3F52);        // subtle borders
  static const darkDivider = Color(0xFF1F3245);       // dividers
  static const darkHint = Color(0xFF8FA8BC);          // placeholder/hint
  static const darkSubtext = Color(0xFF6B8BA4);       // secondary text
  static const darkTextPrimary = Color(0xFFE8F1F8);   // primary text on dark
  static const darkTextSecondary = Color(0xFFAAC0D2); // secondary text on dark
  static const darkError = Color(0xFFFF6B7A);
  static const darkOnSurface = Color(0xFFE8F1F8);
  static const darkSecondaryContainer = Color(0xFF3E2000);
  static const darkOnSecondaryContainer = Color(0xFFFFDDB3);
  static const oceanBright = Color(0xFF48C9F0);       // primary accent dark
  static const tealBright = Color(0xFF26D9C8);        // teal on dark
  static const goldBright = Color(0xFFD4AE5C);        // gold on dark
  static const darkGradientStart = Color(0xFF0C1823);
  static const darkGradientEnd = Color(0xFF1B3A4B);
}
