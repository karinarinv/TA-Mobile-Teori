import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Titik awal iOS; Flutter menangani aplikasi dan plugin didaftarkan saat engine siap.
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Daftarkan plugin Flutter supaya fitur native dapat dipanggil dari Dart.
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
