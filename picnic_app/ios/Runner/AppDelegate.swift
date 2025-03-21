import Flutter
import PAGAdSDK
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var rewardedAd: PAGRewardedAd?
    private var appID: String?
    private var channel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Pangle SDK 환경 진단 정보
        print("==== Pangle SDK 진단 정보 ====")
        print("iOS 버전: \(UIDevice.current.systemVersion)")
        print("앱 번들 ID: \(Bundle.main.bundleIdentifier ?? "알 수 없음")")
        print("기기 모델: \(UIDevice.current.model)")
        print("화면 크기: \(UIScreen.main.bounds)")
        print("============================")

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        // 채널 생성 및 저장
        channel = FlutterMethodChannel(
            name: "pangle_native_channel",
            binaryMessenger: controller.binaryMessenger)

        channel?.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "initPangle":
                if let args = call.arguments as? [String: Any],
                    let appId = args["appId"] as? String
                {
                    self.initPangle(appId: appId) { success, errorMessage in
                        if success {
                            result(true)
                        } else {
                            result(
                                FlutterError(
                                    code: "InitFailed", message: errorMessage, details: nil))
                        }
                    }
                }
            case "loadRewardedAd":
                if let args = call.arguments as? [String: Any],
                    let placementId = args["placementId"] as? String,
                    let userId = args["userId"] as? String
                {
                    self.loadRewardedAd(placementId: placementId, userId: userId, result: result)
                } else {
                    result(
                        FlutterError(
                            code: "InvalidParams", message: "Invalid parameters", details: nil))
                }
            case "showRewardedAd":
                self.showRewardedAd(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

extension AppDelegate: PAGRewardedAdDelegate {
    func initPangle(appId: String, completion: @escaping (Bool, String) -> Void) {
        print("Flutter에서 Pangle SDK 초기화 시작 - appId: \(appId)")

        print("PAGConfig 생성 및 설정...")
        let config = PAGConfig.share()
        config.appID = appId

        // 디버그 모드 활성화 및 추가 설정
        #if DEBUG
            print("디버그 모드 활성화: 로그 레벨 설정")
            config.debugLog = true
        #endif

        // 메인 스레드에서 초기화 확실히 보장
        PAGSdk.start(with: config) { success, error in
            if success {
                print("Pangle SDK 초기화 성공!")
                completion(true, "성공")
                // 여기서부터 광고 로드 등 추가 로직을 호출할 수 있습니다.
            } else {
                let errorMessage = error?.localizedDescription ?? "알 수 없는 오류"
                print("Pangle SDK 초기화 실패: \(errorMessage)")
                completion(false, errorMessage)
            }
        }
    }

    func loadRewardedAd(placementId: String, userId: String, result: @escaping FlutterResult) {
        print("리워드 광고 로드 시작 - placementId: \(placementId), userId: \(userId)")

        // 이전 광고 객체 정리
        self.rewardedAd = nil

        let request = PAGRewardedRequest()
        let extraInfo = ["media_extra": "\(userId),ios"]
        request.extraInfo = extraInfo

        // 슬롯 ID 로그 출력
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
            NSLog(
                "PANGLE_AD_DEBUG: Rewarded ad loaded successfully, delegate set to %@",
                String(describing: type(of: strongSelf)))
            result(true)
        }
    }

    func showRewardedAd(result: @escaping FlutterResult) {
        guard let rewardedAd = rewardedAd else {
            print("리워드 광고 표시 실패: 광고 객체가 nil입니다")
            result(FlutterError(code: "ShowFailed", message: "리워드 광고가 준비되지 않았습니다", details: nil))
            return
        }

        print("정확한 rootViewController 찾기 시도 중...")

        // rootViewController를 더 정확하게 찾기
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

        // 가장 상위의 표시 중인 뷰컨트롤러 찾기
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        print("광고 표시에 사용할 뷰컨트롤러: \(topVC)")

        // 메인 스레드에서 확실하게 실행
        DispatchQueue.main.async {
            print("리워드 광고 표시 시작")

            // 기존 광고가 표시 중인지 확인 후 표시
            rewardedAd.delegate = self

            // 광고 표시 전에 delegate를 다시 한번 명시적으로 설정
            if let ad = self.rewardedAd {
                ad.delegate = self
                ad.present(fromRootViewController: topVC)
                print("present(fromRootViewController:) 메서드 호출됨")
                result(true)
            } else {
                print("리워드 광고 표시 실패: 마지막 순간에 광고 객체가 nil이 됨")
                result(FlutterError(code: "ShowFailed", message: "광고 객체가 nil이 되었습니다", details: nil))
            }
        }
    }

    // MARK: - PAGRewardedAdDelegate

    func adDidShow(_ ad: PAGRewardedAd) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE adDidShow 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("기기: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        print("\n\n")

        NSLog("PANGLE_AD_DEBUG: adDidShow called at %@", Date().description)

        // 메인 스레드에서 실행 보장
        DispatchQueue.main.async {
            // 채널 상태 확인
            if let channel = self.channel {
                print("채널이 유효함 - onAdShown 이벤트 전송 시도")

                let timestamp = Date().timeIntervalSince1970
                let simpleArgs: [String: Any] = ["timestamp": timestamp]

                channel.invokeMethod("onAdShown", arguments: simpleArgs) { error in
                    if let error = error {
                        print("⚠️ 이벤트 전송 실패: \(error)")
                    } else {
                        print("✅ onAdShown 이벤트가 성공적으로 전송됨!")
                    }
                }
            } else {
                print("⚠️ 채널이 nil - 이벤트를 전송할 수 없음")
            }
        }

        print("========= 광고 표시 처리 완료 =========")
    }

    func adDidClick(_ ad: PAGRewardedAd) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE adDidClick 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("\n\n")

        NSLog("PANGLE_AD_DEBUG: adDidClick called at %@", Date().description)

        // 메인 스레드에서 실행 보장
        DispatchQueue.main.async {
            // 채널 상태 확인
            if let channel = self.channel {
                print("채널이 유효함 - onAdClicked 이벤트 전송 시도")

                let timestamp = Date().timeIntervalSince1970
                let simpleArgs: [String: Any] = ["timestamp": timestamp]

                channel.invokeMethod("onAdClicked", arguments: simpleArgs) { error in
                    if let error = error {
                        print("⚠️ 이벤트 전송 실패: \(error)")
                    } else {
                        print("✅ onAdClicked 이벤트가 성공적으로 전송됨!")
                    }
                }
            } else {
                print("⚠️ 채널이 nil - 이벤트를 전송할 수 없음")
            }
        }

        print("========= 광고 클릭 처리 완료 =========")
    }

    func adDidDismiss(_ ad: PAGRewardedAd) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE adDidDismiss 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("기기: \(UIDevice.current.model), iOS \(UIDevice.current.systemVersion)")
        print("\n\n")

        // 이전 코드 계속 실행...
        print("!!!!!!!!!!! 리워드 광고가 닫힘 감지 - 이벤트 전송 시작 !!!!!!!!!!!")
        print("닫힌 광고 객체: \(ad)")

        // 디버그용 NSLog (Xcode 콘솔에 반드시 표시됨)
        NSLog("PANGLE_AD_DEBUG: adDidDismiss called at %@", Date().description)

        // 이벤트가 반드시 전송되도록 타이머 설정
        var retryCount = 0
        let maxRetries = 3

        func sendDismissEvent() {
            // 메인 스레드에서 실행 보장
            DispatchQueue.main.async {
                // 채널 상태 확인
                if let channel = self.channel {
                    print("채널이 유효함 - onAdDismissed 이벤트 전송 시도 #\(retryCount + 1)")

                    // 직접 Channel 호출 여부 디버깅
                    let timestamp = Date().timeIntervalSince1970
                    NSLog("PANGLE_AD_DEBUG: Attempting to invoke method at %f", timestamp)

                    // 간단한 인자로 전송 (복잡한 객체는 피함)
                    let simpleArgs: [String: Any] = [
                        "timestamp": timestamp,
                        "success": true,
                    ]

                    channel.invokeMethod("onAdDismissed", arguments: simpleArgs) { error in
                        if let error = error {
                            print("⚠️ 이벤트 전송 실패: \(error)")

                            // 재시도 로직
                            retryCount += 1
                            if retryCount < maxRetries {
                                print("재시도 중... (\(retryCount)/\(maxRetries))")
                                // 잠시 대기 후 재시도
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    sendDismissEvent()
                                }
                            } else {
                                print("최대 재시도 횟수 초과. 이벤트 전송 실패")

                                // 마지막 시도: 다른 이벤트 명으로 시도
                                print("마지막 시도: 대체 이벤트 이름으로 전송 시도")
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
                            NSLog("PANGLE_AD_DEBUG: Event sent successfully")
                        }
                    }
                } else {
                    print("⚠️ 채널이 nil - 이벤트를 전송할 수 없음")
                    NSLog("PANGLE_AD_DEBUG: Channel is nil, can't send event")
                }
            }
        }

        // 최초 전송 시도
        sendDismissEvent()

        // 한번 더 지연 후 전송 시도 (보험)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if retryCount < maxRetries {
                print("지연 후 추가 전송 시도...")
                // 채널 다시 확인
                if self.channel != nil {
                    sendDismissEvent()
                }
            }
        }

        print("리워드 광고 객체 정리 중")
        self.rewardedAd = nil
        print("!!!!!!!!!!! 광고 닫힘 처리 완료 !!!!!!!!!!!")
    }

    func rewardedAd(_ rewardedAd: PAGRewardedAd, userDidEarnReward rewardModel: PAGRewardModel) {
        print("\n\n")
        print("==================================================")
        print("✅✅✅ PANGLE userDidEarnReward 메서드 호출됨 ✅✅✅")
        print("==================================================")
        print("시간: \(Date())")
        print("보상 이름: \(rewardModel.rewardName ?? ""), 수량: \(rewardModel.rewardAmount)")
        print("\n\n")

        NSLog(
            "PANGLE_AD_DEBUG: userDidEarnReward called at %@, reward: %@, amount: %ld",
            Date().description,
            rewardModel.rewardName ?? "",
            rewardModel.rewardAmount)

        // 메인 스레드에서 실행 보장
        DispatchQueue.main.async {
            // 채널 상태 확인
            if let channel = self.channel {
                print("채널이 유효함 - onRewardEarned 이벤트 전송 시도")

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
            } else {
                print("⚠️ 채널이 nil - 이벤트를 전송할 수 없음")
            }
        }

        print("========= 보상 지급 처리 완료 =========")
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

        NSLog(
            "PANGLE_AD_DEBUG: userEarnRewardFailWithError called at %@, error: %@",
            Date().description,
            error.localizedDescription)

        // 메인 스레드에서 실행 보장
        DispatchQueue.main.async {
            // 채널 상태 확인
            if let channel = self.channel {
                print("채널이 유효함 - onRewardFailed 이벤트 전송 시도")

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
            } else {
                print("⚠️ 채널이 nil - 이벤트를 전송할 수 없음")
            }
        }

        print("========= 보상 실패 처리 완료 =========")
    }
}
