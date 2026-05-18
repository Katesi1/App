import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_colors.dart';

enum TimelineStepStatus { done, current, pending }

class TimelineStep {
  final String title;
  final String? subtitle;
  final TimelineStepStatus status;

  const TimelineStep({
    required this.title,
    this.subtitle,
    required this.status,
  });
}

/// Vertical status timeline with a 1.5px rail on the left (signature pattern,
/// spec section 5.6 Pending Approval).
///
/// Calm operations rules:
/// - Done circle: bg successBorder, border 2px successText, check icon
/// - Current circle: bg goldBg, border 2px goldText, dot 8 inner (pulse)
/// - Pending circle: bg darkContainer, border 2px borderStrong, empty
class StatusTimeline extends StatelessWidget {
  final List<TimelineStep> steps;

  const StatusTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Vertical 1.5px rail at left 13 (center of the 28×28 icon).
          // Top/bottom inset 14 so the rail doesn't extend past the first icon.
          Positioned(
            left: 13.25,
            top: 28,
            bottom: 28,
            child: Container(
              width: 1.5,
              color: colors.borderDefault,
            ),
          ),
          Column(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _StepRow(step: steps[i]),
                if (i < steps.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final TimelineStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (titleColor, subtitleColor, fontWeight) = switch (step.status) {
      TimelineStepStatus.done => (
          colors.textPrimary,
          colors.success,
          FontWeight.w700
        ),
      TimelineStepStatus.current => (
          colors.textPrimary,
          colors.brandSecondary,
          FontWeight.w700
        ),
      TimelineStepStatus.pending => (
          colors.textTertiary,
          colors.textDisabled,
          FontWeight.w700
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepIcon(status: step.status),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: fontWeight,
                    color: titleColor,
                  ),
                ),
                if (step.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: step.status == TimelineStepStatus.pending
                          ? FontWeight.w500
                          : FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatefulWidget {
  final TimelineStepStatus status;
  const _StepIcon({required this.status});

  @override
  State<_StepIcon> createState() => _StepIconState();
}

class _StepIconState extends State<_StepIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.status == TimelineStepStatus.current) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StepIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == TimelineStepStatus.current && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.status != TimelineStepStatus.current &&
        _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final box = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: switch (widget.status) {
          TimelineStepStatus.done => AppColors.successBorder,
          TimelineStepStatus.current => AppColors.goldBg,
          TimelineStepStatus.pending => colors.bgSurfaceContainer,
        },
        border: Border.all(
          color: switch (widget.status) {
            TimelineStepStatus.done => colors.success,
            TimelineStepStatus.current => colors.brandSecondary,
            TimelineStepStatus.pending => colors.borderStrong,
          },
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: switch (widget.status) {
        TimelineStepStatus.done =>
          Icon(Icons.check, size: 14, color: colors.success),
        TimelineStepStatus.current => Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.brandSecondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        TimelineStepStatus.pending => const SizedBox.shrink(),
      },
    );

    if (widget.status != TimelineStepStatus.current) return box;

    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(_pulse),
      child: box,
    );
  }
}
