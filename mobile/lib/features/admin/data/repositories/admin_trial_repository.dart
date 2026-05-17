import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trial_snapshot.dart';

abstract class AdminTrialRepository {
  Future<TrialSnapshot> fetchSubscription(String userId);

  Future<TrialActionResult> grantTrial({
    required String userId,
    required int days,
    String? planId,
    String? cycle,
    int? rooms,
    String? reason,
  });

  Future<TrialActionResult> revokeTrial({
    required String userId,
    String? reason,
  });
}

final adminTrialRepositoryProvider = Provider<AdminTrialRepository>(
  (ref) => throw UnimplementedError('adminTrialRepositoryProvider not overridden'),
);
