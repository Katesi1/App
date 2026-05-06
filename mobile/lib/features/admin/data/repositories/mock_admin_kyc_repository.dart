import '../../../verify/data/models/cccd_upload.dart';
import '../../../verify/data/models/ocr_result.dart';
import '../../../verify/data/models/selfie_upload.dart';
import '../../../verify/data/models/verify_enums.dart';
import '../models/kyc_submission.dart';
import 'admin_kyc_repository.dart';

/// Mock repository cho admin KYC queue.
///
/// Hardcode 5 submission đa dạng (pending / overdue / approved / rejected)
/// để demo UI list + detail screen mà không cần backend.
class MockAdminKYCRepository implements AdminKycRepository {
  /// In-memory cache để approve/reject persist trong session.
  List<KYCSubmission>? _cache;

  @override
  Future<List<KYCSubmission>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cache ??= _seed();
  }

  @override
  Future<KYCSubmission?> fetchById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = await fetchAll();
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<KYCSubmission> approve(String id, {required String adminName}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = await fetchAll();
    final idx = list.indexWhere((s) => s.id == id);
    if (idx < 0) throw StateError('Không tìm thấy submission');
    final updated = list[idx].copyWith(
      status: VerifyStatus.approved,
      handledByAdmin: adminName,
      handledAt: DateTime.now(),
    );
    list[idx] = updated;
    return updated;
  }

  @override
  Future<KYCSubmission> reject(
    String id, {
    required String adminName,
    required String reason,
    required List<RejectableItem> items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final list = await fetchAll();
    final idx = list.indexWhere((s) => s.id == id);
    if (idx < 0) throw StateError('Không tìm thấy submission');
    final updated = list[idx].copyWith(
      status: VerifyStatus.rejected,
      rejectReason: reason,
      rejectedItems: items,
      handledByAdmin: adminName,
      handledAt: DateTime.now(),
    );
    list[idx] = updated;
    return updated;
  }

  /// 5 submission seed — phủ các trạng thái thường gặp.
  List<KYCSubmission> _seed() {
    final now = DateTime.now();
    return [
      // 1. Pending mới — submit 30 phút trước
      _make(
        id: 'sub_001',
        ownerName: 'Nguyễn Văn Tuấn',
        phone: '0912 345 678',
        email: 'tuan.nguyen@gmail.com',
        cccdNumber: '001192012345',
        plan: 'Professional · Hàng năm',
        amount: 23602000,
        rooms: 15,
        submittedAt: now.subtract(const Duration(minutes: 30)),
        status: VerifyStatus.awaitingApproval,
      ),
      // 2. Pending — gần SLA 22h
      _make(
        id: 'sub_002',
        ownerName: 'Trần Thị Minh Hạnh',
        phone: '0987 654 321',
        email: 'minhhanh@gmail.com',
        cccdNumber: '034186007891',
        plan: 'Starter · Hàng năm',
        amount: 19190400,
        rooms: 8,
        submittedAt: now.subtract(const Duration(hours: 22)),
        status: VerifyStatus.awaitingApproval,
      ),
      // 3. Overdue — quá 24h, chưa duyệt → escalate
      _make(
        id: 'sub_003',
        ownerName: 'Lê Hoàng Long',
        phone: '0901 234 567',
        cccdNumber: '022289334456',
        plan: 'Enterprise · Hàng năm',
        amount: 75636000,
        rooms: 80,
        submittedAt: now.subtract(const Duration(hours: 28)),
        status: VerifyStatus.awaitingApproval,
      ),
      // 4. Đã approve hôm nay
      _make(
        id: 'sub_004',
        ownerName: 'Phạm Quỳnh Anh',
        phone: '0945 678 901',
        email: 'qanhpham@gmail.com',
        cccdNumber: '001094556677',
        plan: 'Professional · Hàng tháng',
        amount: 2459700,
        rooms: 12,
        submittedAt: now.subtract(const Duration(hours: 6)),
        status: VerifyStatus.approved,
        handledByAdmin: 'Admin Halong24h',
        handledAt: now.subtract(const Duration(hours: 4)),
      ),
      // 5. Đã reject — CCCD front mờ
      _make(
        id: 'sub_005',
        ownerName: 'Vũ Đức Thành',
        phone: '0936 789 012',
        cccdNumber: '038192887766',
        plan: 'Starter · Hàng năm',
        amount: 21146400,
        rooms: 9,
        submittedAt: now.subtract(const Duration(hours: 8)),
        status: VerifyStatus.rejected,
        rejectReason:
            'Ảnh CCCD mặt trước bị mờ, không đọc được số CCCD ở góc dưới-trái. '
            'Vui lòng chụp lại ảnh rõ nét hơn, đảm bảo ánh sáng đủ.',
        rejectedItems: const [RejectableItem.cccdFront],
        handledByAdmin: 'Admin Halong24h',
        handledAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  KYCSubmission _make({
    required String id,
    required String ownerName,
    required String phone,
    String? email,
    required String cccdNumber,
    required String plan,
    required int amount,
    required int rooms,
    required DateTime submittedAt,
    required VerifyStatus status,
    String? rejectReason,
    List<RejectableItem> rejectedItems = const [],
    String? handledByAdmin,
    DateTime? handledAt,
  }) {
    return KYCSubmission(
      id: id,
      ownerId: 'owner_${id.substring(4)}',
      ownerName: ownerName,
      ownerPhone: phone,
      ownerEmail: email,
      cccdFront: CCCDUpload(
        id: '${id}_front',
        imageUrl: 'https://placehold.co/640x400/16252B/B5D4DA?text=CCCD+Front',
        ocrResult: OCRResult(
          cccdNumber: cccdNumber,
          fullName: ownerName.toUpperCase(),
          dob: '12/05/1992',
          address: 'P. Hồng Hà, TP. Hạ Long, Quảng Ninh',
          gender: 'Nam',
          expiryDate: '12/05/2027',
        ),
        confidence: 0.94,
        uploadedAt: submittedAt.subtract(const Duration(minutes: 5)),
      ),
      cccdBack: CCCDUpload(
        id: '${id}_back',
        imageUrl: 'https://placehold.co/640x400/16252B/B5D4DA?text=CCCD+Back',
        confidence: 0.91,
        uploadedAt: submittedAt.subtract(const Duration(minutes: 3)),
      ),
      selfie: SelfieUpload(
        id: '${id}_selfie',
        imageUrl: 'https://placehold.co/400x500/16252B/B5D4DA?text=Selfie',
        faceMatchScore: 0.92,
        isValid: true,
        uploadedAt: submittedAt.subtract(const Duration(minutes: 1)),
      ),
      planName: plan,
      totalAmount: amount,
      expectedRooms: rooms,
      submittedAt: submittedAt,
      status: status,
      rejectReason: rejectReason,
      rejectedItems: rejectedItems,
      handledByAdmin: handledByAdmin,
      handledAt: handledAt,
    );
  }
}

// Provider xem `admin_kyc_repository.dart` — mặc định trỏ real impl,
// override bằng MockAdminKYCRepository() khi test/QA.
