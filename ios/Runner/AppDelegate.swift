import Flutter
import UIKit
import AVFoundation
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let deviceMotionStreamHandler = DeviceMotionStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Allow audio to play even when the device is on silent mode
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .ambient,
        mode: .default,
        options: [.mixWithOthers]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("AVAudioSession setup error: \(error)")
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let deviceMotionChannel = FlutterEventChannel(
        name: "playtimetool/device_motion",
        binaryMessenger: controller.binaryMessenger
      )
      deviceMotionChannel.setStreamHandler(deviceMotionStreamHandler)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

private final class DeviceMotionStreamHandler: NSObject, FlutterStreamHandler {
  private let motionManager = CMMotionManager()

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard motionManager.isDeviceMotionAvailable else {
      events(
        FlutterError(
          code: "device_motion_unavailable",
          message: "CMMotionManager deviceMotion is not available on this device.",
          details: nil
        )
      )
      return nil
    }

    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
      if let error = error {
        events(
          FlutterError(
            code: "device_motion_error",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }

      guard let attitude = motion?.attitude else {
        return
      }

      events([
        "pitch": attitude.pitch,
        "roll": attitude.roll
      ])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motionManager.stopDeviceMotionUpdates()
    return nil
  }
}
