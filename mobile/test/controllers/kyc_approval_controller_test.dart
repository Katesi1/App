import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/admin/controllers/kyc_approval_controller.dart';
import 'package:mobile/features/admin/data/models/kyc_queue_page.dart';
import 'package:mobile/features/admin/data/models/kyc_submission.dart';
import 'package:mobile/features/admin/data/repositories/admin_kyc_repository.dart';
import 'package:mobile/features/verify/data/models/cccd_upload.dart';
import 'package:mobile/features/verify/data/models/selfie_upload.dart';
import 'package:mobile/features/verify/data/models/verify_enums.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class FakeAdminKYCRepository implements AdminKycRepository {
  List<KYCSubmission> submissions = [];
  bool shouldThrow = false;
  String errorMessage = 'Lỗi server';

  @override
  Future<KycQueuePage> fetchQueue(
    KYCQueueFilter filter, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    final filtered = _filterSubmissions(submissions, filter);
    return KycQueuePage(
      filter: filter.apiFilter,
      pendingCount: submissions.where((s) => s.isPending).length,
      total: filtered.length,
      page: page,
      pageSize: pageSize,
      items: filtered,
    );
  }

  List<KYCSubmission> _filterSubmissions(
    List<KYCSubmission> all,
    KYCQueueFilter filter,
  ) {
    return switch (filter) {
      KYCQueueFilter.pending => all.where((s) => s.isPending).toList(),
      KYCQueueFilter.approved => all.where((s) => s.isApproved).toList(),
      KYCQueueFilter.rejected => all.where((s) => s.isRejected).toList(),
      KYCQueueFilter.all => List<KYCSubmission>.from(all),
    };
  }

  @override
  Future<KYCSubmission?> fetchById(String id) async {
    if (shouldThrow) throw Exception(errorMessage);
    try {
      return submissions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<KYCSubmission> approve(String id, {required String adminName}) async {
    if (shouldThrow) throw Exception(errorMessage);
    final idx = submissions.indexWhere((s) => s.id == id);
    final updated = submissions[idx].copyWith(
      status: VerifyStatus.approved,
      handledByAdmin: adminName,
      handledAt: DateTime.now(),
    );
    submissions = [...submissions]..[idx] = updated;
    return updated;
  }

  @override
  Future<KYCSubmission> reject(
    String id, {
    required String adminName,
    required String reason,
    required List<RejectableItem> items,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    final idx = submissions.indexWhere((s) => s.id == id);
    final updated = submissions[idx].copyWith(
      status: VerifyStatus.rejected,
      handledByAdmin: adminName,
      rejectReason: reason,
      rejectedItems: items,
      handledAt: DateTime.now(),
    );
    submissions = [...submissions]..[idx] = updated;
    return updated;
  }
}

// ─── Test data helpers ────────────────────────────────────────────────────────

CCCDUpload _fakeCCCD(String id) => CCCDUpload(
      id: id,
      imageUrl: 'https://example.com/$id.jpg',
      confidence: 0.95,
      uploadedAt: DateTime(2026, 1, 10),
    );

SelfieUpload _fakeSelfie(String id) => SelfieUpload(
      id: id,
      imageUrl: 'https://example.com/selfie_$id.jpg',
      faceMatchScore: 0.92,
      isValid: true,
      uploadedAt: DateTime(2026, 1, 10),
    );

KYCSubmission _makeSubmission({
  required String id,
  required VerifyStatus status,
  int? statusFilter,
  DateTime? submittedAt,
  DateTime? handledAt,
  bool overdue = false,
}) {
  final submitted = overdue
      ? DateTime.now().subtract(const Duration(hours: 30))
      : (submittedAt ?? DateTime(2026, 1, 15, 10));
  return KYCSubmission(
    id: id,
    ownerId: 'owner_$id',
    ownerName: 'Owner $id',
    ownerPhone: '090000000$id',
    cccdFront: _fakeCCCD('${id}_front'),
    cccdBack: _fakeCCCD('${id}_back'),
    selfie: _fakeSelfie(id),
    planName: 'Starter · Hàng tháng',
    totalAmount: 299000,
    expectedRooms: 5,
    submittedAt: submitted,
    status: status,
    statusFilter: statusFilter,
    handledAt: handledAt,
  );
}

// ─── Container factory ────────────────────────────────────────────────────────

ProviderContainer _makeContainer(FakeAdminKYCRepository repo) {
  final container = ProviderContainer(
    overrides: [adminKYCRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('KYCQueueFilter enum', () {
    test('has 4 values: pending, all, approved, rejected', () {
      expect(KYCQueueFilter.values, hasLength(4));
      expect(
          KYCQueueFilter.values,
          containsAll([
            KYCQueueFilter.pending,
            KYCQueueFilter.all,
            KYCQueueFilter.approved,
            KYCQueueFilter.rejected,
          ]));
    });

    test('apiFilter maps to BE query 0-3', () {
      expect(KYCQueueFilter.all.apiFilter, 0);
      expect(KYCQueueFilter.pending.apiFilter, 1);
      expect(KYCQueueFilter.approved.apiFilter, 2);
      expect(KYCQueueFilter.rejected.apiFilter, 3);
    });
  });

  group('sortedKycSubmissionsProvider', () {
    late FakeAdminKYCRepository repo;

    setUp(() {
      repo = FakeAdminKYCRepository()
        ..submissions = [
          _makeSubmission(
            id: '1',
            status: VerifyStatus.awaitingApproval,
            statusFilter: 1,
          ),
          _makeSubmission(
            id: '2',
            status: VerifyStatus.approved,
            statusFilter: 2,
            handledAt: DateTime(2026, 1, 16),
          ),
          _makeSubmission(
            id: '3',
            status: VerifyStatus.rejected,
            statusFilter: 3,
            handledAt: DateTime(2026, 1, 17),
          ),
          _makeSubmission(
            id: '4',
            status: VerifyStatus.kycSubmitted,
            statusFilter: 1,
          ),
          _makeSubmission(
            id: '5',
            status: VerifyStatus.approved,
            statusFilter: 2,
            handledAt: DateTime(2026, 1, 18),
          ),
        ];
    });

    test('pending filter returns pending queue items', () async {
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.pending).future);
      final sorted =
          container.read(sortedKycSubmissionsProvider(KYCQueueFilter.pending));

      final list = sorted.value!;
      expect(list, hasLength(2));
      expect(list.every((s) => s.isPending), isTrue);
    });

    test('approved filter returns only approved submissions', () async {
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.approved).future);
      final sorted =
          container.read(sortedKycSubmissionsProvider(KYCQueueFilter.approved));

      final list = sorted.value!;
      expect(list, hasLength(2));
      expect(list.every((s) => s.isApproved), isTrue);
    });

    test('rejected filter returns only rejected submissions', () async {
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.rejected).future);
      final sorted =
          container.read(sortedKycSubmissionsProvider(KYCQueueFilter.rejected));

      final list = sorted.value!;
      expect(list, hasLength(1));
      expect(list.first.status, VerifyStatus.rejected);
    });

    test('all filter returns every submission', () async {
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.all).future);
      final sorted =
          container.read(sortedKycSubmissionsProvider(KYCQueueFilter.all));

      expect(sorted.value!, hasLength(5));
    });

    test('pending filter sorts overdue submissions first', () async {
      final recentlySubmitted =
          DateTime.now().subtract(const Duration(hours: 1));
      repo.submissions = [
        _makeSubmission(
          id: 'normal',
          status: VerifyStatus.awaitingApproval,
          statusFilter: 1,
          submittedAt: recentlySubmitted,
        ),
        _makeSubmission(
          id: 'overdue',
          status: VerifyStatus.awaitingApproval,
          statusFilter: 1,
          overdue: true,
        ),
      ];
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.pending).future);
      final list = container
          .read(sortedKycSubmissionsProvider(KYCQueueFilter.pending))
          .value!;

      expect(list.first.isOverdue, isTrue);
      expect(list.last.isOverdue, isFalse);
    });

    test('pending filter sorts non-overdue by oldest submittedAt first',
        () async {
      final older = _makeSubmission(
        id: 'older',
        status: VerifyStatus.awaitingApproval,
        statusFilter: 1,
        submittedAt: DateTime(2026, 1, 10),
      );
      final newer = _makeSubmission(
        id: 'newer',
        status: VerifyStatus.awaitingApproval,
        statusFilter: 1,
        submittedAt: DateTime(2026, 1, 14),
      );
      repo.submissions = [newer, older];
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.pending).future);
      final list = container
          .read(sortedKycSubmissionsProvider(KYCQueueFilter.pending))
          .value!;

      expect(list.first.id, 'older');
      expect(list.last.id, 'newer');
    });

    test('approved filter sorts by handledAt newest first', () async {
      repo.submissions = [
        _makeSubmission(
          id: 'early',
          status: VerifyStatus.approved,
          statusFilter: 2,
          handledAt: DateTime(2026, 1, 10),
        ),
        _makeSubmission(
          id: 'late',
          status: VerifyStatus.approved,
          statusFilter: 2,
          handledAt: DateTime(2026, 1, 20),
        ),
      ];
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.approved).future);
      final list = container
          .read(sortedKycSubmissionsProvider(KYCQueueFilter.approved))
          .value!;

      expect(list.first.id, 'late');
      expect(list.last.id, 'early');
    });
  });

  group('pendingKycCountProvider', () {
    test('reads pendingCount from queue response', () async {
      final repo = FakeAdminKYCRepository()
        ..submissions = [
          _makeSubmission(
            id: '1',
            status: VerifyStatus.awaitingApproval,
            statusFilter: 1,
          ),
          _makeSubmission(
            id: '2',
            status: VerifyStatus.kycSubmitted,
            statusFilter: 1,
          ),
          _makeSubmission(
            id: '3',
            status: VerifyStatus.approved,
            statusFilter: 2,
          ),
        ];
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.pending).future);
      final countState = container.read(pendingKycCountProvider);

      expect(countState.value, 2);
    });

    test('returns 0 when no pending submissions', () async {
      final repo = FakeAdminKYCRepository()
        ..submissions = [
          _makeSubmission(
            id: '1',
            status: VerifyStatus.approved,
            statusFilter: 2,
          ),
        ];
      final container = _makeContainer(repo);

      await container.read(kycQueueProvider(KYCQueueFilter.pending).future);
      final countState = container.read(pendingKycCountProvider);

      expect(countState.value, 0);
    });

    test('returns error state when repository throws', () async {
      final repo = FakeAdminKYCRepository()..shouldThrow = true;
      final container = _makeContainer(repo);

      await expectLater(
        container.read(kycQueueProvider(KYCQueueFilter.pending).future),
        throwsA(isA<Exception>()),
      );
      final countState = container.read(pendingKycCountProvider);
      expect(countState, isA<AsyncError<int>>());
    });
  });

  group('KYCApprovalActionsNotifier.approve', () {
    test('success path: returns true, state is AsyncData', () async {
      final sub = _makeSubmission(
        id: 'kyc-1',
        status: VerifyStatus.awaitingApproval,
        statusFilter: 1,
      );
      final repo = FakeAdminKYCRepository()..submissions = [sub];
      final container = _makeContainer(repo);

      final result = await container
          .read(kycApprovalActionsProvider.notifier)
          .approve('kyc-1', adminName: 'Admin Hoa');

      expect(result, isTrue);
      expect(
        container.read(kycApprovalActionsProvider),
        isA<AsyncData<void>>(),
      );
    });

    test('success path: state transitions loading → data', () async {
      final sub = _makeSubmission(
        id: 'kyc-2',
        status: VerifyStatus.awaitingApproval,
        statusFilter: 1,
      );
      final repo = FakeAdminKYCRepository()..submissions = [sub];
      final container = _makeContainer(repo);

      final states = <AsyncValue<void>>[];
      container.listen(
        kycApprovalActionsProvider,
        (_, next) => states.add(next),
      );

      await container
          .read(kycApprovalActionsProvider.notifier)
          .approve('kyc-2', adminName: 'Admin Hoa');

      expect(states.any((s) => s is AsyncLoading), isTrue);
      expect(states.last, isA<AsyncData<void>>());
    });

    test('error path: returns false, state is AsyncError', () async {
      final repo = FakeAdminKYCRepository()
        ..submissions = [
          _makeSubmission(
            id: 'kyc-3',
            status: VerifyStatus.awaitingApproval,
            statusFilter: 1,
          ),
        ]
        ..shouldThrow = true;
      final container = _makeContainer(repo);

      final result = await container
          .read(kycApprovalActionsProvider.notifier)
          .approve('kyc-3', adminName: 'Admin Hoa');

      expect(result, isFalse);
      expect(
        container.read(kycApprovalActionsProvider),
        isA<AsyncError<void>>(),
      );
    });
  });

  group('KYCApprovalActionsNotifier.reject', () {
    test('success path: returns true, state is AsyncData', () async {
      final sub = _makeSubmission(
        id: 'kyc-r1',
        status: VerifyStatus.awaitingApproval,
        statusFilter: 1,
      );
      final repo = FakeAdminKYCRepository()..submissions = [sub];
      final container = _makeContainer(repo);

      final result =
          await container.read(kycApprovalActionsProvider.notifier).reject(
        'kyc-r1',
        adminName: 'Admin Hoa',
        reason: 'Ảnh CCCD mờ',
        items: [RejectableItem.cccdFront],
      );

      expect(result, isTrue);
      expect(
        container.read(kycApprovalActionsProvider),
        isA<AsyncData<void>>(),
      );
    });

    test('error path: returns false, state is AsyncError', () async {
      final repo = FakeAdminKYCRepository()
        ..submissions = [
          _makeSubmission(
            id: 'kyc-r2',
            status: VerifyStatus.awaitingApproval,
            statusFilter: 1,
          ),
        ]
        ..shouldThrow = true;
      final container = _makeContainer(repo);

      final result =
          await container.read(kycApprovalActionsProvider.notifier).reject(
        'kyc-r2',
        adminName: 'Admin Hoa',
        reason: 'Thiếu mặt sau',
        items: [RejectableItem.cccdBack],
      );

      expect(result, isFalse);
      expect(
        container.read(kycApprovalActionsProvider),
        isA<AsyncError<void>>(),
      );
    });

    test('initial notifier state is AsyncData(null)', () {
      final repo = FakeAdminKYCRepository();
      final container = _makeContainer(repo);

      expect(
        container.read(kycApprovalActionsProvider),
        isA<AsyncData<void>>(),
      );
    });
  });
}
