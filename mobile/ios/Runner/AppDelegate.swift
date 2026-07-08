import Flutter
import UIKit
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(
      application, didFinishLaunchingWithOptions: launchOptions)
    // Buộc đăng ký APNs ngay ở launch. Cần thiết vì với AppDelegate
    // implicit-engine mới, swizzling của Firebase không tự gọi hàm này →
    // getAPNSToken() luôn null. Token trả về ở didRegister... bên dưới rồi
    // forward cho Messaging. An toàn kể cả khi chưa xin quyền (chỉ lấy token).
    application.registerForRemoteNotifications()
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // ── Diagnostic tạm: log kết quả đăng ký APNs để tìm nguyên nhân APNs token
  // null. Vẫn gọi super để Firebase (proxy) nhận được device token như thường.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    NSLog("[APNs] didRegister OK, deviceToken=\(hex)")
    // Chuyển thẳng APNs token cho Firebase Messaging — đảm bảo FCM lấy được token
    // kể cả khi swizzling của Firebase không hook (AppDelegate implicit-engine).
    Messaging.messaging().apnsToken = deviceToken
    super.application(
      application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[APNs] didFailToRegister error=\(error.localizedDescription)")
    super.application(
      application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
