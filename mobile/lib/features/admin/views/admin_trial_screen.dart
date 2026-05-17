import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/admin_trial_controller.dart';
import '../data/models/trial_snapshot.dart';

class AdminTrialScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const AdminTrialScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  ConsumerState<AdminTrialScreen> createState() => _AdminTrialScreenState();
}

class _AdminTrialScreenState extends ConsumerState<AdminTrialScreen> {
  int _days = 30;
  String? _planId;
  String _cycle = 'monthly';
  int _rooms = 1;
  final _reasonCtrl = TextEditingController();
  final _revokeReasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _revokeReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final snapshotAsync =
        ref.watch(trialSnapshotProvider(widget.userId));
    final actionState = ref.watch(adminTrialNotifierProvider);
    final isBusy = actionState is AsyncLoading;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        children: [
          _Header(
            userName: widget.userName ?? snapshotAsync.valueOrNull?.userName,
          ),
          Expanded(
            child: snapshotAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(trialSnapshotProvider(widget.userId)),
              ),
              data: (snapshot) => _Body(
                snapshot: snapshot,
                days: _days,
                planId: _planId,
                cycle: _cycle,
                rooms: _rooms,
                reasonCtrl: _reasonCtrl,
                revokeReasonCtrl: _revokeReasonCtrl,
                isBusy: isBusy,
                onDaysChanged: (v) => setState(() => _days = v),
                onPlanChanged: (v) => setState(() => _planId = v),
                onCycleChanged: (v) => setState(() => _cycle = v),
                onRoomsChanged: (v) => setState(() => _rooms = v),
                onGrant: () => _handleGrant(snapshot),
                onRevoke: () => _handleRevoke(snapshot),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGrant(TrialSnapshot snapshot) async {
    final planToSend =
        snapshot.hasPlan ? snapshot.planId : _planId;
    if (!snapshot.hasPlan &&
        (planToSend == null || planToSend.isEmpty)) {
      AppSnackBar.error(context, 'Vui lòng chọn gói plan cho tài khoản mới');
      return;
    }

    final ok = await ref.read(adminTrialNotifierProvider.notifier).grant(
          userId: widget.userId,
          days: _days,
          planId: planToSend,
          cycle: _cycle,
          rooms: _rooms,
          reason: _reasonCtrl.text.trim().isEmpty
              ? null
              : _reasonCtrl.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      _reasonCtrl.clear();
      final msg = snapshot.hasActiveTrial ? 'Đã gia hạn trial' : 'Đã cấp trial';
      AppSnackBar.success(context, msg);
    } else {
      final err = ref.read(adminTrialNotifierProvider);
      if (err is AsyncError) {
        AppSnackBar.error(
          context,
          err.error.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _handleRevoke(TrialSnapshot snapshot) async {
    final reason = _revokeReasonCtrl.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _RevokeDialog(
        userName: snapshot.userName,
        reasonCtrl: _revokeReasonCtrl,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(adminTrialNotifierProvider.notifier).revoke(
          userId: widget.userId,
          reason: reason.isEmpty ? null : reason,
        );

    if (!mounted) return;
    if (ok) {
      _revokeReasonCtrl.clear();
      AppSnackBar.success(context, 'Đã thu hồi trial');
    } else {
      final err = ref.read(adminTrialNotifierProvider);
      if (err is AsyncError) {
        AppSnackBar.error(
          context,
          err.error.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String? userName;
  const _Header({this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.jade900, AppColors.jade500],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -50,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.jade300.withValues(alpha: 0.10),
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/admin/users');
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý Trial',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (userName != null && userName!.isNotEmpty)
                      Text(
                        userName!,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Free Trial',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final TrialSnapshot snapshot;
  final int days;
  final String? planId;
  final String _cycle;
  final int rooms;
  final TextEditingController reasonCtrl;
  final TextEditingController revokeReasonCtrl;
  final bool isBusy;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<String?> onPlanChanged;
  final ValueChanged<String> onCycleChanged;
  final ValueChanged<int> onRoomsChanged;
  final VoidCallback onGrant;
  final VoidCallback onRevoke;

  const _Body({
    required this.snapshot,
    required this.days,
    required this.planId,
    required String cycle,
    required this.rooms,
    required this.reasonCtrl,
    required this.revokeReasonCtrl,
    required this.isBusy,
    required this.onDaysChanged,
    required this.onPlanChanged,
    required this.onCycleChanged,
    required this.onRoomsChanged,
    required this.onGrant,
    required this.onRevoke,
  }) : _cycle = cycle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Subscription snapshot ────────────────────────────────
          _SnapshotCard(snapshot: snapshot),

          const SizedBox(height: AppSpacing.lg),

          // ── Grant / Extend Trial form ────────────────────────────
          _SectionTitle(
            icon: Icons.card_giftcard_rounded,
            label: snapshot.hasActiveTrial
                ? 'Gia hạn Trial'
                : 'Cấp Free Trial',
            color: colors.brand,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Days
          _FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Số ngày'),
                const SizedBox(height: 8),
                Row(
                  children: [30, 60, 90].map((d) {
                    final selected = days == d;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _DayChip(
                          days: d,
                          selected: selected,
                          onTap: () => onDaysChanged(d),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Plan — chỉ hiện nếu user chưa có plan
                if (!snapshot.hasPlan) ...[
                  const SizedBox(height: 16),
                  _FieldLabel('Gói plan *'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(planId),
                    initialValue: planId,
                    hint: const Text('Chọn gói'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: colors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: colors.borderDefault),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'starter', child: Text('Starter')),
                      DropdownMenuItem(
                          value: 'professional',
                          child: Text('Professional')),
                      DropdownMenuItem(
                          value: 'enterprise', child: Text('Enterprise')),
                    ],
                    onChanged: onPlanChanged,
                  ),
                ],

                // Cycle
                const SizedBox(height: 16),
                _FieldLabel('Chu kỳ'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ToggleChip(
                        label: 'Hàng tháng',
                        selected: _cycle == 'monthly',
                        onTap: () => onCycleChanged('monthly'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleChip(
                        label: 'Hàng năm',
                        selected: _cycle == 'yearly',
                        onTap: () => onCycleChanged('yearly'),
                      ),
                    ),
                  ],
                ),

                // Rooms
                const SizedBox(height: 16),
                _FieldLabel('Số phòng'),
                const SizedBox(height: 8),
                _RoomCounter(
                  value: rooms,
                  onChanged: onRoomsChanged,
                ),

                // Reason
                const SizedBox(height: 16),
                _FieldLabel('Lý do (tùy chọn)'),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'VD: Khuyến mãi ra mắt, hỗ trợ sự kiện...',
                    hintStyle: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: colors.textTertiary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colors.borderDefault),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Grant button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : onGrant,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.card_giftcard_rounded, size: 18),
              label: Text(
                snapshot.hasActiveTrial ? 'Gia hạn Trial' : 'Cấp Free Trial',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: colors.textOnPrimary,
                disabledBackgroundColor: colors.brand.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),

          // Revoke (chỉ khi đang có trial)
          if (snapshot.hasActiveTrial) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(
              icon: Icons.block_rounded,
              label: 'Thu hồi Trial',
              color: colors.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            _FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thu hồi sẽ kết thúc ngay trial hiện tại và đặt subscription về trạng thái "none". '
                    'Người dùng sẽ bị mất quyền quản lý phòng.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('Lý do thu hồi (tùy chọn)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: revokeReasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'VD: Vi phạm điều khoản, yêu cầu hoàn tiền...',
                      hintStyle: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.borderDefault),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : onRevoke,
                icon: const Icon(Icons.block_rounded, size: 18),
                label: Text(
                  'Thu hồi Trial',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Subscription Snapshot Card ───────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  final TrialSnapshot snapshot;
  const _SnapshotCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusInfo = _statusInfo(snapshot.subscriptionStatus);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: colors.brand.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusInfo.$2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusInfo.$1,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusInfo.$2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (snapshot.planId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _planLabel(snapshot.planId),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.brand,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: colors.borderDefault),
          const SizedBox(height: 12),

          // Info rows
          if (snapshot.trialEndsAt != null)
            _InfoRow(
              icon: Icons.timer_outlined,
              label: 'Trial kết thúc',
              value: fmt.format(snapshot.trialEndsAt!.toLocal()),
              valueColor: snapshot.hasActiveTrial
                  ? colors.success
                  : colors.textTertiary,
            ),
          if (snapshot.nextChargeAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.payment_outlined,
              label: 'Charge tiếp theo',
              value: fmt.format(snapshot.nextChargeAt!.toLocal()),
            ),
          ],
          if (snapshot.rooms != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.apartment_outlined,
              label: 'Số phòng',
              value: '${snapshot.rooms} phòng',
            ),
          ],
          if (snapshot.cycle != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.repeat_rounded,
              label: 'Chu kỳ',
              value: snapshot.cycle == 'yearly' ? 'Hàng năm' : 'Hàng tháng',
            ),
          ],
          if (snapshot.trialEndsAt == null &&
              snapshot.nextChargeAt == null &&
              snapshot.subscriptionStatus == 'none') ...[
            _InfoRow(
              icon: Icons.info_outline_rounded,
              label: 'Trạng thái',
              value: 'Chưa có subscription',
              valueColor: colors.textTertiary,
            ),
          ],
        ],
      ),
    );
  }

  static (String, Color) _statusInfo(String status) => switch (status) {
        'trial' => ('Đang Trial', AppColors.statusHold),
        'active' => ('Active', AppColors.statusConfirmed),
        'past_due' => ('Quá hạn', AppColors.statusCancelled),
        'cancelled' => ('Đã huỷ', AppColors.slate400),
        _ => ('Chưa có', AppColors.slate400),
      };

  static String _planLabel(String? planId) => switch (planId) {
        'starter' => 'Starter',
        'professional' => 'Professional',
        'enterprise' => 'Enterprise',
        _ => planId ?? '',
      };
}

// ─── Revoke confirmation dialog ───────────────────────────────────────────────

class _RevokeDialog extends StatelessWidget {
  final String userName;
  final TextEditingController reasonCtrl;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _RevokeDialog({
    required this.userName,
    required this.reasonCtrl,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Thu hồi Trial?',
        style: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành động này sẽ kết thúc ngay trial của $userName. '
            'Không thể hoàn tác.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Huỷ',
            style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            'Thu hồi',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderDefault),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final int days;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.days,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.brand
              : colors.brand.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? colors.brand
                : colors.brand.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              '$days',
              style: GoogleFonts.beVietnamPro(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : colors.brand,
              ),
            ),
            Text(
              'ngày',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : colors.brand.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                selected ? colors.brand : colors.borderDefault,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomCounter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RoomCounter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        _CounterBtn(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
          colors: colors,
        ),
        const SizedBox(width: 12),
        Text(
          '$value phòng',
          style: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        _CounterBtn(
          icon: Icons.add_rounded,
          onTap: value < 999 ? () => onChanged(value + 1) : null,
          colors: colors,
        ),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final AppColorScheme colors;

  const _CounterBtn({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? colors.brand.withValues(alpha: 0.1)
              : colors.borderDefault.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? colors.brand.withValues(alpha: 0.3)
                : colors.borderDefault,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colors.brand : colors.textTertiary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textTertiary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
