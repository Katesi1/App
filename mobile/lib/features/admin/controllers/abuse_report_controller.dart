import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/abuse_report.dart';
import '../data/repositories/abuse_report_repository.dart';

enum AbuseReportFilter { pending, all, resolved, dismissed }

final abuseReportFilterProvider =
    StateProvider<AbuseReportFilter>((_) => AbuseReportFilter.pending);

final abuseReportsProvider = FutureProvider<List<AbuseReport>>(
  (ref) => ref.watch(abuseReportRepositoryProvider).fetchAll(),
);

final filteredAbuseReportsProvider =
    Provider<AsyncValue<List<AbuseReport>>>((ref) {
  final filter = ref.watch(abuseReportFilterProvider);
  final all = ref.watch(abuseReportsProvider);
  return all.whenData((list) {
    final filtered = switch (filter) {
      AbuseReportFilter.pending => list
          .where(
            (r) =>
                r.status == AbuseReportStatus.pending ||
                r.status == AbuseReportStatus.investigating,
          )
          .toList(),
      AbuseReportFilter.resolved =>
        list.where((r) => r.status == AbuseReportStatus.resolved).toList(),
      AbuseReportFilter.dismissed =>
        list.where((r) => r.status == AbuseReportStatus.dismissed).toList(),
      AbuseReportFilter.all => List<AbuseReport>.from(list),
    };

    filtered.sort((a, b) {
      if (filter == AbuseReportFilter.pending) {
        final levelOrder = {
          AbuseReportLevel.high: 0,
          AbuseReportLevel.medium: 1,
          AbuseReportLevel.low: 2,
        };
        final lc = levelOrder[a.level]!.compareTo(levelOrder[b.level]!);
        if (lc != 0) return lc;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  });
});

final pendingAbuseReportCountProvider = Provider<AsyncValue<int>>((ref) {
  final all = ref.watch(abuseReportsProvider);
  return all.whenData(
    (list) => list.where((r) => r.status.isActionable).length,
  );
});

final abuseReportDetailProvider =
    FutureProvider.family<AbuseReport?, String>((ref, id) {
  return ref.watch(abuseReportRepositoryProvider).fetchById(id);
});

class AbuseReportActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  AbuseReportActionsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> investigate(String id, {required String adminName}) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(abuseReportRepositoryProvider)
          .investigate(id, adminName: adminName);
      _invalidate(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> dismiss(String id, {required String adminName}) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(abuseReportRepositoryProvider)
          .dismiss(id, adminName: adminName);
      _invalidate(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> resolve(
    String id, {
    required String adminName,
    required String resolution,
    bool hideContent = false,
    bool banUser = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(abuseReportRepositoryProvider).resolve(
            id,
            adminName: adminName,
            resolution: resolution,
            hideContent: hideContent,
            banUser: banUser,
          );
      _invalidate(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _invalidate(String id) {
    _ref.invalidate(abuseReportsProvider);
    _ref.invalidate(abuseReportDetailProvider(id));
  }
}

final abuseReportActionsProvider =
    StateNotifierProvider<AbuseReportActionsNotifier, AsyncValue<void>>(
  (ref) => AbuseReportActionsNotifier(ref),
);
