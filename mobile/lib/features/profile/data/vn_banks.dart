/// Danh sách ngân hàng VN + mã BIN NAPAS (6 số) để OWNER chọn khi cấu hình
/// tài khoản nhận tiền. BIN dùng để BE sinh VietQR (xem `payment_session.dart`
/// — logo `https://api.vietqr.io/img/<bin>.png`).
///
/// Mã BIN là chuẩn NAPAS ổn định. Khi cần thêm ngân hàng mới: thêm 1 dòng,
/// KHÔNG hardcode BIN rải rác nơi khác.
class VnBank {
  final String bin; // NAPAS BIN, 6 số
  final String shortName; // Tên viết tắt hiển thị (VCB, TCB...)
  final String name; // Tên đầy đủ

  const VnBank({
    required this.bin,
    required this.shortName,
    required this.name,
  });

  /// Logo ngân hàng từ vietqr.io (cùng nguồn với QR thanh toán).
  String get logoUrl => 'https://api.vietqr.io/img/$bin.png';
}

/// Ngân hàng phổ biến xếp trước. Nguồn BIN: NAPAS / vietqr.io.
const List<VnBank> kVnBanks = [
  VnBank(bin: '970436', shortName: 'Vietcombank', name: 'Ngân hàng TMCP Ngoại thương Việt Nam'),
  VnBank(bin: '970415', shortName: 'VietinBank', name: 'Ngân hàng TMCP Công thương Việt Nam'),
  VnBank(bin: '970418', shortName: 'BIDV', name: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam'),
  VnBank(bin: '970405', shortName: 'Agribank', name: 'Ngân hàng NN&PTNT Việt Nam'),
  VnBank(bin: '970407', shortName: 'Techcombank', name: 'Ngân hàng TMCP Kỹ thương Việt Nam'),
  VnBank(bin: '970422', shortName: 'MB Bank', name: 'Ngân hàng TMCP Quân đội'),
  VnBank(bin: '970416', shortName: 'ACB', name: 'Ngân hàng TMCP Á Châu'),
  VnBank(bin: '970432', shortName: 'VPBank', name: 'Ngân hàng TMCP Việt Nam Thịnh Vượng'),
  VnBank(bin: '970403', shortName: 'Sacombank', name: 'Ngân hàng TMCP Sài Gòn Thương Tín'),
  VnBank(bin: '970423', shortName: 'TPBank', name: 'Ngân hàng TMCP Tiên Phong'),
  VnBank(bin: '970441', shortName: 'VIB', name: 'Ngân hàng TMCP Quốc tế Việt Nam'),
  VnBank(bin: '970443', shortName: 'SHB', name: 'Ngân hàng TMCP Sài Gòn - Hà Nội'),
  VnBank(bin: '970437', shortName: 'HDBank', name: 'Ngân hàng TMCP Phát triển TP.HCM'),
  VnBank(bin: '970426', shortName: 'MSB', name: 'Ngân hàng TMCP Hàng Hải Việt Nam'),
  VnBank(bin: '970448', shortName: 'OCB', name: 'Ngân hàng TMCP Phương Đông'),
  VnBank(bin: '970440', shortName: 'SeABank', name: 'Ngân hàng TMCP Đông Nam Á'),
  VnBank(bin: '970431', shortName: 'Eximbank', name: 'Ngân hàng TMCP Xuất Nhập khẩu Việt Nam'),
  VnBank(bin: '970449', shortName: 'LPBank', name: 'Ngân hàng TMCP Lộc Phát Việt Nam'),
  VnBank(bin: '970429', shortName: 'SCB', name: 'Ngân hàng TMCP Sài Gòn'),
  VnBank(bin: '970428', shortName: 'Nam A Bank', name: 'Ngân hàng TMCP Nam Á'),
  VnBank(bin: '970409', shortName: 'Bac A Bank', name: 'Ngân hàng TMCP Bắc Á'),
  VnBank(bin: '970412', shortName: 'PVcomBank', name: 'Ngân hàng TMCP Đại Chúng Việt Nam'),
  VnBank(bin: '970427', shortName: 'VietABank', name: 'Ngân hàng TMCP Việt Á'),
  VnBank(bin: '970425', shortName: 'ABBANK', name: 'Ngân hàng TMCP An Bình'),
  VnBank(bin: '970419', shortName: 'NCB', name: 'Ngân hàng TMCP Quốc Dân'),
  VnBank(bin: '970452', shortName: 'Kienlongbank', name: 'Ngân hàng TMCP Kiên Long'),
  VnBank(bin: '970400', shortName: 'Saigonbank', name: 'Ngân hàng TMCP Sài Gòn Công Thương'),
  VnBank(bin: '970438', shortName: 'BaoVietBank', name: 'Ngân hàng TMCP Bảo Việt'),
  VnBank(bin: '970430', shortName: 'PGBank', name: 'Ngân hàng TMCP Thịnh vượng và Phát triển'),
  VnBank(bin: '970433', shortName: 'VietBank', name: 'Ngân hàng TMCP Việt Nam Thương Tín'),
  VnBank(bin: '970424', shortName: 'Shinhan Bank', name: 'Ngân hàng TNHH MTV Shinhan Việt Nam'),
  VnBank(bin: '970457', shortName: 'Woori Bank', name: 'Ngân hàng TNHH MTV Woori Việt Nam'),
  VnBank(bin: '970439', shortName: 'Public Bank', name: 'Ngân hàng TNHH MTV Public Việt Nam'),
  VnBank(bin: '970458', shortName: 'UOB', name: 'Ngân hàng TNHH MTV UOB Việt Nam'),
  VnBank(bin: '970410', shortName: 'Standard Chartered', name: 'Ngân hàng TNHH MTV Standard Chartered VN'),
  VnBank(bin: '970442', shortName: 'Hong Leong', name: 'Ngân hàng TNHH MTV Hong Leong Việt Nam'),
  VnBank(bin: '970444', shortName: 'CBBank', name: 'Ngân hàng TM TNHH MTV Xây dựng Việt Nam'),
  VnBank(bin: '970414', shortName: 'OceanBank', name: 'Ngân hàng TM TNHH MTV Đại Dương'),
  VnBank(bin: '970408', shortName: 'GPBank', name: 'Ngân hàng TM TNHH MTV Dầu Khí Toàn Cầu'),
  VnBank(bin: '970421', shortName: 'VRB', name: 'Ngân hàng Liên doanh Việt - Nga'),
  VnBank(bin: '970446', shortName: 'Co-opBank', name: 'Ngân hàng Hợp tác xã Việt Nam'),
  VnBank(bin: '970406', shortName: 'DongA Bank', name: 'Ngân hàng TMCP Đông Á'),
  VnBank(bin: '546034', shortName: 'Cake', name: 'Cake by VPBank'),
  VnBank(bin: '546035', shortName: 'Ubank', name: 'Ubank by VPBank'),
  VnBank(bin: '963388', shortName: 'Timo', name: 'Timo by Bản Việt Bank'),
];

/// Tìm bank theo BIN (dùng khi prefill từ user đã lưu). Null nếu không khớp.
VnBank? bankByBin(String? bin) {
  if (bin == null || bin.isEmpty) return null;
  for (final b in kVnBanks) {
    if (b.bin == bin) return b;
  }
  return null;
}
