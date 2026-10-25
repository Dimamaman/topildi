import FirebaseAuth
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // With UIScene, URLs opened in the app arrive here, not at the app delegate that
  // Firebase Auth hooks into. Hand its reCAPTCHA return URL over explicitly, or phone
  // sign-in never gets past the check; everything else goes to Flutter as before.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if URLContexts.contains(where: { Auth.auth().canHandle($0.url) }) { return }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
