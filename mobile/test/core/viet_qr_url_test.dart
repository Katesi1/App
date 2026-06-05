import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/viet_qr_url.dart';

void main() {
  group('VietQrUrl.build', () {
    test('builds URL from bankInfo fields', () {
      final url = VietQrUrl.build(
        bankCode: 'ACB',
        accountNumber: '21169431',
        accountName: 'NGUYEN VU NAM',
        amount: 499000,
        content: 'HALONG24H abc123de',
      );

      expect(
        url,
        'https://img.vietqr.io/image/ACB-21169431-qr_only.png'
        '?amount=499000&addInfo=HALONG24H%20abc123de'
        '&accountName=NGUYEN%20VU%20NAM',
      );
    });
  });
}
