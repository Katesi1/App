import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/notification_deep_link.dart';

void main() {
  group('resolveNotificationRoute — map theo pushType', () {
    test('kyc_approved → /dashboard', () {
      expect(
        resolveNotificationRoute({'type': 'kyc_approved'}),
        '/dashboard',
      );
    });

    test('kyc_rejected → /verify/rejected', () {
      expect(
        resolveNotificationRoute({'type': 'kyc_rejected'}),
        '/verify/rejected',
      );
    });

    test('bank_approved / bank_rejected → /profile/bank-account', () {
      expect(
        resolveNotificationRoute({'type': 'bank_approved'}),
        '/profile/bank-account',
      );
      expect(
        resolveNotificationRoute({'type': 'bank_rejected'}),
        '/profile/bank-account',
      );
    });

    test('property_approved dùng targetId → /properties/:id', () {
      expect(
        resolveNotificationRoute({
          'type': 'property_approved',
          'targetId': 'abc123',
          'deepLink': '/host/properties/abc123',
        }),
        '/properties/abc123',
      );
    });

    test('property push thiếu id → /properties (list)', () {
      expect(
        resolveNotificationRoute({'type': 'property_updated'}),
        '/properties',
      );
    });

    test('calendar_locked lấy id từ deepLink khi thiếu targetId', () {
      expect(
        resolveNotificationRoute({
          'type': 'calendar_locked',
          'deepLink': '/host/properties/p-9',
        }),
        '/properties/p-9',
      );
    });

    test('subscription_* → /verify/subscription-detail', () {
      expect(
        resolveNotificationRoute({'type': 'subscription_paid'}),
        '/verify/subscription-detail',
      );
      expect(
        resolveNotificationRoute({'type': 'subscription_frozen'}),
        '/verify/subscription-detail',
      );
    });

    test('trial_granted → /verify/subscription-detail', () {
      expect(
        resolveNotificationRoute({'type': 'trial_granted'}),
        '/verify/subscription-detail',
      );
    });

    test('payment_succeeded → /dashboard', () {
      expect(
        resolveNotificationRoute({'type': 'payment_succeeded'}),
        '/dashboard',
      );
    });

    test('booking_* thiếu id → /bookings (list)', () {
      for (final t in [
        'booking_created',
        'booking_confirmed',
        'booking_paid',
        'booking_cancelled',
        'booking_deposit_proof',
        'booking_checkin_reminder',
        'booking_completed',
      ]) {
        expect(resolveNotificationRoute({'type': t}), '/bookings');
      }
    });

    test('booking_* có targetId → /bookings/:id (v1.31 deeplink)', () {
      for (final t in [
        'booking_created',
        'booking_confirmed',
        'booking_paid',
        'booking_deposit_proof',
        'booking_checkin_reminder',
        'booking_completed',
      ]) {
        expect(
          resolveNotificationRoute({'type': t, 'targetId': 'bk-9'}),
          '/bookings/bk-9',
        );
      }
    });

    test('staff_removed → /login', () {
      expect(
        resolveNotificationRoute({'type': 'staff_removed'}),
        '/login',
      );
    });

    test('chat_message dùng targetId → /conversations/:id', () {
      expect(
        resolveNotificationRoute({'type': 'chat_message', 'targetId': 'c1'}),
        '/conversations/c1',
      );
    });
  });

  group('resolveNotificationRoute — target chưa có route → /notifications', () {
    test('bank_submitted (admin) → /notifications', () {
      expect(
        resolveNotificationRoute({
          'type': 'bank_submitted',
          'deepLink': '/admin/bank-accounts',
        }),
        '/notifications',
      );
    });

    test('dispute_opened (admin/khiếu nại) → /notifications', () {
      expect(
        resolveNotificationRoute({
          'type': 'dispute_opened',
          'deepLink': '/admin/disputes/d1',
        }),
        '/notifications',
      );
    });

    test('lead_new → /notifications', () {
      expect(
        resolveNotificationRoute({
          'type': 'lead_new',
          'deepLink': '/host/leads/l1',
        }),
        '/notifications',
      );
    });

    test('property_pending_review (admin) → /notifications', () {
      expect(
        resolveNotificationRoute({
          'type': 'property_pending_review',
          'deepLink': '/admin/properties/p1',
        }),
        '/notifications',
      );
    });
  });

  group('resolveNotificationRoute — dịch path web khi type lạ/thiếu', () {
    test('/dashboard/billing → /verify/subscription-detail', () {
      expect(
        resolveNotificationRoute({'deepLink': '/dashboard/billing'}),
        '/verify/subscription-detail',
      );
    });

    test('/host/settings/bank → /profile/bank-account', () {
      expect(
        resolveNotificationRoute({'deepLink': '/host/settings/bank'}),
        '/profile/bank-account',
      );
    });

    test('/host/properties/:id → /properties/:id', () {
      expect(
        resolveNotificationRoute({'deepLink': '/host/properties/x9'}),
        '/properties/x9',
      );
    });

    test('/my-bookings → /bookings', () {
      expect(
        resolveNotificationRoute({'deepLink': '/my-bookings'}),
        '/bookings',
      );
    });

    test('path đã đúng dạng app đi thẳng (/conversations/:id)', () {
      expect(
        resolveNotificationRoute({'deepLink': '/conversations/z1'}),
        '/conversations/z1',
      );
    });

    test('path admin lạ không pass-through → /notifications', () {
      expect(
        resolveNotificationRoute({'deepLink': '/admin/unknown/thing'}),
        '/notifications',
      );
    });
  });

  group('resolveNotificationRoute — an toàn & rỗng', () {
    test('không type lẫn deepLink → null (không điều hướng)', () {
      expect(resolveNotificationRoute({}), isNull);
    });

    test('chặn open-redirect: deepLink có scheme/host → /notifications', () {
      // type lạ + deepLink tuyệt đối → path rewrite từ chối → fallback.
      expect(
        resolveNotificationRoute({
          'type': 'weird_unknown',
          'deepLink': 'https://evil.com/admin',
        }),
        '/notifications',
      );
    });

    test('targetId chứa ký tự nguy hiểm bị bỏ → /properties (list)', () {
      expect(
        resolveNotificationRoute({
          'type': 'property_approved',
          'targetId': '../admin',
        }),
        '/properties',
      );
    });

    test('type lạ hoàn toàn, không deepLink dùng được → /notifications', () {
      expect(
        resolveNotificationRoute({'type': 'brand_new_type_2027'}),
        '/notifications',
      );
    });
  });
}
