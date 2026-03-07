import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    enableMultiTouch()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    enableMultiTouch()
  }

  private func enableMultiTouch() {
    guard let rootView = window?.rootViewController?.view else {
      return
    }
    enableMultiTouchRecursively(for: rootView)
  }

  private func enableMultiTouchRecursively(for view: UIView) {
    view.isMultipleTouchEnabled = true
    for subview in view.subviews {
      enableMultiTouchRecursively(for: subview)
    }
  }
}
