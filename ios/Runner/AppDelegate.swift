import Flutter
import UIKit
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pipChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configurer l'audio session pour le PiP
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
      try audioSession.setActive(true)
    } catch {
      print("Failed to configure audio session: \(error)")
    }
    
    // Configurer le MethodChannel pour le PiP
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    pipChannel = FlutterMethodChannel(
      name: "movi/native_pip",
      binaryMessenger: controller.binaryMessenger
    )
    
    pipChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isSupported":
        // Le PiP est supporté sur iOS 15+ avec AVPlayerViewController
        // media_kit devrait gérer cela automatiquement
        result(true)
      case "enter":
        // Sur iOS, le PiP est généralement géré automatiquement par AVPlayerViewController
        // via media_kit. On notifie juste Flutter que c'est supporté.
        result(nil)
      case "exit":
        // Sur iOS, l'utilisateur contrôle le PiP via les contrôles système
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
