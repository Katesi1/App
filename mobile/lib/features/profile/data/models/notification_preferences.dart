import 'package:equatable/equatable.dart';

/// `GET/PUT /users/me/notification-preferences`
class NotificationPreferences extends Equatable {
  final bool booking;
  final bool payment;
  final bool quietHours;

  const NotificationPreferences({
    this.booking = true,
    this.payment = true,
    this.quietHours = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      booking: json['booking'] as bool? ?? true,
      payment: json['payment'] as bool? ?? true,
      quietHours: json['quietHours'] as bool? ??
          json['quiet_hours'] as bool? ??
          false,
    );
  }

  Map<String, dynamic> toJson() => {
        'booking': booking,
        'payment': payment,
        'quietHours': quietHours,
      };

  NotificationPreferences copyWith({
    bool? booking,
    bool? payment,
    bool? quietHours,
  }) =>
      NotificationPreferences(
        booking: booking ?? this.booking,
        payment: payment ?? this.payment,
        quietHours: quietHours ?? this.quietHours,
      );

  @override
  List<Object?> get props => [booking, payment, quietHours];
}
