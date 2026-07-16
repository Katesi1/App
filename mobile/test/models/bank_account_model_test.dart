import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/bank_account_model.dart';

void main() {
  group('BankStatusResult.fromJson', () {
    test('parses approved with current detail', () {
      final r = BankStatusResult.fromJson({
        'status': 'approved',
        'current': {
          'bankBin': '970436',
          'bankName': 'Vietcombank',
          'bankAccountNumber': '0123456789',
          'bankAccountName': 'NGUYEN VAN A',
        },
        'pending': null,
        'rejectReason': null,
      });

      expect(r.isApproved, true);
      expect(r.current?.bankBin, '970436');
      expect(r.current?.bankAccountName, 'NGUYEN VAN A');
      expect(r.pending, isNull);
    });

    test('parses pending with pending detail', () {
      final r = BankStatusResult.fromJson({
        'status': 'pending',
        'pending': {
          'bankBin': '970418',
          'bankAccountNumber': '99988877',
          'bankAccountName': 'NGUYEN VAN A',
        },
      });

      expect(r.isPending, true);
      expect(r.pending?.bankBin, '970418');
      expect(r.pending?.bankName, isNull);
    });

    test('parses rejected with rejectReason', () {
      final r = BankStatusResult.fromJson({
        'status': 'rejected',
        'rejectReason': 'Sai tên chủ tài khoản',
      });

      expect(r.isRejected, true);
      expect(r.rejectReason, 'Sai tên chủ tài khoản');
    });

    test('defaults to none when status missing', () {
      final r = BankStatusResult.fromJson(<String, dynamic>{});
      expect(r.isNone, true);
      expect(r.current, isNull);
    });
  });

  group('BankDetail.toJson', () {
    test('omits empty bankName', () {
      const d = BankDetail(
        bankBin: '970436',
        bankAccountNumber: '0123456789',
        bankAccountName: 'NGUYEN VAN A',
      );
      final json = d.toJson();
      expect(json.containsKey('bankName'), false);
      expect(json['bankBin'], '970436');
    });

    test('includes bankName when present', () {
      const d = BankDetail(
        bankBin: '970436',
        bankName: 'Vietcombank',
        bankAccountNumber: '0123456789',
        bankAccountName: 'NGUYEN VAN A',
      );
      expect(d.toJson()['bankName'], 'Vietcombank');
    });
  });
}
