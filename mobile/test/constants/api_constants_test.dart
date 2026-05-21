import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_constants.dart';

void main() {
  // ── Static string constants ───────────────────────────────────────────────

  group('ApiConstants — base URL', () {
    test('baseUrl is the production HTTPS endpoint', () {
      expect(ApiConstants.baseUrl, 'https://api.halong24h.com');
    });
  });

  group('ApiConstants — Auth endpoints', () {
    test('login', () => expect(ApiConstants.login, '/auth/login'));
    test('register', () => expect(ApiConstants.register, '/auth/register'));
    test('refresh', () => expect(ApiConstants.refresh, '/auth/refresh'));
    test('googleLogin', () => expect(ApiConstants.googleLogin, '/auth/google'));
    test('appleLogin', () => expect(ApiConstants.appleLogin, '/auth/apple'));
    test('logout', () => expect(ApiConstants.logout, '/auth/logout'));
    test('profile', () => expect(ApiConstants.profile, '/auth/profile'));
    test('forgotPassword',
        () => expect(ApiConstants.forgotPassword, '/auth/forgot-password'));
    test('resetPassword',
        () => expect(ApiConstants.resetPassword, '/auth/reset-password'));
    test('changePassword',
        () => expect(ApiConstants.changePassword, '/auth/change-password'));
  });

  group('ApiConstants — Users', () {
    test('users list endpoint', () => expect(ApiConstants.users, '/users'));

    test('userDetail builds correct URL', () {
      expect(ApiConstants.userDetail('abc123'), '/users/abc123');
    });

    test('userDetail with UUID format', () {
      expect(
        ApiConstants.userDetail('550e8400-e29b-41d4-a716-446655440000'),
        '/users/550e8400-e29b-41d4-a716-446655440000',
      );
    });
  });

  group('ApiConstants — Properties', () {
    test('properties list endpoint',
        () => expect(ApiConstants.properties, '/properties'));
    test('propertiesPublic',
        () => expect(ApiConstants.propertiesPublic, '/properties/public'));

    test('propertyDetail builds correct URL', () {
      expect(ApiConstants.propertyDetail('prop01'), '/properties/prop01');
    });

    test('propertyImages builds correct URL', () {
      expect(ApiConstants.propertyImages('prop01'), '/properties/prop01/images');
    });

    test('propertyImageDetail builds correct URL', () {
      expect(
        ApiConstants.propertyImageDetail('prop01', 'img99'),
        '/properties/prop01/images/img99',
      );
    });

    test('propertyImageCover builds correct URL', () {
      expect(
        ApiConstants.propertyImageCover('prop01', 'img99'),
        '/properties/prop01/images/img99/cover',
      );
    });

    test('propertyPrices builds correct URL', () {
      expect(
        ApiConstants.propertyPrices('prop01'),
        '/properties/prop01/prices',
      );
    });

    test('propertyShare builds correct URL', () {
      expect(
        ApiConstants.propertyShare('prop01'),
        '/properties/share/prop01',
      );
    });

    test('propertyReviews builds correct URL', () {
      expect(
        ApiConstants.propertyReviews('prop01'),
        '/properties/prop01/reviews',
      );
    });

    test('propertyReviewReply builds correct URL', () {
      expect(
        ApiConstants.propertyReviewReply('prop01', 'rev42'),
        '/properties/prop01/reviews/rev42/reply',
      );
    });
  });

  group('ApiConstants — Bookings', () {
    test('bookings list endpoint',
        () => expect(ApiConstants.bookings, '/bookings'));
    test('holdRoom', () => expect(ApiConstants.holdRoom, '/bookings/hold'));
    test('customerHold',
        () => expect(ApiConstants.customerHold, '/bookings/customer-hold'));
    test('myBookings',
        () => expect(ApiConstants.myBookings, '/bookings/my-bookings'));

    test('bookingDetail builds correct URL', () {
      expect(ApiConstants.bookingDetail('bk001'), '/bookings/bk001');
    });

    test('bookingConfirm builds correct URL', () {
      expect(ApiConstants.bookingConfirm('bk001'), '/bookings/bk001/confirm');
    });

    test('bookingCancel builds correct URL', () {
      expect(ApiConstants.bookingCancel('bk001'), '/bookings/bk001/cancel');
    });

    test('bookingUpdate builds correct URL (same path as detail)', () {
      expect(ApiConstants.bookingUpdate('bk001'), '/bookings/bk001');
    });

    test('bookingCalendar builds correct URL', () {
      expect(
        ApiConstants.bookingCalendar('prop01'),
        '/bookings/calendar/prop01',
      );
    });

    test('customerCancel builds correct URL', () {
      expect(
        ApiConstants.customerCancel('bk001'),
        '/bookings/bk001/customer-cancel',
      );
    });

    test('bookingDetail with UUID format', () {
      expect(
        ApiConstants.bookingDetail('550e8400-e29b-41d4-a716-446655440000'),
        '/bookings/550e8400-e29b-41d4-a716-446655440000',
      );
    });
  });

  group('ApiConstants — KYC', () {
    test('kycUploadCccdFront',
        () => expect(ApiConstants.kycUploadCccdFront, '/kyc/upload-cccd-front'));
    test('kycUploadCccdBack',
        () => expect(ApiConstants.kycUploadCccdBack, '/kyc/upload-cccd-back'));
    test('kycUploadSelfie',
        () => expect(ApiConstants.kycUploadSelfie, '/kyc/upload-selfie'));
    test('kycSubmit', () => expect(ApiConstants.kycSubmit, '/kyc/submit'));
    test('kycStatus', () => expect(ApiConstants.kycStatus, '/kyc/status'));

    test('kycSubmissionDetail builds correct URL', () {
      expect(ApiConstants.kycSubmissionDetail('sub01'), '/kyc/submissions/sub01');
    });

    test('kycSubmissionResubmit builds correct URL', () {
      expect(
        ApiConstants.kycSubmissionResubmit('sub01'),
        '/kyc/submissions/sub01/resubmit',
      );
    });
  });

  group('ApiConstants — Billing & Payment', () {
    test('billingPlans', () => expect(ApiConstants.billingPlans, '/billing/plans'));
    test('paymentInitiate',
        () => expect(ApiConstants.paymentInitiate, '/payments/initiate'));
    test('paymentRenew',
        () => expect(ApiConstants.paymentRenew, '/payments/renew'));
    test('paymentHistory',
        () => expect(ApiConstants.paymentHistory, '/payments/history'));

    test('paymentStatus builds correct URL', () {
      expect(
        ApiConstants.paymentStatus('sess01'),
        '/payments/sess01/status',
      );
    });

    test('paymentRefund builds correct URL', () {
      expect(
        ApiConstants.paymentRefund('sess01'),
        '/payments/sess01/refund',
      );
    });
  });

  group('ApiConstants — Admin', () {
    test('adminKycQueue',
        () => expect(ApiConstants.adminKycQueue, '/admin/kyc/queue'));

    test('adminKycApprove builds correct URL', () {
      expect(
        ApiConstants.adminKycApprove('sub01'),
        '/admin/kyc/submissions/sub01/approve',
      );
    });

    test('adminKycReject builds correct URL', () {
      expect(
        ApiConstants.adminKycReject('sub01'),
        '/admin/kyc/submissions/sub01/reject',
      );
    });

    test('adminUserSubscription builds correct URL', () {
      expect(
        ApiConstants.adminUserSubscription('usr01'),
        '/admin/users/usr01/subscription',
      );
    });

    test('adminUserTrial builds correct URL', () {
      expect(
        ApiConstants.adminUserTrial('usr01'),
        '/admin/users/usr01/trial',
      );
    });

    test('adminUserSubscription with UUID format', () {
      expect(
        ApiConstants.adminUserSubscription('550e8400-e29b-41d4-a716-446655440000'),
        '/admin/users/550e8400-e29b-41d4-a716-446655440000/subscription',
      );
    });

    test('adminUserTrial with UUID format', () {
      expect(
        ApiConstants.adminUserTrial('550e8400-e29b-41d4-a716-446655440000'),
        '/admin/users/550e8400-e29b-41d4-a716-446655440000/trial',
      );
    });

    test('adminHideReview builds correct URL', () {
      expect(
        ApiConstants.adminHideReview('rev42'),
        '/admin/reviews/rev42',
      );
    });
  });

  group('ApiConstants — Calendar', () {
    test('calendarPublicGrid',
        () => expect(ApiConstants.calendarPublicGrid, '/calendar/public-grid'));
    test('calendarGrid',
        () => expect(ApiConstants.calendarGrid, '/calendar/grid'));
    test('calendarLock',
        () => expect(ApiConstants.calendarLock, '/calendar/lock'));
    test('calendarSold',
        () => expect(ApiConstants.calendarSold, '/calendar/sold'));
    test('calendarAdminContact',
        () =>
            expect(ApiConstants.calendarAdminContact, '/calendar/admin-contact'));
  });

  group('ApiConstants — Dashboard & Reports', () {
    test('dashboardStats',
        () => expect(ApiConstants.dashboardStats, '/dashboard/stats'));
    test('reports', () => expect(ApiConstants.reports, '/reports'));
  });

  group('ApiConstants — Staff', () {
    test('staffInvites',
        () => expect(ApiConstants.staffInvites, '/staff/invites'));
    test('staffInviteAccept',
        () => expect(ApiConstants.staffInviteAccept, '/staff/invites/accept'));
    test('staff', () => expect(ApiConstants.staff, '/staff'));

    test('staffInviteDetail builds correct URL', () {
      expect(
        ApiConstants.staffInviteDetail('inv01'),
        '/staff/invites/inv01',
      );
    });

    test('staffInviteVerify builds correct URL', () {
      expect(
        ApiConstants.staffInviteVerify('tok123'),
        '/staff/invites/verify/tok123',
      );
    });

    test('staffDetail builds correct URL', () {
      expect(ApiConstants.staffDetail('usr01'), '/staff/usr01');
    });
  });

  group('ApiConstants — Devices & Notifications', () {
    test('appVersion', () => expect(ApiConstants.appVersion, '/app/version'));
    test('devices', () => expect(ApiConstants.devices, '/devices'));
    test('notifications',
        () => expect(ApiConstants.notifications, '/notifications'));
    test('notificationsUnreadCount',
        () => expect(
            ApiConstants.notificationsUnreadCount, '/notifications/unread-count'));
    test('notificationsReadAll',
        () =>
            expect(ApiConstants.notificationsReadAll, '/notifications/read-all'));

    test('deviceDetail builds correct URL', () {
      expect(
        ApiConstants.deviceDetail('fcm-token-abc'),
        '/devices/fcm-token-abc',
      );
    });

    test('notificationRead builds correct URL', () {
      expect(
        ApiConstants.notificationRead('notif01'),
        '/notifications/notif01/read',
      );
    });
  });

  group('ApiConstants — Partner', () {
    test('partnerProperties',
        () => expect(ApiConstants.partnerProperties, '/partner/properties'));
    test('partnerBookings',
        () => expect(ApiConstants.partnerBookings, '/partner/bookings'));

    test('partnerPropertyDetail builds correct URL', () {
      expect(
        ApiConstants.partnerPropertyDetail('prop01'),
        '/partner/properties/prop01',
      );
    });

    test('partnerPropertyAvailability builds correct URL', () {
      expect(
        ApiConstants.partnerPropertyAvailability('prop01'),
        '/partner/properties/prop01/availability',
      );
    });

    test('partnerBookingCancel builds correct URL', () {
      expect(
        ApiConstants.partnerBookingCancel('bk001'),
        '/partner/bookings/bk001/cancel',
      );
    });
  });
}
