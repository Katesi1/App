import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// Label cho field bắt buộc: phần chữ giữ nguyên style, dấu `*` ở cuối tô đỏ.
///
/// Nếu [text] không kết thúc bằng `*`, render như [Text] thường — nên có thể
/// dùng thay thế trực tiếp cho mọi `Text(label)` của label/title field.
///
/// Dùng cho mọi label/title field required thay vì gắn ` *` cùng màu với chữ.
class RequiredLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const RequiredLabel(this.text, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trimRight();
    if (!trimmed.endsWith('*')) {
      return Text(text, style: style, textAlign: textAlign);
    }
    final base = trimmed.substring(0, trimmed.length - 1).trimRight();
    final asteriskStyle =
        (style ?? const TextStyle()).copyWith(color: context.colors.error);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: '$base '),
          TextSpan(text: '*', style: asteriskStyle),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
