import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';

/// 4-segment stepper progress shown at the top of each verify screen.
///
/// Anatomy:
/// - 4 segments height 3px, gap 6px
/// - Active: fill brandLight (jadeMuted)
/// - Inactive: fill borderDefault
/// - Full border-radius (100) — only valid for progress-bar segments; do NOT
///   use for status pills (status pills use radius 4-6).
class StepperProgress extends StatelessWidget {
  final int currentStep; // 1-based (1, 2, 3, 4)
  final int totalSteps;

  const StepperProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: List.generate(totalSteps, (i) {
        final isActive = i < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
            height: 3,
            decoration: BoxDecoration(
              color: isActive ? colors.brandLight : colors.borderDefault,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }
}
