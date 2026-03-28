import '../models/notification_model.dart';

class NotificationRepository {
  Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockNotifications;
  }

  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockNotifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _mockNotifications[index] =
          _mockNotifications[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockNotifications = _mockNotifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
  }

  // TODO: Kết nối API thật khi backend có endpoint /notifications

  static List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: '1',
      title: 'Booking mới — Phòng 201',
      subtitle: 'Nguyễn Thị Lan · 2 đêm · 19-21/3',
      type: NotificationType.booking,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      targetType: 'booking',
      targetId: 'b001',
    ),
    NotificationModel(
      id: '2',
      title: 'Thanh toán cọc — 2.400.000đ',
      subtitle: 'Villa Vĩnh Xanh · MoMo',
      type: NotificationType.payment,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      targetType: 'booking',
      targetId: 'b002',
    ),
    NotificationModel(
      id: '3',
      title: 'Check-in — Phòng 305',
      subtitle: 'Trần Văn Nam · 14:00 hôm nay',
      type: NotificationType.booking,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      targetType: 'booking',
      targetId: 'b003',
    ),
    NotificationModel(
      id: '4',
      title: 'Đồng bộ Booking.com',
      subtitle: '3 đêm mới được đồng bộ',
      type: NotificationType.system,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: '5',
      title: 'Huỷ booking — Phòng 102',
      subtitle: 'Lê Minh Hoàng · Hoàn cọc 1.3tr',
      type: NotificationType.booking,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      targetType: 'booking',
      targetId: 'b004',
    ),
    NotificationModel(
      id: '6',
      title: 'Thanh toán hoàn tất — 4.800.000đ',
      subtitle: 'Phòng 201 · Chuyển khoản VCB',
      type: NotificationType.payment,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      targetType: 'booking',
      targetId: 'b005',
    ),
    NotificationModel(
      id: '7',
      title: 'Bảo trì hệ thống',
      subtitle: 'Dự kiến 2:00 - 4:00 sáng mai',
      type: NotificationType.system,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
