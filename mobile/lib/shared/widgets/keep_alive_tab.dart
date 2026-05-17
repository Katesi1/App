import 'package:flutter/material.dart';

/// Wrapper giữ state subtree khi TabBarView swipe sang tab khác — tránh
/// reset scroll position + state nội tại (vd `_GroupTile._expanded`).
///
/// Dùng khi children của TabBarView là widget được build inline (không phải
/// class riêng có thể trực tiếp `with AutomaticKeepAliveClientMixin`).
///
/// ```dart
/// TabBarView(
///   children: tabs.map((t) => KeepAliveTab(child: _buildTab(t))).toList(),
/// )
/// ```
class KeepAliveTab extends StatefulWidget {
  final Widget child;

  const KeepAliveTab({super.key, required this.child});

  @override
  State<KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
