import Flutter
import PAGAdSDK
import UIKit

class PangleAdManager: NSObject {
    private var rewardedAd: PAGRewardedAd?
    private var appID: String?
    private var channel: FlutterMethodChannel?

    init(channel: FlutterMethodChannel) {
        super.init()
        self.channel = channel
    }

    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initPangle":
            if let args = call.arguments as? [String: Any],
                let appId = args["appId"] as? String
            {
                initPangle(appId: appId) { success, errorMessage in
                    if success {
                        result(true)
                    } else {
                        result(
                            FlutterError(code: "InitFailed", message: errorMessage, details: nil))
                    }
                }
            }
        case "loadRewardedAd":
            if let args = call.arguments as? [String: Any],
                let placementId = args["placementId"] as? String,
                let userId = args["userId"] as? String
            {
                loadRewardedAd(placementId: placementId, userId: userId, result: result)
            } else {
                result(
                    FlutterError(code: "InvalidParams", message: "Invalid parameters", details: nil)
                )
            }
        case "showRewardedAd":
            showRewardedAd(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initPangle(appId: String, completion: @escaping (Bool, String) -> Void) {
        print("Flutter에서 Pangle SDK 초기화 시작 - appId: \(appId)")

        print("PAGConfig 생성 및 설정...")
        let config = PAGConfig.share()
        config.appID = appId

        #if DEBUG
            print("디버그 모드 활성화: 로그 레벨 설정")
            config.debugLog = true
        #endif

        PAGSdk.start(with: config) { success, error in
            if success {
                print("Pangle SDK 초기화 성공!")
                completion(true, "성공")
            } else {
                let errorMessage = error?.localizedDescription ?? "알 수 없는 오류"
                print("Pangle SDK 초기화 실패: \(errorMessage)")
                completion(false, errorMessage)
            }
        }
    }

    private func loadRewardedAd(
        placementId: String, userId: String, result: @escaping FlutterResult
    ) {
        print("리워드 광고 로드 시작 - placementId: \(placementId), userId: \(userId)")

        self.rewardedAd = nil

        let request = PAGRewardedRequest()
        let extraInfo = ["media_extra": "\(userId),ios"]
        request.extraInfo = extraInfo

        print("PAGRewardedAd.load 호출 준비 - placementId: \(placementId)")

        PAGRewardedAd.load(withSlotID: placementId, request: request) {
            [weak self] rewardedAd, error in
            if let error = error {
                print("리워드 광고 로드 실패: \(error.localizedDescription)")
                result(false)
                return
            }
            guard let strongSelf = self, let ad = rewardedAd else {
                print("광고 객체가 nil입니다.")
                result(false)
                return
            }
            strongSelf.rewardedAd = ad
            strongSelf.rewardedAd?.delegate = strongSelf
            print("리워드 광고 로드 성공! - delegate 설정됨: \(String(describing: type(of: strongSelf)))")
            result(true)
        }
    }

    private func showRewardedAd(result: @escaping FlutterResult) {
        guard let rewardedAd = rewardedAd else {
            print("리워드 광고 표시 실패: 광고 객체가 nil입니다")
            result(FlutterError(code: "ShowFailed", message: "리워드 광고가 준비되지 않았습니다", details: nil))
            return
        }

        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            print("리워드 광고 표시 실패: keyWindow를 찾을 수 없습니다")
            result(FlutterError(code: "ShowFailed", message: "keyWindow를 찾을 수 없습니다", details: nil))
            return
        }

        guard let rootVC = keyWindow.rootViewController else {
            print("리워드 광고 표시 실패: rootViewController를 찾을 수 없습니다")
            result(
                FlutterError(
                    code: "ShowFailed", message: "rootViewController를 찾을 수 없습니다", details: nil))
            return
        }

        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        DispatchQueue.main.async {
            rewardedAd.delegate = self

            if let ad = self.rewardedAd {
                ad.delegate = self
                ad.present(fromRootViewController: topVC)
                result(true)
            } else {
                result(FlutterError(code: "ShowFailed", message: "광고 객체가 nil이 되었습니다", details: nil))
            }
        }
    }
}

