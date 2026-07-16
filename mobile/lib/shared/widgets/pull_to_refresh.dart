import 'package:flutter/material.dart';

/// Bọc widget "tĩnh" (empty / error) để vẫn kéo-làm-mới được khi đặt trong
/// nhánh của [AsyncValue.when] bên trong một [RefreshIndicator].
///
/// Vấn đề: [EmptyStateWidget]/[ErrorStateWidget] không cuộn được nên gesture
/// vuốt xuống không kích hoạt refresh khi danh sách rỗng hoặc lỗi. Widget này
/// cho nội dung fill hết viewport + [AlwaysScrollableScrollPhysics] để luôn
/// kéo được ở mọi state.
///
/// Dùng:
/// ```dart
/// RefreshIndicator(
///   onRefresh: () async => ref.invalidate(fooProvider),
///   child: async.when(
///     data: (items) => items.isEmpty
///         ? const RefreshableMessage(child: EmptyStateWidget(...))
///         : ListView(physics: const AlwaysScrollableScrollPhysics(), ...),
///     loading: () => const SkeletonList(...),
///     error: (e, _) => RefreshableMessage(child: ErrorStateWidget(...)),
///   ),
/// )
/// ```
class RefreshableMessage extends StatelessWidget {
  final Widget child;

  const RefreshableMessage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}
