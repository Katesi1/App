import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/partner_repository.dart';

final partnerRepositoryProvider =
    Provider<PartnerRepository>((ref) => PartnerRepository());
