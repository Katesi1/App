/// Kết quả yêu cầu xoá tài khoản (BE v1.14+ — grace 30 ngày theo NĐ 13).
///
/// `DELETE /users/me` không xoá ngay mà tạo deletion request ở trạng thái
/// pending, đặt lịch xoá sau [graceDays] ngày. Đăng nhập lại trước
/// [scheduledDeleteAt] sẽ tự huỷ yêu cầu và khôi phục tài khoản.
class AccountDeletionSchedule {
  final DateTime scheduledDeleteAt;
  final int graceDays;

  const AccountDeletionSchedule({
    required this.scheduledDeleteAt,
    required this.graceDays,
  });

  /// Mặc định grace 30 ngày khi BE không trả `graceDays`.
  static const int defaultGraceDays = 30;

  factory AccountDeletionSchedule.fromJson(Map<String, dynamic> json) {
    return AccountDeletionSchedule(
      scheduledDeleteAt: DateTime.parse(json['scheduledDeleteAt'].toString()),
      graceDays: (json['graceDays'] as num?)?.toInt() ?? defaultGraceDays,
    );
  }
}
