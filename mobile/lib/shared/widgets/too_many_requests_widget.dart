import 'package:flutter/material.dart';

class TooManyRequestsWidget extends StatelessWidget {
  final Duration retryAfter;
  final VoidCallback onRetry;

  const TooManyRequestsWidget({
    super.key,
    required this.retryAfter,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 40),
            const SizedBox(height: 8),
            Text(
              'Bạn thao tác quá nhanh. Vui lòng thử lại sau ${retryAfter.inSeconds}s.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
