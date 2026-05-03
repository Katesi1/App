import 'dart:async';

import 'package:flutter/material.dart';

import 'verify_format.dart';

/// Realtime countdown badge cho Trial Active screen.
///
/// Tự update mỗi 60s (đủ chính xác cho user). Dispose timer khi widget unmount.
class TrialCountdownText extends StatefulWidget {
  final DateTime trialEndsAt;
  final TextStyle? style;
  final String prefix;

  const TrialCountdownText({
    super.key,
    required this.trialEndsAt,
    this.style,
    this.prefix = 'TRIAL · ',
  });

  @override
  State<TrialCountdownText> createState() => _TrialCountdownTextState();
}

class _TrialCountdownTextState extends State<TrialCountdownText> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _update());
  }

  void _update() {
    if (!mounted) return;
    setState(() {
      _remaining = widget.trialEndsAt.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix}${VerifyFormat.countdown(_remaining)}',
      style: widget.style,
    );
  }
}
