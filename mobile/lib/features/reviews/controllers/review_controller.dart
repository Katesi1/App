import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/review_model.dart';
import '../data/repositories/review_repository.dart';

// Re-export để các caller chỉ cần import controller.
export '../data/models/review_model.dart';

final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository());

/// Lấy danh sách review cho 1 property + summary + pagination. Public.
final propertyReviewsProvider = FutureProvider.autoDispose
    .family<PropertyReviewsPage, ReviewListParams>((ref, params) async {
  final repo = ref.read(reviewRepositoryProvider);
  final result = await repo.getReviews(params);
  if (result.success) return result.data!;
  throw Exception(result.message);
});

/// State holder cho list params (sort/filter/page) trong screen public list.
final reviewListParamsProvider = StateProvider.autoDispose
    .family<ReviewListParams, String>(
        (ref, propertyId) => ReviewListParams(propertyId: propertyId));

/// Actions notifier — bọc 3 mutation: create / reply / hide. State =
/// `AsyncValue<void>` cho UI bind loading + error.
class ReviewActionsNotifier extends StateNotifier<AsyncValue<void>> {
  ReviewActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  final ReviewRepository _repo;
  final Ref _ref;

  Future<({bool success, String message})> create({
    required String propertyId,
    required CreateReviewPayload payload,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.createReview(propertyId, payload);
    if (result.success) {
      // Invalidate list cho property này — không biết params nào đang active
      // nên invalidate cả family bằng cách rebuild propertyReviewsProvider
      // (autoDispose sẽ lo cleanup các param ko mount).
      _ref.invalidate(propertyReviewsProvider);
      state = const AsyncValue.data(null);
      return (success: true, message: result.message);
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (success: false, message: result.message);
  }

  Future<({bool success, String message})> reply({
    required String propertyId,
    required String reviewId,
    required String reply,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.replyReview(
      propertyId: propertyId,
      reviewId: reviewId,
      reply: reply,
    );
    if (result.success) {
      _ref.invalidate(propertyReviewsProvider);
      state = const AsyncValue.data(null);
      return (success: true, message: result.message);
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (success: false, message: result.message);
  }

  Future<({bool success, String message})> hide({
    required String reviewId,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.hideReview(reviewId: reviewId, reason: reason);
    if (result.success) {
      _ref.invalidate(propertyReviewsProvider);
      state = const AsyncValue.data(null);
      return (success: true, message: result.message);
    }
    state = AsyncValue.error(result.message, StackTrace.current);
    return (success: false, message: result.message);
  }
}

final reviewActionsProvider =
    StateNotifierProvider<ReviewActionsNotifier, AsyncValue<void>>((ref) {
  return ReviewActionsNotifier(ref.read(reviewRepositoryProvider), ref);
});
