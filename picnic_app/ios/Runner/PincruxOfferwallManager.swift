import Flutter
import PincruxOfferwall
import UIKit

class PincruxOfferwallManager: NSObject {
    private var offerwall: PincruxOfferwallSDK?
    private var channel: FlutterMethodChannel?

    init(channel: FlutterMethodChannel) {
        super.init()
        self.channel = channel
    }

    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            if let args = call.arguments as? [String: Any],
                let pubkey = args["pubkey"] as? String,
                let usrkey = args["usrkey"] as? String
            {
                self.offerwall = PincruxOfferwallSDK.initWithPubkeyAndUsrkey(pubkey, usrkey)
                result(true)
            } else {
                result(
                    FlutterError(code: "InvalidParams", message: "Invalid parameters", details: nil)
                )
            }

        case "setOfferwallViewControllerType":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let type = args["type"] as? Int
            {
                if type == 1 {
                    self.offerwall?.setViewControllerType(.Modal)
                } else if type == 2 {
                    self.offerwall?.setViewControllerType(.ViewType)
                }
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "startOfferwall":
            if isOfferwallNotNil(),
                let controller = UIApplication.shared.windows.first?.rootViewController
            {
                self.offerwall?.startOfferwall(vc: controller)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "startPincruxOfferwallAdDetail":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let appkey = args["appkey"] as? String,
                let controller = UIApplication.shared.windows.first?.rootViewController
            {
                self.offerwall?.startOfferwallDetailVC(vc: controller, appKey: appkey)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "startPincruxOfferwallContact":
            if isOfferwallNotNil(),
                let controller = UIApplication.shared.windows.first?.rootViewController
            {
                self.offerwall?.startOfferwallContactVC(vc: controller)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setOfferwallType":
            if isOfferwallNotNil(),
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
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setEnableTab":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let isEnable = args["isEnable"] as? Bool
            {
                self.offerwall?.setEnableTab(isEnable)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setOfferwallTitle":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let title = args["title"] as? String
            {
                self.offerwall?.setOfferwallTitle(title)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setOfferwallThemeColor":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let color = args["color"] as? String
            {
                self.offerwall?.setThemeColor(color)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setEnableScrollTopButton":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let isEnable = args["isEnable"] as? Bool
            {
                self.offerwall?.setEnableScrollTopButton(isEnable)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setAdDetail":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let isEnable = args["isEnable"] as? Bool
            {
                self.offerwall?.setAdDetail(isEnable)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setDisableCPS":
            if isOfferwallNotNil(),
                let args = call.arguments as? [String: Any],
                let isDisable = args["isDisable"] as? Bool
            {
                self.offerwall?.setDisableCPS(isDisable)
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        case "setDarkMode":
            if isOfferwallNotNil(),
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
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "NotInitialized", message: "Offerwall not initialized", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func isOfferwallNotNil() -> Bool {
        return self.offerwall != nil
    }
}
