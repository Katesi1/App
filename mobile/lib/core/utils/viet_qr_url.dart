/// Build VietQR image URL từ thông tin tài khoản BE trả về.
///
/// Không hardcode STK — mọi field lấy từ [bankInfo] trong payment session.
class VietQrUrl {
  VietQrUrl._();

  static String build({
    required String bankCode,
    required String accountNumber,
    required String accountName,
    required int amount,
    required String content,
  }) {
    final encodedContent = Uri.encodeComponent(content);
    final encodedName = Uri.encodeComponent(accountName);
    return 'https://img.vietqr.io/image/$bankCode-$accountNumber-qr_only.png'
        '?amount=$amount&addInfo=$encodedContent&accountName=$encodedName';
  }
}
