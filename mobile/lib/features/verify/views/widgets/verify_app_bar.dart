import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import 'stepper_progress.dart';

/// Custom AppBar for the verify flow screens.
///
/// Anatomy:
/// - Back button 32×32, bg darkContainer, icon textTertiary, radius 8
/// - Overline 10px w700 letter-spacing 0.5 — "STEP X/Y · Verify CCCD"
/// - Title 14px w700 textPrimary
/// - 4-segment stepper progress below (when currentStep is provided)
class VerifyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String overline;
  final String title;
  final int? currentStep;
  final int totalSteps;
  final VoidCallback? onBack;

  const VerifyAppBar({
    super.key,
    required this.overline,
    required this.title,
    this.currentStep,
    this.totalSteps = 4,
    this.onBack,
  });

  @override
  Size get preferredSize => Size.fromHeight(currentStep != null ? 96 : 76);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.bgSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BackButton(
                    onTap: onBack ??
                        () {
                          // Verify flow is usually entered via pushReplacement
                          // so the stack may be empty. Fall back to /dashboard.
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/dashboard');
                          }
                        },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overline,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: colors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (currentStep != null) ...[
                const SizedBox(height: AppSpacing.sm + 2),
                StepperProgress(
                  currentStep: currentStep!,
                  totalSteps: totalSteps,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_back,
          size: 18,
          color: colors.textTertiary,
        ),
      ),
    );
  }
}
