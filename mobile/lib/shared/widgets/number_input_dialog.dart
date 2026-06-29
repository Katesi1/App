import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';

/// Dialog nhập 1 số nguyên dương — dùng cho các trường có giá trị lớn vượt
/// dải chip có sẵn (VD: số phòng ngủ, số nhà tắm/WC khi nhiều).
///
/// Có stepper −/+ và ô nhập trực tiếp. Trả về số đã nhập (trong [min]..[max]),
/// hoặc null nếu huỷ.
///
/// Lưu ý kỹ thuật:
/// - 2 nút hành động đặt trong `Row` + `Expanded` (KHÔNG dùng
///   `AlertDialog.actions` → tránh `OverflowBar` đo nút với width vô hạn, vốn
///   gây crash vì theme button có `minimumSize: Size(double.infinity, 52)`).
/// - Body là `StatefulWidget` tự sở hữu controller, dispose trong `State` →
///   tránh "TextEditingController used after disposed" khi dialog rebuild lúc
///   đóng.
Future<int?> showNumberInputDialog(
  BuildContext context, {
  required String title,
  required String hint,
  int? initial,
  IconData icon = Icons.tag_rounded,
  String? subtitle,
  int min = 1,
  int max = 999,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _NumberInputDialog(
      title: title,
      hint: hint,
      initial: initial,
      icon: icon,
      subtitle: subtitle,
      min: min,
      max: max,
    ),
  );
}

class _NumberInputDialog extends StatefulWidget {
  const _NumberInputDialog({
    required this.title,
    required this.hint,
    required this.icon,
    required this.min,
    required this.max,
    this.initial,
    this.subtitle,
  });

  final String title;
  final String hint;
  final IconData icon;
  final int min;
  final int max;
  final int? initial;
  final String? subtitle;

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int? get _value {
    final n = int.tryParse(_ctrl.text.trim());
    return (n != null && n >= widget.min && n <= widget.max) ? n : null;
  }

  void _step(int delta) {
    final current = int.tryParse(_ctrl.text.trim()) ?? 0;
    final next = (current + delta).clamp(widget.min, widget.max);
    _ctrl.text = '$next';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = _value;

    return Dialog(
      backgroundColor: colors.bgSurfaceElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon badge ──
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.brand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: colors.brand, size: 26),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Tiêu đề ──
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // ── Stepper: [−] [ số ] [+] ──
            Row(
              children: [
                _StepButton(
                    icon: Icons.remove_rounded, onTap: () => _step(-1)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => Navigator.pop(context, _value),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      isDense: true,
                      filled: true,
                      fillColor: colors.bgSurfaceContainer,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      hintStyle: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: colors.textTertiary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            BorderSide(color: colors.brand, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StepButton(icon: Icons.add_rounded, onTap: () => _step(1)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Hành động ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text('Huỷ',
                        style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: value == null
                        ? null
                        : () => Navigator.pop(context, value),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: colors.brand,
                      foregroundColor: colors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text('Xong',
                        style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút vuông −/+ cho stepper.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.brand.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: colors.brand, size: 22),
        ),
      ),
    );
  }
}
