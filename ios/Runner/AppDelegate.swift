import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let controller = engineBridge.pluginRegistry as? FlutterViewController
        ?? (window?.rootViewController as? FlutterViewController)

    if let flutterController = controller {
      let channel = FlutterMethodChannel(
        name: "com.pocketnoc/network",
        binaryMessenger: flutterController.binaryMessenger
      )

      let networkHandler = NetworkChannelHandler()
      channel.setMethodCallHandler(networkHandler.handle)
    }
  }
}
