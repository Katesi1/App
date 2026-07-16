import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../../shared/widgets/status_strip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../verify/data/models/cccd_upload.dart';
import '../../verify/data/models/ocr_result.dart';
import '../../verify/data/models/verify_enums.dart';
import '../../verify/views/widgets/verify_format.dart';
import '../controllers/kyc_approval_controller.dart';
import '../data/models/kyc_submission.dart';

/// Admin KYC detail — preview submission + approve/reject.
///
/// Layout:
/// 1. Status banner (chỉ khi đã handled)
/// 2. Owner info card
/// 3. CCCD front (image + OCR data)
/// 4. CCCD back (image)
/// 5. Selfie (image + face match score)
/// 6. Subscription summary
/// 7. SLA / overdue warning
/// 8. Action bar (chỉ khi pending): "Từ chối" + "Phê duyệt"
class KYCApprovalDetailScreen extends ConsumerWidget {
  final String submissionId;

  const KYCApprovalDetailScreen({super.key, required this.submissionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(kycSubmissionProvider(submissionId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'Chi tiết KYC',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: colors.brand,
        onRefresh: () async =>
            ref.invalidate(kycSubmissionProvider(submissionId)),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => RefreshableMessage(
            child: Center(child: Text('Lỗi: $e')),
          ),
          data: (s) {
            if (s == null) {
              return const RefreshableMessage(
                child: Center(child: Text('Không tìm thấy hồ sơ.')),
              );
            }
            return _Content(submission: s);
          },
        ),
      ),
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  final KYCSubmission submission;
  const _Content({required this.submission});

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  /// Set các item user (admin) muốn reject (multi-select).
  final Set<RejectableItem> _rejectingItems = {};

  Future<void> _approve() async {
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bgSurfaceElevated,
        title: const Text('Phê duyệt hồ sơ?'),
        content: Text(
          'Owner ${widget.submission.ownerName} sẽ được kích hoạt trial 7 ngày '
          'và bắt đầu sử dụng full quyền quản lý.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Phê duyệt'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final adminName = ref.read(currentUserProvider)?.name ?? 'Admin';
    final success = await ref
        .read(kycApprovalActionsProvider.notifier)
        .approve(widget.submission.id, adminName: adminName);
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(context, 'Đã phê duyệt hồ sơ');
      Navigator.of(context).maybePop();
    } else {
      _showError('Phê duyệt thất bại');
    }
  }

  Future<void> _openRejectFlow() async {
    if (_rejectingItems.isEmpty) {
      _showError('Tích chọn ít nhất 1 item cần bổ sung trước khi từ chối');
      return;
    }
    final reason = await _promptReason();
    if (reason == null || reason.trim().isEmpty || !mounted) return;

    final adminName = ref.read(currentUserProvider)?.name ?? 'Admin';
    final success = await ref.read(kycApprovalActionsProvider.notifier).reject(
          widget.submission.id,
          adminName: adminName,
          reason: reason.trim(),
          items: _rejectingItems.toList(),
        );
    if (!mounted) return;
    if (success) {
      AppSnackBar.success(
        context,
        'Đã từ chối hồ sơ + gửi yêu cầu bổ sung cho owner',
      );
      Navigator.of(context).maybePop();
    } else {
      _showError('Từ chối thất bại');
    }
  }

  Future<String?> _promptReason() async {
    final colors = context.colors;
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bgSurfaceElevated,
        title: const Text('Lý do từ chối'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mô tả cụ thể để owner biết phải sửa gì.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'VD: Ảnh CCCD mặt trước bị mờ, không đọc được số...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text),
            child: const Text('Gửi từ chối'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    AppSnackBar.error(context, msg);
  }

  void _toggleReject(RejectableItem item, bool checked) {
    setState(() {
      if (checked) {
        _rejectingItems.add(item);
      } else {
        _rejectingItems.remove(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    final actionState = ref.watch(kycApprovalActionsProvider);

    return Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            s.isPending ? 120 : AppSpacing.md,
          ),
          children: [
            if (!s.isPending) _ResolvedBanner(submission: s),
            if (!s.isPending) const SizedBox(height: AppSpacing.md),
            if (s.isOverdue && s.isPending) ...[
              const _OverdueBanner(),
              const SizedBox(height: AppSpacing.md),
            ],
            _OwnerInfoCard(submission: s),
            const SizedBox(height: AppSpacing.md),
            _SectionLabel('CCCD MẶT TRƯỚC'),
            const SizedBox(height: 8),
            _CCCDFrontSection(
              upload: s.cccdFront,
              isRejectable: s.isPending,
              isRejected: _rejectingItems.contains(RejectableItem.cccdFront),
              onToggleReject: (v) => _toggleReject(RejectableItem.cccdFront, v),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionLabel('CCCD MẶT SAU'),
            const SizedBox(height: 8),
            _ImageOnlySection(
              upload: s.cccdBack,
              isRejectable: s.isPending,
              isRejected: _rejectingItems.contains(RejectableItem.cccdBack),
              onToggleReject: (v) => _toggleReject(RejectableItem.cccdBack, v),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionLabel('SELFIE FACE MATCH'),
            const SizedBox(height: 8),
            _SelfieSection(
              submission: s,
              isRejectable: s.isPending,
              isRejected: _rejectingItems.contains(RejectableItem.selfie),
              onToggleReject: (v) => _toggleReject(RejectableItem.selfie, v),
            ),
            const SizedBox(height: AppSpacing.md),
            _SubscriptionSection(submission: s),
          ],
        ),
        if (s.isPending)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ActionBar(
              loading: actionState.isLoading,
              hasRejectSelection: _rejectingItems.isNotEmpty,
              onApprove: _approve,
              onReject: _openRejectFlow,
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: colors.textTertiary,
      ),
    );
  }
}

class _ResolvedBanner extends StatelessWidget {
  final KYCSubmission submission;
  const _ResolvedBanner({required this.submission});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isApproved = submission.isApproved;
    final bg = isApproved ? AppColors.successBgDark : AppColors.errorBgDark;
    final border = isApproved ? AppColors.successBorder : AppColors.errorBorder;
    final fg = isApproved ? colors.success : colors.error;
    final icon = isApproved ? Icons.check : Icons.close;
    final title = isApproved ? 'Đã phê duyệt' : 'Đã từ chối';
    final handledAt = submission.handledAt;
    final subtitle = [
      if (submission.handledByAdmin != null) 'bởi ${submission.handledByAdmin}',
      if (handledAt != null)
        '· ${VerifyFormat.dateVN(handledAt)} ${VerifyFormat.time(handledAt)}',
    ].join(' ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
                if (submission.rejectReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${submission.rejectReason!}"',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner();

  @override
  Widget build(BuildContext context) {
    return const StatusStrip(
      icon: Icons.priority_high,
      label: 'Hồ sơ quá hạn 24h SLA',
      subtitle:
          'Owner đã chờ quá thời gian cam kết. Ưu tiên xử lý hoặc liên hệ owner để giải thích.',
      variant: StatusStripVariant.error,
    );
  }
}

class _OwnerInfoCard extends StatelessWidget {
  final KYCSubmission submission;
  const _OwnerInfoCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = submission;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.ownerName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.phone, value: s.ownerPhone),
          if (s.ownerEmail != null) ...[
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.mail_outline, value: s.ownerEmail!),
          ],
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.schedule,
            value:
                'Submit ${VerifyFormat.dateVN(s.submittedAt)} ${VerifyFormat.time(s.submittedAt)}',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 13, color: colors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CCCDFrontSection extends StatelessWidget {
  final CCCDUpload upload;
  final bool isRejectable;
  final bool isRejected;
  final ValueChanged<bool> onToggleReject;

  const _CCCDFrontSection({
    required this.upload,
    required this.isRejectable,
    required this.isRejected,
    required this.onToggleReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(
          color: isRejected ? colors.error : colors.borderDefault,
          width: isRejected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CCCDImage(url: upload.imageUrl, confidence: upload.confidence),
          if (upload.ocrResult != null) _OCRGrid(ocr: upload.ocrResult!),
          if (isRejectable)
            _RejectToggle(
              isRejected: isRejected,
              onChanged: onToggleReject,
            ),
        ],
      ),
    );
  }
}

class _ImageOnlySection extends StatelessWidget {
  final CCCDUpload upload;
  final bool isRejectable;
  final bool isRejected;
  final ValueChanged<bool> onToggleReject;

  const _ImageOnlySection({
    required this.upload,
    required this.isRejectable,
    required this.isRejected,
    required this.onToggleReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(
          color: isRejected ? colors.error : colors.borderDefault,
          width: isRejected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _CCCDImage(url: upload.imageUrl, confidence: upload.confidence),
          if (isRejectable)
            _RejectToggle(
              isRejected: isRejected,
              onChanged: onToggleReject,
            ),
        ],
      ),
    );
  }
}

class _CCCDImage extends StatelessWidget {
  final String url;
  final double confidence;

  const _CCCDImage({required this.url, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            memCacheWidth: 800,
            placeholder: (_, __) => Container(color: colors.bgSurfaceContainer),
            errorWidget: (_, __, ___) => Container(
              color: colors.bgSurfaceContainer,
              child: Icon(Icons.broken_image,
                  size: 48, color: colors.textTertiary),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: _ConfidencePill(confidence: confidence),
        ),
      ],
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final double confidence;
  const _ConfidencePill({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = (confidence * 100).round();
    final isLow = confidence < 0.8;
    final fg = isLow ? colors.warning : colors.success;
    final bg = isLow ? AppColors.warningBgDark : AppColors.successBgDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'OCR $pct%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
    );
  }
}

class _OCRGrid extends StatelessWidget {
  final OCRResult ocr;
  const _OCRGrid({required this.ocr});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fields = <(String, String?)>[
      ('Số CCCD', ocr.cccdNumber),
      ('Họ tên', ocr.fullName),
      ('Ngày sinh', ocr.dob),
      ('Giới tính', ocr.gender),
      ('HSD', ocr.expiryDate),
      ('Địa chỉ', ocr.address),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KẾT QUẢ OCR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          ...fields.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      f.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.$2 ?? '—',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfieSection extends StatelessWidget {
  final KYCSubmission submission;
  final bool isRejectable;
  final bool isRejected;
  final ValueChanged<bool> onToggleReject;

  const _SelfieSection({
    required this.submission,
    required this.isRejectable,
    required this.isRejected,
    required this.onToggleReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = submission.selfie;
    final score = (s.faceMatchScore * 100).round();
    final isLow = s.faceMatchScore < 0.85;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(
          color: isRejected ? colors.error : colors.borderDefault,
          width: isRejected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 180,
                child: CachedNetworkImage(
                  imageUrl: s.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 280,
                  placeholder: (_, __) =>
                      Container(color: colors.bgSurfaceContainer),
                  errorWidget: (_, __, ___) =>
                      Container(color: colors.bgSurfaceContainer),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FACE MATCH SCORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isLow ? colors.warning : colors.success,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLow
                            ? 'Dưới ngưỡng 85% — admin nên reject'
                            : 'Đạt ngưỡng (≥ 85%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isLow ? colors.warning : colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isRejectable)
            _RejectToggle(
              isRejected: isRejected,
              onChanged: onToggleReject,
            ),
        ],
      ),
    );
  }
}

class _RejectToggle extends StatelessWidget {
  final bool isRejected;
  final ValueChanged<bool> onChanged;

  const _RejectToggle({required this.isRejected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => onChanged(!isRejected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isRejected ? AppColors.errorBgDark : Colors.transparent,
          border: Border(
            top: BorderSide(color: colors.borderSubtle),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isRejected ? colors.error : Colors.transparent,
                border: Border.all(
                  color: isRejected ? colors.error : colors.borderStrong,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isRejected
                  ? Icon(Icons.check, size: 12, color: AppColors.darkBg)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRejected
                    ? 'Đã đánh dấu cần bổ sung'
                    : 'Tích để yêu cầu owner chụp lại item này',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isRejected ? colors.error : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  final KYCSubmission submission;
  const _SubscriptionSection({required this.submission});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GÓI ĐĂNG KÝ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            submission.planName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SubMetric(
                  label: 'SỐ PHÒNG',
                  value: '${submission.expectedRooms}',
                ),
              ),
              Container(width: 1, height: 32, color: colors.borderSubtle),
              Expanded(
                child: _SubMetric(
                  label: 'TIỀN TẠM GIỮ',
                  value: VerifyFormat.priceVND(submission.totalAmount),
                  highlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SubMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: highlight ? colors.textBrand : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool loading;
  final bool hasRejectSelection;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ActionBar({
    required this.loading,
    required this.hasRejectSelection,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onReject,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.error),
                  foregroundColor: colors.error,
                ),
                icon: const Icon(Icons.close, size: 16),
                label: Text(
                  hasRejectSelection ? 'Từ chối (đã chọn)' : 'Từ chối',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: loading ? null : onApprove,
                icon: loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.darkBg,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Phê duyệt'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
