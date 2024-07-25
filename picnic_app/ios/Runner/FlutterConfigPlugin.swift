import Foundation
import flutter_config

@objc public class FlutterConfigPlugin: NSObject {
  @objc public class func env(for name: String) -> [String: Any] {
    var filename = ".env"
    if let dotenvPath = ProcessInfo.processInfo.environment["DOTENV_PATH"] {
      filename = dotenvPath
    }
    return FlutterConfigPlugin.env(for: name, filename: filename)
  }
}