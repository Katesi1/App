import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_response.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/features/admin/controllers/user_controller.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class FakeUserRepository extends UserRepository {
  List<UserModel> fakeUsers = [];
  UserModel? fakeUser;
  String? errorMessage;

  @override
  Future<ApiResponse<List<UserModel>>> getUsers({int? role}) async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    final filtered = role == null
        ? fakeUsers
        : fakeUsers.where((u) => u.role == role).toList();
    return ApiResponse(success: true, data: filtered, message: '');
  }

  @override
  Future<ApiResponse<UserModel>> getUser(String id) async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    final user = fakeUser ??
        fakeUsers.firstWhere(
          (u) => u.id == id,
          orElse: () => _buildUser(id: id),
        );
    return ApiResponse(success: true, data: user, message: '');
  }

  @override
  Future<ApiResponse<UserModel>> createUser(Map<String, dynamic> data) async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    final created = _buildUser(
      id: 'new-id',
      name: data['name'] as String? ?? 'New User',
    );
    fakeUsers = [...fakeUsers, created];
    return ApiResponse(success: true, data: created, message: 'Tạo thành công');
  }

  @override
  Future<ApiResponse<UserModel>> updateUser(
      String id, Map<String, dynamic> data) async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    final updated = _buildUser(id: id, name: data['name'] as String? ?? id);
    return ApiResponse(success: true, data: updated, message: 'Cập nhật OK');
  }

  @override
  Future<ApiResponse<void>> deleteUser(String id) async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    fakeUsers = fakeUsers.where((u) => u.id != id).toList();
    return ApiResponse(success: true, message: 'Xoá thành công');
  }

  @override
  Future<ApiResponse<List<UserModel>>> getMyStaff() async {
    if (errorMessage != null) {
      return ApiResponse(success: false, message: errorMessage!);
    }
    return ApiResponse(success: true, data: fakeUsers, message: '');
  }
}

UserModel _buildUser({
  String id = 'u1',
  String name = 'Test User',
  int role = 2,
}) =>
    UserModel(id: id, name: name, phone: '0900000001', role: role);

// ─── Helpers ──────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer(FakeUserRepository repo) {
  final container = ProviderContainer(
    overrides: [userRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── userListProvider ───────────────────────────────────────────────────────

  group('userListProvider', () {
    test('returns all users when role filter is null', () async {
      final repo = FakeUserRepository()
        ..fakeUsers = [
          _buildUser(id: 'u1', role: 2),
          _buildUser(id: 'u2', role: 3),
        ];
      final container = _makeContainer(repo);

      final result = await container.read(userListProvider(null).future);

      expect(result, hasLength(2));
      expect(result.map((u) => u.id), containsAll(['u1', 'u2']));
    });

    test('returns filtered users when role is provided', () async {
      final repo = FakeUserRepository()
        ..fakeUsers = [
          _buildUser(id: 'u1', role: 2),
          _buildUser(id: 'u2', role: 3),
          _buildUser(id: 'u3', role: 2),
        ];
      final container = _makeContainer(repo);

      final result = await container.read(userListProvider(2).future);

      expect(result, hasLength(2));
      expect(result.every((u) => u.role == 2), isTrue);
    });

    test('throws exception when repository returns error', () async {
      final repo = FakeUserRepository()
        ..errorMessage = 'Lỗi kết nối';
      final container = _makeContainer(repo);

      await expectLater(
        container.read(userListProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty list when no users exist', () async {
      final repo = FakeUserRepository()..fakeUsers = [];
      final container = _makeContainer(repo);

      final result = await container.read(userListProvider(null).future);

      expect(result, isEmpty);
    });
  });

  // ── userDetailProvider ─────────────────────────────────────────────────────

  group('userDetailProvider', () {
    test('returns correct user by id', () async {
      final expected = _buildUser(id: 'abc-123', name: 'Nguyen Van A');
      final repo = FakeUserRepository()
        ..fakeUsers = [expected]
        ..fakeUser = expected;
      final container = _makeContainer(repo);

      final result = await container.read(userDetailProvider('abc-123').future);

      expect(result.id, 'abc-123');
      expect(result.name, 'Nguyen Van A');
    });

    test('throws exception when repository returns error', () async {
      final repo = FakeUserRepository()..errorMessage = 'Không tìm thấy';
      final container = _makeContainer(repo);

      await expectLater(
        container.read(userDetailProvider('missing').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── UserActionsNotifier ────────────────────────────────────────────────────

  group('UserActionsNotifier.create', () {
    test('returns true and state is data(null) on success', () async {
      final repo = FakeUserRepository()..fakeUsers = [];
      final container = _makeContainer(repo);

      final notifier = container.read(userActionsProvider.notifier);
      final result = await notifier.create({'name': 'Tran Thi B', 'phone': '0911000000'});

      expect(result, isTrue);
      expect(container.read(userActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and state is error on failure', () async {
      final repo = FakeUserRepository()..errorMessage = 'Email đã tồn tại';
      final container = _makeContainer(repo);

      final notifier = container.read(userActionsProvider.notifier);
      final result = await notifier.create({'name': 'Bad User'});

      expect(result, isFalse);
      expect(container.read(userActionsProvider), isA<AsyncError<void>>());
    });

    test('state transitions through loading then settles', () async {
      final repo = FakeUserRepository();
      final container = _makeContainer(repo);
      final notifier = container.read(userActionsProvider.notifier);

      final states = <AsyncValue<void>>[];
      container.listen(userActionsProvider, (_, next) => states.add(next));

      await notifier.create({'name': 'Test'});

      expect(states, hasLength(greaterThanOrEqualTo(1)));
      // Final state must be data or error — never stuck loading
      expect(states.last, isNot(isA<AsyncLoading<void>>()));
    });
  });

  group('UserActionsNotifier.update', () {
    test('returns true on success', () async {
      final repo = FakeUserRepository()
        ..fakeUsers = [_buildUser(id: 'u1')];
      final container = _makeContainer(repo);

      final result = await container
          .read(userActionsProvider.notifier)
          .update('u1', {'name': 'Updated Name'});

      expect(result, isTrue);
      expect(container.read(userActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false and exposes error message on failure', () async {
      final repo = FakeUserRepository()..errorMessage = 'Không có quyền';
      final container = _makeContainer(repo);

      final result = await container
          .read(userActionsProvider.notifier)
          .update('u1', {'name': 'X'});

      expect(result, isFalse);
      final state = container.read(userActionsProvider);
      expect(state, isA<AsyncError<void>>());
      final err = (state as AsyncError<void>).error.toString();
      expect(err, contains('Không có quyền'));
    });
  });

  group('UserActionsNotifier.delete', () {
    test('returns true on success', () async {
      final repo = FakeUserRepository()
        ..fakeUsers = [_buildUser(id: 'u1')];
      final container = _makeContainer(repo);

      final result =
          await container.read(userActionsProvider.notifier).delete('u1');

      expect(result, isTrue);
      expect(container.read(userActionsProvider), isA<AsyncData<void>>());
    });

    test('returns false on failure', () async {
      final repo = FakeUserRepository()..errorMessage = 'Lỗi xoá user';
      final container = _makeContainer(repo);

      final result =
          await container.read(userActionsProvider.notifier).delete('u99');

      expect(result, isFalse);
      expect(container.read(userActionsProvider), isA<AsyncError<void>>());
    });

    test('initial state is AsyncData(null)', () {
      final repo = FakeUserRepository();
      final container = _makeContainer(repo);

      final state = container.read(userActionsProvider);

      expect(state, isA<AsyncData<void>>());
    });
  });
}
