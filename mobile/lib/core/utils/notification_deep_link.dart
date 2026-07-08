/// Dịch push FCM của backend → route GoRouter trong app.
///
/// Backend gửi `data.type` (pushType) + `data.deepLink` + `data.targetId`.
/// `deepLink` dùng path của **web frontend** (`/host/...`, `/my-bookings`,
/// `/dashboard/billing`) — KHÔNG khớp router app này. Hàm dưới ưu tiên map theo
/// `pushType` (đáng tin, lấy id từ `targetId`), fallback dịch một vài path web
/// đã biết, cuối cùng về danh sách thông báo (`/notifications`) — mọi sự kiện
/// (trừ chat) đều tạo 1 row ở đó nên user vẫn tới được nội dung.
library;

/// Fallback khi push không map được đích cụ thể.
const String _fallbackRoute = '/notifications';

/// Route đích trong app cho một push. Trả `null` nếu không nên điều hướng
/// (payload không có type lẫn deepLink dùng được).
String? resolveNotificationRoute(Map<String, dynamic> data) {
  final pushType = _stringOf(data['type'] ?? data['pushType']);
  final targetId = _stringOf(data['targetId']);
  final deepLink = _stringOf(data['deepLink']);

  if (pushType == null && (deepLink == null || deepLink.isEmpty)) return null;

  // 1) Ưu tiên map theo pushType (bao trùm mọi loại BE đang gửi).
  final byType = _routeForType(pushType, targetId, deepLink);
  if (byType != null) return byType;

  // 2) Type lạ → dịch các path web đã biết sang route app.
  final byPath = _rewriteWebPath(deepLink);
  if (byPath != null) return byPath;

  // 3) Không khớp gì → về danh sách thông báo trong app.
  return _fallbackRoute;
}

String? _routeForType(String? type, String? targetId, String? deepLink) {
  if (type == null) return null;

  // id cơ sở: ưu tiên targetId, nếu không thì lấy segment cuối của deepLink.
  final id = _safeId(targetId) ?? _safeId(_lastSegment(deepLink));

  return switch (type) {
    'kyc_approved' => '/dashboard',
    'kyc_rejected' => '/verify/rejected',
    'bank_approved' || 'bank_rejected' => '/profile/bank-account',
    'payment_succeeded' => '/dashboard',
    'staff_removed' => '/login',
    'trial_granted' || 'trial_revoked' => '/verify/subscription-detail',
    'chat_message' => id != null ? '/conversations/$id' : _fallbackRoute,
    'booking_created' ||
    'booking_confirmed' ||
    'booking_paid' ||
    'booking_cancelled' =>
      '/bookings',
    'property_approved' ||
    'property_rejected' ||
    'property_suspended' ||
    'property_updated' ||
    'property_price_updated' ||
    'property_images_updated' ||
    'calendar_locked' ||
    'calendar_unlocked' ||
    'calendar_sold' ||
    'calendar_bulk_locked' ||
    'calendar_bulk_unlocked' =>
      id != null ? '/properties/$id' : '/properties',
    _ when type.startsWith('subscription') => '/verify/subscription-detail',
    // Type admin-only / chưa có route (bank_submitted, property_pending_review,
    // lead_new, dispute_*, staff_invite_accepted...) → về /notifications ở bước
    // fallback.
    _ => null,
  };
}

/// Dịch một số path web BE đã biết sang route app khi thiếu/không nhận ra
/// pushType. Chỉ pass-through các path chắc chắn tồn tại trong router.
String? _rewriteWebPath(String? deepLink) {
  if (deepLink == null || deepLink.isEmpty) return null;
  final uri = Uri.tryParse(deepLink);
  // Chỉ nhận relative path (chống open-redirect từ push giả mạo).
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  final segs = uri.pathSegments;
  if (segs.isEmpty) return null;

  return switch (segs) {
    ['dashboard', 'billing'] => '/verify/subscription-detail',
    ['host', 'settings', 'bank'] => '/profile/bank-account',
    ['host', 'properties', final id] when _safeId(id) != null =>
      '/properties/$id',
    ['host', 'bookings', ...] || ['my-bookings'] => '/bookings',
    _ when _isKnownAppRoute(uri.path) => uri.path,
    _ => null,
  };
}

/// Whitelist prefix route chắc chắn có trong app_router.dart — cho phép deeplink
/// đã đúng dạng app đi thẳng. KHÔNG gồm `/admin` (nhiều subpath admin BE gửi
/// không tồn tại → để rơi về /notifications thay vì trang lỗi).
const List<String> _knownAppRoutePrefixes = <String>[
  '/dashboard',
  '/login',
  '/notifications',
  '/conversations/',
  '/verify/',
  '/rooms',
  '/properties',
  '/calendar',
  '/reports',
  '/profile',
];

bool _isKnownAppRoute(String path) =>
    _knownAppRoutePrefixes.any((p) => path == p || path.startsWith(p));

/// Chấp nhận id an toàn (chữ/số/`-`/`_`) — chặn path injection qua targetId.
String? _safeId(String? value) {
  if (value == null || value.isEmpty) return null;
  return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value) ? value : null;
}

String? _lastSegment(String? deepLink) {
  if (deepLink == null || deepLink.isEmpty) return null;
  final segs = Uri.tryParse(deepLink)?.pathSegments ?? const [];
  return segs.isEmpty ? null : segs.last;
}

String? _stringOf(Object? v) {
  if (v == null) return null;
  final s = v is String ? v : v.toString();
  return s.isEmpty ? null : s;
}