// MARK: - PAGRewardedAdDelegate
extension PangleAdManager: PAGRewardedAdDelegate {
    func adDidShow(_ ad: PAGRewardedAd) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE adDidShow 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("기기: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        print("\n\n")

        DispatchQueue.main.async {
            if let channel = self.channel {
                let timestamp = Date().timeIntervalSince1970
                let simpleArgs: [String: Any] = ["timestamp": timestamp]

                channel.invokeMethod("onAdShown", arguments: simpleArgs) { error in
                    if let error = error {
                        print("⚠️ 이벤트 전송 실패: \(error)")
                    } else {
                        print("✅ onAdShown 이벤트가 성공적으로 전송됨!")
                    }
                }
            }
        }
    }

    func adDidClick(_ ad: PAGRewardedAd) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE adDidClick 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("\n\n")

        DispatchQueue.main.async {
            if let channel = self.channel {
                let timestamp = Date().timeIntervalSince1970
                let simpleArgs: [String: Any] = ["timestamp": timestamp]

                channel.invokeMethod("onAdClicked", arguments: simpleArgs) { error in
                    if let error = error {
                        print("⚠️ 이벤트 전송 실패: \(error)")
                    } else {
                        print("✅ onAdClicked 이벤트가 성공적으로 전송됨!")
                    }
                }
            }
        }
    }

    func adDidDismiss(_ ad: PAGRewardedAd) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE adDidDismiss 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("기기: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        print("\n\n")

        var retryCount = 0
        let maxRetries = 3

        func sendDismissEvent() {
            DispatchQueue.main.async {
                if let channel = self.channel {
                    let timestamp = Date().timeIntervalSince1970
                    let simpleArgs: [String: Any] = [
                        "timestamp": timestamp,
                        "success": true,
                    ]

                    channel.invokeMethod("onAdDismissed", arguments: simpleArgs) { error in
                        if let error = error {
                            print("⚠️ 이벤트 전송 실패: \(error)")

                            retryCount += 1
                            if retryCount < maxRetries {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    sendDismissEvent()
                                }
                            } else {
                                print("최대 재시도 횟수 초과. 이벤트 전송 실패")

                                channel.invokeMethod("onAdClosed", arguments: simpleArgs) { error in
                                    if let error = error {
                                        print("⚠️ 대체 이벤트도 전송 실패: \(error)")
                                    } else {
                                        print("✅ 대체 이벤트 전송 성공")
                                    }
                                }
                            }
                        } else {
                            print("✅ onAdDismissed 이벤트가 성공적으로 전송됨!")
                        }
                    }
                }
            }
        }

        sendDismissEvent()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if retryCount < maxRetries {
                if self.channel != nil {
                    sendDismissEvent()
                }
            }
        }

        self.rewardedAd = nil
    }

    func rewardedAd(_ rewardedAd: PAGRewardedAd, userDidEarnReward rewardModel: PAGRewardModel) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE userDidEarnReward 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("보상 이름: \(rewardModel.rewardName ?? ""), 수량: \(rewardModel.rewardAmount)")
        print("\n\n")

        DispatchQueue.main.async {
            if let channel = self.channel {
                let arguments: [String: Any] = [
                    "rewardName": rewardModel.rewardName ?? "",
                    "rewardAmount": rewardModel.rewardAmount,
                    "timestamp": Date().timeIntervalSince1970,
                ]

                channel.invokeMethod("onRewardEarned", arguments: arguments) { error in
                    if let error = error {
                        print("⚠️ 이벤트 전송 실패: \(error)")
                    } else {
                        print("✅ onRewardEarned 이벤트가 성공적으로 전송됨!")
                    }
                }
            }
        }
    }

    func rewardedAd(_ rewardedAd: PAGRewardedAd, userEarnRewardFailWithError error: Error) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE userEarnRewardFailWithError 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("오류 메시지: \(error.localizedDescription)")
        print("에러 상세: \(error)")
        print("\n\n")

        DispatchQueue.main.async {
            if let channel = self.channel {
                let arguments: [String: Any] = [
                    "errorMessage": error.localizedDescription,
                    "timestamp": Date().timeIntervalSince1970,
                ]

                channel.invokeMethod("onRewardFailed", arguments: arguments) { error in
                    if let error = error {
                        print("⚠️ 이벤트 전송 실패: \(error)")
                    } else {
                        print("✅ onRewardFailed 이벤트가 성공적으로 전송됨!")
                    }
                }
            }
        }
    }
}
