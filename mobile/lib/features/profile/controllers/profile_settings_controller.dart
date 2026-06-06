import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/models/data_export_request.dart';
import '../data/models/notification_preferences.dart';
import '../data/models/support_ticket.dart';
import '../data/models/user_consents.dart';
import '../data/repositories/profile_settings_repository.dart';

// ── Support tickets ───────────────────────────────────────────────────────────

final supportTicketListProvider =
    FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final repo = ref.read(profileSettingsRepositoryProvider);
  final result = await repo.getTickets();
  if (result.success) return result.data ?? [];
  throw Exception(result.message);
});

final supportTicketDetailProvider = FutureProvider.autoDispose
    .family<SupportTicketDetail, String>((ref, ticketId) async {
  final repo = ref.read(profileSettingsRepositoryProvider);
  final result = await repo.getTicketDetail(ticketId);
  if (result.success && result.data != null) return result.data!;
  throw Exception(result.message);
});

class SupportTicketActionsNotifier extends StateNotifier<AsyncValue<void>> {
  SupportTicketActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ProfileSettingsRepository _repo;
  final Ref _ref;

  Future<(bool, String, String?)> createTicket({
    required String subject,
    required String message,
    String? category,
    String? contact,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.createTicket(
      subject: subject,
      message: message,
      category: category,
      contact: contact,
    );
    if (result.success && result.data != null) {
      _ref.invalidate(supportTicketListProvider);
      state = const AsyncValue.data(null);
      return (true, 'Đã tạo yêu cầu hỗ trợ', result.data!.id);
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message, null);
  }

  Future<(bool, String)> reply(String ticketId, String message) async {
    state = const AsyncValue.loading();
    final result = await _repo.replyTicket(
      ticketId: ticketId,
      message: message,
    );
    if (result.success) {
      _ref.invalidate(supportTicketDetailProvider(ticketId));
      _ref.invalidate(supportTicketListProvider);
      state = const AsyncValue.data(null);
      return (true, 'Đã gửi phản hồi');
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }
}

final supportTicketActionsProvider = StateNotifierProvider.autoDispose<
    SupportTicketActionsNotifier, AsyncValue<void>>((ref) {
  return SupportTicketActionsNotifier(
    ref.read(profileSettingsRepositoryProvider),
    ref,
  );
});

// ── Feedback ──────────────────────────────────────────────────────────────────

class FeedbackActionsNotifier extends StateNotifier<AsyncValue<void>> {
  FeedbackActionsNotifier(this._repo) : super(const AsyncValue.data(null));

  final ProfileSettingsRepository _repo;

  Future<(bool, String)> submit({
    required String category,
    required String content,
    String? contact,
    bool includeDeviceInfo = false,
  }) async {
    state = const AsyncValue.loading();
    Map<String, dynamic>? deviceInfo;
    if (includeDeviceInfo) {
      final info = await PackageInfo.fromPlatform();
      deviceInfo = {
        'platform': Platform.isIOS ? 'ios' : 'android',
        'appVersion': info.version,
        'buildNumber': info.buildNumber,
      };
    }
    final result = await _repo.submitFeedback(
      category: category,
      content: content,
      contact: contact,
      includeDeviceInfo: includeDeviceInfo,
      deviceInfo: deviceInfo,
    );
    if (result.success) {
      state = const AsyncValue.data(null);
      return (true, 'Đã gửi phản hồi, cảm ơn bạn');
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }
}

final feedbackActionsProvider = StateNotifierProvider.autoDispose<
    FeedbackActionsNotifier, AsyncValue<void>>((ref) {
  return FeedbackActionsNotifier(ref.read(profileSettingsRepositoryProvider));
});

// ── Data export ───────────────────────────────────────────────────────────────

final dataExportListProvider =
    FutureProvider.autoDispose<List<DataExportRequest>>((ref) async {
  final repo = ref.read(profileSettingsRepositoryProvider);
  final result = await repo.getDataExports();
  if (result.success) return result.data ?? [];
  throw Exception(result.message);
});

class DataExportActionsNotifier extends StateNotifier<AsyncValue<void>> {
  DataExportActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ProfileSettingsRepository _repo;
  final Ref _ref;

  Future<(bool, String)> requestExport() async {
    state = const AsyncValue.loading();
    final result = await _repo.requestDataExport();
    if (result.success) {
      _ref.invalidate(dataExportListProvider);
      state = const AsyncValue.data(null);
      return (true, 'Đã gửi yêu cầu xuất dữ liệu');
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }
}

final dataExportActionsProvider = StateNotifierProvider.autoDispose<
    DataExportActionsNotifier, AsyncValue<void>>((ref) {
  return DataExportActionsNotifier(
    ref.read(profileSettingsRepositoryProvider),
    ref,
  );
});

// ── Consents ──────────────────────────────────────────────────────────────────

final userConsentsProvider =
    FutureProvider.autoDispose<UserConsents>((ref) async {
  final repo = ref.read(profileSettingsRepositoryProvider);
  final result = await repo.getConsents();
  if (result.success && result.data != null) return result.data!;
  throw Exception(result.message);
});

class UserConsentsNotifier extends StateNotifier<AsyncValue<void>> {
  UserConsentsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ProfileSettingsRepository _repo;
  final Ref _ref;

  Future<(bool, String)> save(UserConsents consents) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateConsents(consents);
    if (result.success) {
      _ref.invalidate(userConsentsProvider);
      state = const AsyncValue.data(null);
      return (true, 'Đã lưu quyền đồng ý');
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }
}

final userConsentsActionsProvider = StateNotifierProvider.autoDispose<
    UserConsentsNotifier, AsyncValue<void>>((ref) {
  return UserConsentsNotifier(
    ref.read(profileSettingsRepositoryProvider),
    ref,
  );
});

// ── Notification preferences ──────────────────────────────────────────────────

final notificationPreferencesProvider =
    FutureProvider.autoDispose<NotificationPreferences>((ref) async {
  final repo = ref.read(profileSettingsRepositoryProvider);
  final result = await repo.getNotificationPreferences();
  if (result.success && result.data != null) return result.data!;
  throw Exception(result.message);
});

class NotificationPreferencesNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationPreferencesNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ProfileSettingsRepository _repo;
  final Ref _ref;

  Future<(bool, String)> save(NotificationPreferences prefs) async {
    state = const AsyncValue.loading();
    final result = await _repo.updateNotificationPreferences(prefs);
    if (result.success) {
      _ref.invalidate(notificationPreferencesProvider);
      state = const AsyncValue.data(null);
      return (true, 'Đã cập nhật tùy chọn thông báo');
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (false, result.message);
  }
}

final notificationPreferencesActionsProvider = StateNotifierProvider
    .autoDispose<NotificationPreferencesNotifier, AsyncValue<void>>((ref) {
  return NotificationPreferencesNotifier(
    ref.read(profileSettingsRepositoryProvider),
    ref,
  );
});
