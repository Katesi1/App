import 'package:equatable/equatable.dart';

/// `GET/PUT /users/me/consents` — KYC consent server-locked.
class UserConsents extends Equatable {
  final bool kyc;
  final bool marketing;
  final bool kycLocked;

  const UserConsents({
    required this.kyc,
    required this.marketing,
    this.kycLocked = true,
  });

  factory UserConsents.fromJson(Map<String, dynamic> json) {
    return UserConsents(
      kyc: json['kyc'] as bool? ?? true,
      marketing: json['marketing'] as bool? ?? false,
      kycLocked: json['kycLocked'] as bool? ??
          json['kyc_locked'] as bool? ??
          json['kycServerLocked'] as bool? ??
          json['kyc_server_locked'] as bool? ??
          true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (!kycLocked) 'kyc': kyc,
        'marketing': marketing,
      };

  UserConsents copyWith({bool? kyc, bool? marketing}) => UserConsents(
        kyc: kyc ?? this.kyc,
        marketing: marketing ?? this.marketing,
        kycLocked: kycLocked,
      );

  @override
  List<Object?> get props => [kyc, marketing, kycLocked];
}
