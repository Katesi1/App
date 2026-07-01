import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/vnd_input_formatter.dart';
import '../../data/models/booking_model.dart';

/// Kết quả dialog ghi nhận thanh toán. [amount] = null → để BE tự dùng
/// totalAmount/depositAmount. Dialog trả `null` (outer) nghĩa là huỷ.
class MarkPaidResult {
  final double? amount;
  const MarkPaidResult(this.amount);
}

/// Dialog cho OWNER/SALE ghi nhận tiền cọc/đủ tiền của KHÁCH
/// (`PATCH /bookings/:id/paid`). KHÔNG phải thanh toán gói subscription.
class MarkPaidDialog extends StatefulWidget {
  final BookingModel booking;
  const MarkPaidDialog({super.key, required this.booking});

  /// Mở dialog, trả [MarkPaidResult] khi xác nhận, `null` khi huỷ.
  static Future<MarkPaidResult?> show(
    BuildContext context,
    BookingModel booking,
  ) {
    return showDialog<MarkPaidResult>(
      context: context,
      builder: (_) => MarkPaidDialog(booking: booking),
    );
  }

  @override
  State<MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends State<MarkPaidDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final preset = widget.booking.totalAmount ?? widget.booking.depositAmount;
    _ctrl = TextEditingController(text: _format(preset));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _format(double? value) {
    if (value == null || value <= 0) return '';
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  double? _parse() {
    final digits = _ctrl.text.replaceAll('.', '').trim();
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  void _setPreset(double value) {
    _ctrl.text = _format(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final b = widget.booking;
    final isHold = b.status == BookingStatus.hold;

    return AlertDialog(
      title: const Text('Ghi nhận thanh toán'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số tiền khách đã trả (cọc hoặc đủ tiền phòng).',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [VndInputFormatter()],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Số tiền',
              suffixText: '₫',
              border: OutlineInputBorder(),
              isDense: true,
              helperText: 'Để trống = dùng tổng tiền hệ thống',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (b.depositAmount != null && b.depositAmount! > 0)
                ActionChip(
                  label:
                      Text('Cọc ${AppHelpers.formatPrice(b.depositAmount!)}'),
                  onPressed: () => _setPreset(b.depositAmount!),
                ),
              if (b.totalAmount != null && b.totalAmount! > 0)
                ActionChip(
                  label:
                      Text('Đủ tiền ${AppHelpers.formatPrice(b.totalAmount!)}'),
                  onPressed: () => _setPreset(b.totalAmount!),
                ),
            ],
          ),
          if (isHold) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: colors.info),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Booking sẽ tự chuyển sang Đã xác nhận.',
                    style: TextStyle(fontSize: 12, color: colors.info),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, MarkPaidResult(_parse())),
          child: const Text('Ghi nhận'),
        ),
      ],
    );
  }
}
