import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';

/// Stepper progress 4 segments dùng trên đầu mỗi screen verify.
///
/// Anatomy:
/// - 4 segments height 3px, gap 6px
/// - Active: fill brandLight (jadeMuted)
/// - Inactive: fill borderDefault
/// - Border-radius full (100) — chỉ hợp lệ cho progress bar segments,
///   KHÔNG dùng cho status pill (status pill dùng radius 4-6).
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
