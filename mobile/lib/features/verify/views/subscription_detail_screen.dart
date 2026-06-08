import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/repositories/verify_repository_impl.dart';
import 'widgets/payment_dialogs.dart';
import 'widgets/verify_format.dart';

/// Subscription status, derived from the REAL backend profile (`/kyc/status`),
/// NOT the local picker draft — drives the hero card styling + which actions
/// to surface.
enum _SubKind { none, trial, active, pastDue, cancelled }

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({super.key});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  bool _renewing = false;

  /// Renew via VietQR bank transfer (the only supported method). Backend uses
  /// the user's current plan + cycle; the app only sends the method.
  Future<void> _handleRenew() async {
    setState(() => _renewing = true);
    try {
      final session = await ref
          .read(verifyFlowControllerProvider.notifier)
          .initiateRenewal(PaymentMethod.bankTransfer);
      if (!mounted) return;
      _openSessionDialog(session);
    } on VerifyApiException catch (e) {
      if (!mounted) return;
      if (e.isPaymentPending) {
        await _onRenewPaymentPending(e);
      } else if (e.isSubscriptionFrozen) {
        _snack('Gói đang tạm khoá. Vui lòng liên hệ hỗ trợ.', error: true);
      } else {
        _snack('Tạo phiên gia hạn thất bại: ${e.message}', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack(
        'Tạo phiên gia hạn thất bại: '
        '${e.toString().replaceAll('Exception: ', '')}',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _renewing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    error ? AppToast.error(context, msg) : AppToast.info(context, msg);
  }

  /// 409 `paymentPending` khi gia hạn — hỏi tiếp tục đợi (resume) hay huỷ & tạo
  /// lại.
  Future<void> _onRenewPaymentPending(VerifyApiException e) async {
    final pending = e.pendingSession;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đang có phiên chờ thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.message),
            if (pending != null) ...[
              const SizedBox(height: 10),
              Text(
                '${pending.planLabel ?? ''} · '
                '${VerifyFormat.priceVND(pending.totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (pending.expiresAt != null)
                Text('Hết hạn: ${VerifyFormat.dateVN(pending.expiresAt!)}',
                    style: TextStyle(
                        fontSize: 12, color: context.colors.textTertiary)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Huỷ phiên cũ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('wait'),
            child: const Text('Tiếp tục đợi'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'wait') {
      final active = await ref
          .read(verifyFlowControllerProvider.notifier)
          .getActivePayment();
      if (!mounted || active == null) return;
      _openSessionDialog(active);
    } else if (choice == 'cancel' && pending != null) {
      try {
        await ref
            .read(verifyFlowControllerProvider.notifier)
            .cancelPayment(pending.sessionId);
        if (!mounted) return;
        _handleRenew();
      } catch (err) {
        _snack('Huỷ phiên cũ thất bại: '
            '${err.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _openSessionDialog(PaymentSession session) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BankTransferDialog(
        session: session,
        onCloseAndWait: () {
          if (!mounted) return;
          AppToast.success(context,
              'Đã ghi nhận. Gói sẽ gia hạn khi hệ thống xác nhận chuyển khoản.');
        },
        onCreateNew: _handleRenew,
        // Abandon → confirm in-dialog, then void the pending bill server-side.
        onCancel: () async {
          await ref
              .read(verifyFlowControllerProvider.notifier)
              .cancelPayment(session.sessionId);
          if (!mounted) return;
          AppToast.info(context, 'Đã huỷ phiên chuyển khoản.');
          ref.invalidate(paymentHistoryProvider);
          ref.invalidate(paymentHistoryListProvider);
        },
      ),
    );
    // Refresh history after the user closes the dialog (assumption: admin
    // reconcile has or will update status). Don't poll here to keep logic simple.
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.invalidate(paymentHistoryProvider);
        ref.invalidate(paymentHistoryListProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);

    // Plan + cycle come from the REAL backend subscription (/kyc/status), not
    // the local picker draft — a leftover draft must never look like an owned
    // plan on a brand-new account.
    final tier = Plan.tierFromId(user?.subscriptionPlanId);
    final catalog =
        ref.watch(verifyPlansProvider).valueOrNull ?? const <Plan>[];
    final plan =
        tier == null ? null : PlanPriceCalculator.planFor(tier, catalog);
    final cycle = user?.subscriptionCycle == 'yearly'
        ? BillingCycle.yearly
        : BillingCycle.monthly;
    final price = plan == null ? 0 : PlanPriceCalculator.total(plan, cycle);

    final inTrial = user?.isInTrial ?? false;
    final isActive = user?.isSubscriptionActive ?? false;
    final isPastDue = user?.isSubscriptionPastDue ?? false;
    final isCancelled = user?.isSubscriptionCancelled ?? false;
    final hasActiveSub = isActive || isPastDue;

    final kind = switch (true) {
      _ when isPastDue => _SubKind.pastDue,
      _ when isCancelled => _SubKind.cancelled,
      _ when inTrial => _SubKind.trial,
      _ when isActive => _SubKind.active,
      _ => _SubKind.none,
    };

    final expiry = user?.currentPeriodEnd ??
        user?.subscriptionExpiresAt ??
        user?.trialEndsAt;
    final daysLeft = inTrial ? user?.trialDaysLeft : user?.subscriptionDaysLeft;

    // Price label for the hero — only when there's a real plan with a fixed
    // price (skip the "Chưa đăng ký" empty state).
    final priceLabel = (plan != null && plan.hasFixedPrice && tier != null)
        ? '${VerifyFormat.priceVND(price)}'
            '/${cycle == BillingCycle.yearly ? 'năm' : 'tháng'}'
        : null;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Chi tiết gói đăng ký'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Khi mở trực tiếp (deep link / context.go) không có stack cũ để pop
          // → fallback về trang quản lý thay vì kẹt không có nút back.
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/properties'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _StatusHero(
            kind: kind,
            tier: tier,
            cycle: cycle,
            daysLeft: daysLeft,
            expiry: expiry,
            priceLabel: priceLabel,
          ).animate().fadeIn(duration: 400.ms).slideY(
                begin: 0.06,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: AppSpacing.lg),

          // Scheduled downgrade (BE đã ghi pendingPlanId/EffectiveAt).
          if (user?.hasPendingDowngrade ?? false) ...[
            _PendingDowngradeBanner(
              planId: user!.pendingPlanId!,
              effectiveAt: user.pendingEffectiveAt,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Plan facts ─────────────────────────────────────────────
          if (plan != null) ...[
            _SectionLabel('CHI TIẾT GÓI'),
            const SizedBox(height: AppSpacing.sm),
            ..._buildFacts(colors, plan, cycle, price, expiry, kind, user)
                .animateList(),
            const SizedBox(height: AppSpacing.lg),
            if (plan.features.isNotEmpty) ...[
              _SectionLabel('TÍNH NĂNG'),
              const SizedBox(height: AppSpacing.sm),
              _FeatureCard(features: plan.features)
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 350.ms),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],

          // ── Actions ────────────────────────────────────────────────
          // VietQR bank-transfer lifecycle (Apple IAP removed):
          //  - No live plan → "Chọn gói" → select-plan → VietQR
          //  - Active/past_due → "Gia hạn ngay" (VietQR) + "Đổi gói"
          //  - Always → "Lịch sử thanh toán"
          ..._buildActions(context, colors, hasActiveSub, price)
              .animate()
              .fadeIn(delay: 320.ms, duration: 350.ms),
        ],
      ),
    );
  }

  List<Widget> _buildFacts(
    AppColorScheme colors,
    Plan plan,
    BillingCycle cycle,
    int price,
    DateTime? expiry,
    _SubKind kind,
    dynamic user,
  ) {
    final rooms = plan.tier.rooms;
    final statusLabel = switch (kind) {
      _SubKind.trial => 'Đang dùng thử',
      _SubKind.active => 'Đang hoạt động',
      _SubKind.pastDue => 'Quá hạn thanh toán',
      _SubKind.cancelled => 'Đã huỷ',
      _SubKind.none => 'Chưa đăng ký',
    };
    final periodStart = user?.currentPeriodStart as DateTime?;
    final nextCharge = user?.nextChargeAt as DateTime?;
    return [
      _DetailItem(
        icon: Icons.workspace_premium_rounded,
        label: 'Tên gói',
        value: plan.tier.displayName,
      ),
      _DetailItem(
        icon: Icons.verified_rounded,
        label: 'Trạng thái',
        value: statusLabel,
      ),
      _DetailItem(
        icon: Icons.meeting_room_rounded,
        label: 'Số phòng',
        value: rooms < 0 ? 'Không giới hạn' : '$rooms phòng',
      ),
      _DetailItem(
        icon: Icons.event_repeat_rounded,
        label: 'Chu kỳ',
        value: cycle == BillingCycle.yearly
            ? 'Hàng năm (cước năm)'
            : 'Hàng tháng (cước tháng)',
      ),
      _DetailItem(
        icon: Icons.payments_rounded,
        // "Giá niêm yết" (list price từ catalog) — KHÔNG phải số tiền thực thu.
        // Số tiền thật (prorate/override) do BE tính, hiện trong QR khi gia hạn.
        label: 'Giá niêm yết',
        value: plan.hasFixedPrice
            ? '${VerifyFormat.priceVND(price)}'
                '/${cycle == BillingCycle.yearly ? 'năm' : 'tháng'}'
            : 'Liên hệ',
      ),
      if (periodStart != null)
        _DetailItem(
          icon: Icons.play_circle_outline_rounded,
          label: 'Bắt đầu kỳ',
          value: VerifyFormat.dateVN(periodStart),
        ),
      if (expiry != null)
        _DetailItem(
          icon: Icons.schedule_rounded,
          label: kind == _SubKind.trial ? 'Trial đến' : 'Hết hạn kỳ',
          value: VerifyFormat.dateVN(expiry),
        ),
      if (nextCharge != null && kind != _SubKind.cancelled)
        _DetailItem(
          icon: Icons.event_available_rounded,
          label: 'Thu phí tiếp theo',
          value: VerifyFormat.dateVN(nextCharge),
        ),
    ];
  }

  List<Widget> _buildActions(
    BuildContext context,
    AppColorScheme colors,
    bool hasActiveSub,
    int price,
  ) {
    return [
      if (!hasActiveSub)
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: () => context.push('/verify/select-plan'),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Chọn gói đăng ký'),
          ),
        )
      else ...[
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _renewing ? null : _handleRenew,
            icon: _renewing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.autorenew_rounded, size: 18),
            // KHÔNG hiện số tiền local trên nút — số thật do BE tính, hiển thị
            // trong QR (renew response). Tránh chủ nhà thấy số lệch với thực thu.
            label: Text(_renewing ? 'Đang tạo phiên...' : 'Gia hạn ngay'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/verify/select-plan'),
            icon: const Icon(Icons.upgrade_rounded, size: 18),
            label: const Text('Đổi gói (nâng cấp/hạ cấp)'),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 46,
        child: OutlinedButton.icon(
          onPressed: () => context.push('/verify/payment-history'),
          icon: const Icon(Icons.receipt_long_outlined, size: 18),
          label: const Text('Lịch sử thanh toán'),
        ),
      ),
    ];
  }
}

// ─── Status hero ─────────────────────────────────────────────────────────────

class _StatusHero extends StatelessWidget {
  final _SubKind kind;
  final Tier? tier;
  final BillingCycle cycle;
  final int? daysLeft;
  final DateTime? expiry;
  final String? priceLabel;

  const _StatusHero({
    required this.kind,
    required this.tier,
    required this.cycle,
    required this.daysLeft,
    required this.expiry,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Per-kind styling: gradient, badge label, icon.
    final ({List<Color> grad, String badge, IconData icon}) s = switch (kind) {
      _SubKind.trial => (
          grad: [colors.brand, colors.brandLight],
          badge: 'ĐANG DÙNG THỬ',
          icon: Icons.rocket_launch_rounded,
        ),
      _SubKind.active => (
          grad: [colors.brand, colors.brandSecondary],
          badge: 'ĐANG HOẠT ĐỘNG',
          icon: Icons.verified_rounded,
        ),
      _SubKind.pastDue => (
          grad: [colors.error, Color.lerp(colors.error, Colors.black, 0.28)!],
          badge: 'QUÁ HẠN',
          icon: Icons.error_outline_rounded,
        ),
      _SubKind.cancelled => (
          grad: [colors.textTertiary, colors.textSecondary],
          badge: 'ĐÃ HUỶ',
          icon: Icons.pause_circle_outline_rounded,
        ),
      _SubKind.none => (
          grad: [colors.brand, colors.brandLight],
          badge: 'CHƯA ĐĂNG KÝ',
          icon: Icons.workspace_premium_outlined,
        ),
    };

    final title = switch (kind) {
      _SubKind.none => 'Chưa có gói đăng ký',
      _ => tier?.displayName ?? 'Gói đăng ký',
    };

    final subtitle = switch (kind) {
      _SubKind.none =>
        'Chọn gói để mở khoá quản lý phòng & booking không giới hạn.',
      _SubKind.trial => daysLeft != null
          ? 'Còn $daysLeft ngày dùng thử miễn phí.'
          : 'Bạn đang trong thời gian dùng thử.',
      _SubKind.active => expiry != null
          ? 'Gia hạn tự động vào ${VerifyFormat.dateVN(expiry!)}.'
          : 'Gói của bạn đang hoạt động.',
      _SubKind.pastDue => 'Thanh toán quá hạn — vui lòng gia hạn để tiếp tục.',
      _SubKind.cancelled => expiry != null
          ? 'Đã huỷ — còn dùng đến ${VerifyFormat.dateVN(expiry!)}.'
          : 'Gói đã bị huỷ.',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: s.grad,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: s.grad.first.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  s.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Icon(s.icon,
                  color: Colors.white.withValues(alpha: 0.9), size: 26),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          // Current fee — "đang dùng gói gì với cước bao nhiêu".
          if (priceLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payments_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    priceLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Trial progress bar (baseline 7 days).
          if (kind == _SubKind.trial && daysLeft != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (daysLeft! / 7).clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Detail row ──────────────────────────────────────────────────────────────

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textBrand),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature card ────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final List<String> features;
  const _FeatureCard({required this.features});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: features.asMap().entries.map((e) {
          final isLast = e.key == features.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 13, color: colors.success),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.textTertiary,
      ),
    );
  }
}

// Stagger helper — fade + slide each list item in sequence.
extension _AnimateList on List<Widget> {
  List<Widget> animateList() => asMap()
      .entries
      .map((e) => e.value
          .animate(delay: (80 + e.key * 70).ms)
          .fadeIn(duration: 320.ms)
          .slideX(begin: 0.04, end: 0, curve: Curves.easeOut))
      .toList();
}

/// Banner "đã đặt lịch hạ gói" — hiện khi `user.pendingPlanId != null`.
class _PendingDowngradeBanner extends StatelessWidget {
  final String planId;
  final DateTime? effectiveAt;

  const _PendingDowngradeBanner({required this.planId, this.effectiveAt});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final planName = Plan.tierFromId(planId)?.displayName ?? planId;
    final whenText = effectiveAt != null
        ? 'áp dụng từ ${VerifyFormat.dateVN(effectiveAt!)}'
        : 'áp dụng từ kỳ tiếp theo';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.trending_down_rounded, size: 20, color: colors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã đặt lịch hạ gói',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gói $planName sẽ $whenText. Tới lúc đó bạn vẫn dùng quyền lợi gói hiện tại.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
