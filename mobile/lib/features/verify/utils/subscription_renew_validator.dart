import '../../../data/models/user_model.dart';
import '../data/models/payment_quote.dart';
import '../data/models/plan.dart';

/// Đường gọi API khi user bấm "Gia hạn ngay".
enum RenewPaymentPath {
  /// `POST /payments/renew` — chỉ khi `active` hoặc `past_due`.
  renewEndpoint,

  /// `POST /payments/initiate` cùng gói — trial thanh toán sớm.
  initiateSamePlan,
}

/// Kết quả kiểm tra trước khi gia hạn.
class RenewValidation {
  final bool showRenewButton;
  final bool canTap;
  final RenewPaymentPath? path;
  final String? blockMessage;
  final String? disabledHint;

  const RenewValidation({
    required this.showRenewButton,
    required this.canTap,
    this.path,
    this.blockMessage,
    this.disabledHint,
  });

  const RenewValidation.hidden()
      : showRenewButton = false,
        canTap = false,
        path = null,
        blockMessage = null,
        disabledHint = null;
}

/// Validation gia hạn subscription — message tiếng Việt, mirror rule BE.
class SubscriptionRenewValidator {
  SubscriptionRenewValidator._();

  static RenewValidation validate({
    required UserModel user,
    Plan? plan,
    PaymentQuote? quote,
    bool quoteLoading = false,
    Object? quoteError,
  }) {
    if (user.isSubscriptionFrozen) {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        blockMessage: 'Tài khoản đang bị đóng băng. Vui lòng liên hệ hỗ trợ.',
        disabledHint: 'Không thể gia hạn khi tài khoản bị đóng băng',
      );
    }

    if (user.subscriptionStatus == 'none' ||
        !user.hasEverPurchasedSubscription) {
      return const RenewValidation.hidden();
    }

    if (user.isSubscriptionCancelled) {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        blockMessage:
            'Gói đã huỷ. Vui lòng dùng nút "Nâng cấp gói" để mua lại.',
        disabledHint: 'Gói đã huỷ — mua lại qua "Nâng cấp gói"',
      );
    }

    if (user.subscriptionStatus == 'expired') {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        blockMessage:
            'Gói đã hết hạn. Vui lòng dùng nút "Nâng cấp gói" để đăng ký lại.',
        disabledHint: 'Gói hết hạn — đăng ký lại qua "Nâng cấp gói"',
      );
    }

    if (user.subscriptionPlanId == null ||
        user.subscriptionPlanId!.trim().isEmpty) {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        blockMessage:
            'Chưa xác định được gói hiện tại. Kéo xuống để tải lại trang.',
        disabledHint: 'Thiếu thông tin gói',
      );
    }

    if (plan == null) {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        blockMessage: 'Không tải được danh mục gói. Vui lòng thử lại sau.',
        disabledHint: 'Đang tải thông tin gói...',
      );
    }

    if (!user.isInTrial &&
        !user.isSubscriptionActive &&
        !user.isSubscriptionPastDue) {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        blockMessage: 'Trạng thái gói (${user.subscriptionStatus}) '
            'không cho phép gia hạn.',
        disabledHint: 'Không thể gia hạn ở trạng thái hiện tại',
      );
    }

    if (quoteLoading) {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        disabledHint: 'Đang tải giá gia hạn...',
      );
    }

    if (quoteError != null) {
      final hint = quoteError is Exception
          ? quoteError.toString().replaceAll('Exception: ', '')
          : 'Không tải được giá gia hạn';
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        blockMessage:
            'Không tải được báo giá gia hạn. Kiểm tra mạng và thử lại.',
        disabledHint: hint,
      );
    }

    if (quote == null) {
      return RenewValidation(
        showRenewButton: true,
        canTap: false,
        disabledHint: 'Đang tải giá gia hạn...',
      );
    }

    if (user.isInTrial) {
      return RenewValidation(
        showRenewButton: true,
        canTap: true,
        path: RenewPaymentPath.initiateSamePlan,
        disabledHint: user.trialDaysLeft != null
            ? 'Thanh toán sớm trước khi hết trial '
                '(còn ${user.trialDaysLeft} ngày)'
            : 'Thanh toán sớm trong thời gian trial',
      );
    }

    return RenewValidation(
      showRenewButton: true,
      canTap: true,
      path: RenewPaymentPath.renewEndpoint,
      disabledHint: user.isSubscriptionPastDue
          ? 'Gói quá hạn — gia hạn để tiếp tục sử dụng'
          : null,
    );
  }
}
