import 'package:flutter/cupertino.dart';

/// Page transitions — dùng [CupertinoPage] để mọi trang push đều có cử chỉ
/// vuốt-cạnh-trái-để-back (interactive edge swipe-back), hoạt động trên cả
/// Android lẫn iOS (do [CupertinoRouteTransitionMixin] cung cấp, không phụ
/// thuộc platform).
///
/// 3 hàm dưới đây giữ nguyên tên + chữ ký cũ để router không phải đổi call-site;
/// tất cả cùng trả [CupertinoPage] (trượt ngang iOS-style + swipe-back). Cử chỉ
/// tự động vô hiệu khi trang là route gốc (không có gì để back) hoặc khi màn
/// đăng ký chặn pop (PopScope/onPopInvoked).

/// Điều hướng phân cấp (list → detail). Trượt ngang + swipe-back.
Page<T> horizontalPage<T>({
  required LocalKey key,
  required Widget child,
}) =>
    CupertinoPage<T>(key: key, child: child);

/// Trước là slide-up; nay dùng chung Cupertino để có swipe-back đồng nhất.
Page<T> slideUpPage<T>({
  required LocalKey key,
  required Widget child,
}) =>
    CupertinoPage<T>(key: key, child: child);

/// Trước là fade-scale (modal form); nay dùng chung Cupertino để có swipe-back.
Page<T> fadeScalePage<T>({
  required LocalKey key,
  required Widget child,
}) =>
    CupertinoPage<T>(key: key, child: child);
