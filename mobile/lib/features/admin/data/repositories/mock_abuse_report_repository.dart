import '../models/abuse_report.dart';
import 'abuse_report_repository.dart';

/// Mock queue cho QA — thay bằng real impl khi BE expose `/admin/abuse-reports`.
class MockAbuseReportRepository implements AbuseReportRepository {
  MockAbuseReportRepository() {
    _seed();
  }

  final List<AbuseReport> _items = [];

  void _seed() {
    _items.addAll([
      AbuseReport(
        id: 'report_001',
        title: 'Tin đăng spam phòng giả',
        description: 'Phòng không tồn tại, ảnh lấy từ Google. '
            'Người bán yêu cầu chuyển khoản trước khi xem phòng.',
        reporterId: 'user_172',
        reporterName: 'Nguyễn Văn A',
        level: AbuseReportLevel.high,
        category: AbuseReportCategory.spam,
        status: AbuseReportStatus.pending,
        targetType: AbuseTargetType.property,
        targetId: 'room_548',
        targetLabel: 'Villa Hạ Long View (giả)',
        createdAt: DateTime(2026, 5, 6, 14, 30),
      ),
      AbuseReport(
        id: 'report_002',
        title: 'Nội dung không phù hợp',
        description:
            'Mô tả phòng chứa ngôn từ thô tục và hình ảnh không liên quan.',
        reporterId: 'user_816',
        reporterName: 'Trần Thị B',
        level: AbuseReportLevel.medium,
        category: AbuseReportCategory.content,
        status: AbuseReportStatus.pending,
        targetType: AbuseTargetType.property,
        targetId: 'room_312',
        targetLabel: 'Homestay Bãi Cháy',
        createdAt: DateTime(2026, 5, 5, 9, 15),
      ),
      AbuseReport(
        id: 'report_003',
        title: 'User spam tin nhắn',
        description: 'Gửi 50+ tin nhắn quảng cáo trong 1 giờ.',
        reporterId: 'user_420',
        reporterName: 'Lê Văn C',
        level: AbuseReportLevel.high,
        category: AbuseReportCategory.spam,
        status: AbuseReportStatus.investigating,
        targetType: AbuseTargetType.user,
        targetId: 'user_999',
        targetLabel: 'spammer@example.com',
        createdAt: DateTime(2026, 5, 4, 18, 0),
        handledAt: DateTime(2026, 5, 4, 19, 0),
        handledBy: 'admin_01',
      ),
      AbuseReport(
        id: 'report_004',
        title: 'Đánh giá giả mạo',
        description: '5 sao nhưng không có booking tương ứng trong hệ thống.',
        reporterId: 'user_055',
        reporterName: 'Phạm Thị D',
        level: AbuseReportLevel.low,
        category: AbuseReportCategory.fraud,
        status: AbuseReportStatus.resolved,
        targetType: AbuseTargetType.review,
        targetId: 'review_88',
        targetLabel: 'Review #88 — Homestay Tuần Châu',
        createdAt: DateTime(2026, 5, 3, 11, 0),
        handledAt: DateTime(2026, 5, 3, 15, 30),
        handledBy: 'admin_01',
        resolution: 'Đã ẩn đánh giá và cảnh báo owner.',
      ),
    ]);
  }

  @override
  Future<List<AbuseReport>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<AbuseReport>.from(_items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<AbuseReport?> fetchById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  AbuseReport _update(String id, AbuseReport Function(AbuseReport) fn) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx < 0) throw Exception('Không tìm thấy báo cáo');
    final updated = fn(_items[idx]);
    _items[idx] = updated;
    return updated;
  }

  @override
  Future<AbuseReport> investigate(
    String id, {
    required String adminName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _update(
      id,
      (r) => r.copyWith(
        status: AbuseReportStatus.investigating,
        handledAt: DateTime.now(),
        handledBy: adminName,
      ),
    );
  }

  @override
  Future<AbuseReport> dismiss(
    String id, {
    required String adminName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _update(
      id,
      (r) => r.copyWith(
        status: AbuseReportStatus.dismissed,
        handledAt: DateTime.now(),
        handledBy: adminName,
        resolution: 'Báo cáo không đủ căn cứ — đã bỏ qua.',
      ),
    );
  }

  @override
  Future<AbuseReport> resolve(
    String id, {
    required String adminName,
    required String resolution,
    bool hideContent = false,
    bool banUser = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final extra = <String>[
      if (hideContent) 'Đã ẩn nội dung',
      if (banUser) 'Đã khóa user',
    ];
    final note =
        extra.isEmpty ? resolution : '$resolution (${extra.join(', ')})';
    return _update(
      id,
      (r) => r.copyWith(
        status: AbuseReportStatus.resolved,
        handledAt: DateTime.now(),
        handledBy: adminName,
        resolution: note,
      ),
    );
  }
}
