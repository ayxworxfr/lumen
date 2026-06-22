import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // 注册 AVIF 编码插件（iOS 16+）
    if #available(iOS 16.0, *) {
      if let controller = window?.rootViewController as? FlutterViewController {
        AvifEncoderPlugin.register(with: registrar(forPlugin: "AvifEncoderPlugin")!)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
