import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// iOS chỉ hỗ trợ vuốt-trái-để-quay-lại (edge back swipe) khi route dùng
/// [CupertinoPage] (hoặc MaterialPage với CupertinoPageTransitionsBuilder).
/// `CustomTransitionPage` KHÔNG bật cử chỉ này → mọi màn hình con phải dùng
/// [CupertinoPage] trên iOS. Android giữ nguyên transition tuỳ biến.
bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

/// Horizontal shared-axis (list → sub-list level).
/// iOS: [CupertinoPage] để có cử chỉ vuốt-quay-lại native.
Page<T> horizontalPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  if (_isIOS) {
    return CupertinoPage<T>(key: key, child: child);
  }
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animation, secondaryAnimation, c) =>
        SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      child: c,
    ),
  );
}

/// Vertical slide-up (detail screens, calendar).
/// iOS: [CupertinoPage] để có cử chỉ vuốt-quay-lại native.
Page<T> slideUpPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  if (_isIOS) {
    return CupertinoPage<T>(key: key, child: child);
  }
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, secondaryAnimation, c) =>
        SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.vertical,
      child: c,
    ),
  );
}

/// Fade-scale (modal forms sliding up from bottom).
/// iOS: [CupertinoPage] để có cử chỉ vuốt-quay-lại native.
Page<T> fadeScalePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  if (_isIOS) {
    return CupertinoPage<T>(key: key, child: child);
  }
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, animation, secondaryAnimation, c) =>
        FadeScaleTransition(animation: animation, child: c),
  );
}
