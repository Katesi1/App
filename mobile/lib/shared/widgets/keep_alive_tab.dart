import 'package:flutter/material.dart';

/// Keeps a subtree's state alive when TabBarView swipes to another tab —
/// avoids resetting scroll position + internal state (e.g. `_GroupTile._expanded`).
///
/// Use this when TabBarView children are inline-built widgets (not their own
/// class that could `with AutomaticKeepAliveClientMixin` directly).
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
