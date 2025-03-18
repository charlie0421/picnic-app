import Flutter
import UIKit

public class SwiftPangleCustomPluginPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // PangleNativeHandler를 메인 핸들러로 등록
    PangleNativeHandler.register(with: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // 구현이 PangleNativeHandler로 위임됨
    result(FlutterMethodNotImplemented)
  }
} 