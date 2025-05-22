import Flutter
import PAGAdSDK
import PincruxOfferwall
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    var offerwall: PincruxOfferwallSDK?
    private var pangleAdManager: PangleAdManager?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        // Pangle 채널 생성 및 저장
        let pangleChannel = FlutterMethodChannel(
            name: "pangle_native_channel",
            binaryMessenger: controller.binaryMessenger)

        // Pangle 광고 매니저 초기화
        pangleAdManager = PangleAdManager(channel: pangleChannel)

        // Pangle 채널 메소드 핸들러 설정
        pangleChannel.setMethodCallHandler { [weak self] call, result in
            self?.pangleAdManager?.handleMethodCall(call, result: result)
        }

        let methodChannel = FlutterMethodChannel(
            name: "com.pincrux.offerwall.flutter", binaryMessenger: controller.binaryMessenger)

        methodChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

            switch call.method {
            case "init":
                if let args = call.arguments as? [String: Any],
                    let pubkey = args["pubkey"] as? String,
                    let usrkey = args["usrkey"] as? String
                {
                    self.offerwall = PincruxOfferwallSDK.initWithPubkeyAndUsrkey(pubkey, usrkey)
                }

            case "setOfferwallViewControllerType":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let type = args["type"] as? Int
                {
                    if type == 1 {
                        self.offerwall?.setViewControllerType(.Modal)
                    } else if type == 2 {
                        self.offerwall?.setViewControllerType(.ViewType)
                    }
                }

            case "startOfferwall":
                if self.isOfferwallNotNil() {
                    self.offerwall?.startOfferwall(vc: controller)
                }

            case "startPincruxOfferwallAdDetail":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let appkey = args["appkey"] as? String
                {
                    self.offerwall?.startOfferwallDetailVC(vc: controller, appKey: appkey)
                }

            case "startPincruxOfferwallContact":
                if self.isOfferwallNotNil() {
                    self.offerwall?.startOfferwallContactVC(vc: controller)
                }

            case "setOfferwallType":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let type = args["type"] as? Int
                {
                    if type == 2 {
                        self.offerwall?.setOfferwallType(.BAR_PREMIUM_TYPE)
                    } else if type == 3 {
                        self.offerwall?.setOfferwallType(.PREMIUM_TYPE)
                    } else {
                        self.offerwall?.setOfferwallType(.BAR_TYPE)
                    }
                }

            case "setEnableTab":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let isEnable = args["isEnable"] as? Bool
                {
                    self.offerwall?.setEnableTab(isEnable)
                }

            case "setOfferwallTitle":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let title = args["title"] as? String
                {
                    self.offerwall?.setOfferwallTitle(title)
                }

            case "setOfferwallThemeColor":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let color = args["color"] as? String
                {
                    self.offerwall?.setThemeColor(color)
                }

            case "setEnableScrollTopButton":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let isEnable = args["isEnable"] as? Bool
                {
                    self.offerwall?.setEnableScrollTopButton(isEnable)
                }

            case "setAdDetail":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let isEnable = args["isEnable"] as? Bool
                {
                    self.offerwall?.setAdDetail(isEnable)
                }

            case "setDisableCPS":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let isDisable = args["isDisable"] as? Bool
                {
                    self.offerwall?.setDisableCPS(isDisable)
                }

            case "setDarkMode":
                if self.isOfferwallNotNil(),
                    let args = call.arguments as? [String: Any],
                    let mode = args["mode"] as? Int
                {
                    if mode == 0 {
                        self.offerwall?.setDarkMode(.AUTO)
                    } else if mode == 2 {
                        self.offerwall?.setDarkMode(.DARK_ONLY)
                    } else {
                        self.offerwall?.setDarkMode(.LIGHT_ONLY)
                    }
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func isOfferwallNotNil() -> Bool {
        if self.offerwall != nil {
            return true
        } else {
            return false
        }
    }
}
