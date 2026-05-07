import 'package:flutter/material.dart';

Future<void> showSoftUpdatePrompt(
  BuildContext context, {
  required String latestVersion,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Có bản cập nhật mới'),
      content: Text(
        'Phiên bản mới $latestVersion đã sẵn sàng. '
        'Bạn nên cập nhật để có trải nghiệm ổn định hơn.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cập nhật'),
        ),
      ],
    ),
  );
}
