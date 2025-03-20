import Flutter
import PAGAdSDK
import UIKit

/// Pangle iOS 네이티브 구현
public class PangleNativeHandler: NSObject, FlutterPlugin {
    private static var channel: FlutterMethodChannel?
    private var rewardedAd: PAGRewardedAd?
    private var isSDKInitialized = false
    private var appID: String?

    /// Flutter 플러그인 등록
    public static func register(with registrar: FlutterPluginRegistrar) {
        print("PangleNativeHandler 등록 시작")
        channel = FlutterMethodChannel(
            name: "pangle_native_channel",
            binaryMessenger: registrar.messenger())
        let instance = PangleNativeHandler()
        registrar.addMethodCallDelegate(instance, channel: channel!)
        print("PangleNativeHandler 등록 완료")
    }

    /// Flutter 메서드 호출 처리
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("메서드 호출 수신: \(call.method), 인자: \(String(describing: call.arguments))")

        switch call.method {
        case "initPangle":
            if let args = call.arguments as? [String: Any],
                let appId = args["appId"] as? String
            {
                print("Pangle 초기화 시작 - appId: \(appId)")
                self.appID = appId
                self.initPangle(appId: appId) { success, errorMessage in
                    if success {
                        print("Pangle 초기화 성공 - 결과 리턴")
                        result(true)
                    } else {
                        print("Pangle 초기화 실패 - 에러: \(errorMessage)")
                        result(
                            FlutterError(code: "InitFailed", message: errorMessage, details: nil))
                    }
                }
            } else {
                print("Pangle 초기화 실패 - 인자 없음")
                result(FlutterError(code: "InvalidParams", message: "App ID is null", details: nil))
            }
        case "loadRewardedAd":
            if let args = call.arguments as? [String: Any],
                let placementId = args["placementId"] as? String
            {
                if self.isSDKInitialized {
                    self.loadRewardedAd(placementId: placementId, result: result)
                } else if let appId = self.appID {
                    // SDK가 초기화되지 않았다면 다시 초기화 시도 후 광고 로드
                    print("SDK가 초기화되지 않았습니다. 재초기화 시도 중...")
                    self.initPangle(appId: appId) { success, errorMessage in
                        if success {
                            self.loadRewardedAd(placementId: placementId, result: result)
                        } else {
                            result(
                                FlutterError(
                                    code: "InitFailed",
                                    message: "Pangle SDK 초기화 실패: \(errorMessage)", details: nil))
                        }
                    }
                } else {
                    result(
                        FlutterError(
                            code: "NotInitialized", message: "Pangle SDK가 초기화되지 않았습니다", details: nil
                        ))
                }
            } else {
                result(
                    FlutterError(
                        code: "InvalidParams", message: "Placement ID is null", details: nil))
            }
        case "showRewardedAd":
            self.showRewardedAd(result: result)
        default:
            print("지원하지 않는 메서드: \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
}

/// Pangle 광고 관련 기능 구현
extension PangleNativeHandler: PAGRewardedAdDelegate {
    func initPangle(appId: String, completion: @escaping (Bool, String) -> Void) {
        print("initPangle 메서드 호출됨 - appId: \(appId)")

        // 이미 초기화된 상태면 바로 성공 반환
        if isSDKInitialized && self.appID == appId {
            print("Pangle SDK가 이미 초기화되어 있습니다.")
            completion(true, "이미 초기화됨")
            return
        }

        print("PAGConfig 생성 및 설정...")
        let config = PAGConfig.share()
        config.appID = appId

        // 디버그 모드 활성화 및 추가 설정
        #if DEBUG
            print("디버그 모드 활성화")
        #endif

        // 메인 스레드에서 초기화 확실히 보장
        DispatchQueue.main.async {
            print("PAGSdk.start 호출 (메인 스레드)...")
            PAGSdk.start(with: config) { [weak self] success, error in
                guard let self = self else {
                    print("self가 nil이라 초기화 완료 처리 불가")
                    completion(false, "객체가 해제됨")
                    return
                }

                if success {
                    print("Pangle SDK 초기화 성공")
                    self.isSDKInitialized = true
                    self.appID = appId

                    // Pangle SDK 상태 확인
                    print("Pangle SDK 초기화 상태: \(self.isSDKInitialized)")
                    print("Pangle SDK appID: \(self.appID ?? "nil")")

                    completion(true, "성공")
                } else {
                    let errorMessage = error?.localizedDescription ?? "알 수 없는 오류"
                    print("Pangle SDK 초기화 실패: \(errorMessage)")
                    print("에러 상세: \(String(describing: error))")
                    self.isSDKInitialized = false
                    completion(false, errorMessage)
                }
            }
        }
    }

    func loadRewardedAd(placementId: String, result: @escaping FlutterResult) {
        print("리워드 광고 로드 시작 - placementId: \(placementId)")

        // SDK가 초기화되지 않았으면 초기화 상태를 확인
        if !isSDKInitialized {
            print("Pangle SDK가 초기화되지 않았습니다. 초기화 필요")
            result(
                FlutterError(
                    code: "NotInitialized", message: "Pangle SDK가 초기화되지 않았습니다", details: nil))
            return
        }

        // 이전 광고 객체 정리
        self.rewardedAd = nil

        let request = PAGRewardedRequest()

        // 슬롯 ID 로그 출력
        print("PAGRewardedAd.load 호출 준비 - placementId: \(placementId)")

        // 안전 장치: 광고 로드 시도 전 약간의 지연 추가
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 메인 스레드에서 로드 시작
            PAGRewardedAd.load(withSlotID: placementId, request: request) {
                [weak self] (rewardedAd: PAGRewardedAd?, error: Error?) in
                // 메인 스레드에서 콜백 처리 보장
                DispatchQueue.main.async {
                    guard let self = self else {
                        print("self가 nil이라 광고 로드 처리 불가")
                        result(FlutterError(code: "LoadFailed", message: "객체가 해제됨", details: nil))
                        return
                    }

                    if let error = error {
                        print("리워드 광고 로드 실패: \(error.localizedDescription)")
                        print("오류 상세: \(error)")
                        result(
                            FlutterError(
                                code: "LoadFailed", message: error.localizedDescription,
                                details: nil))
                        return
                    }

                    if let rewardedAd = rewardedAd {
                        print("리워드 광고 로드 성공: \(rewardedAd)")
                        self.rewardedAd = rewardedAd
                        self.rewardedAd?.delegate = self
                        // 로드 성공 여부 다시 한번 확인
                        if self.rewardedAd != nil {
                            print("광고 객체 저장 성공")
                            result(true)
                        } else {
                            print("광고 객체 저장 실패")
                            result(
                                FlutterError(
                                    code: "LoadFailed", message: "광고 객체 저장 실패", details: nil))
                        }
                    } else {
                        print("리워드 광고 로드 실패: 광고 객체가 null임")
                        result(
                            FlutterError(
                                code: "LoadFailed", message: "알 수 없는 오류로 광고 로드 실패", details: nil))
                    }
                }
            }
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

    func rewardedAdDidShow(_ rewardedAd: PAGRewardedAd) {
        print("리워드 광고가 표시됨: \(rewardedAd)")
        PangleNativeHandler.channel?.invokeMethod("onAdShowed", arguments: nil)
    }

    func rewardedAdDidClick(_ rewardedAd: PAGRewardedAd) {
        print("리워드 광고가 클릭됨: \(rewardedAd)")
        PangleNativeHandler.channel?.invokeMethod("onAdClicked", arguments: nil)
    }

    func rewardedAdDidClose(_ rewardedAd: PAGRewardedAd) {
        print("리워드 광고가 닫힘: \(rewardedAd)")
        self.rewardedAd = nil
        PangleNativeHandler.channel?.invokeMethod("onAdClosed", arguments: nil)
    }

    func rewardedAd(_ rewardedAd: PAGRewardedAd, didRewardSuccess rewardInfo: PAGRewardModel) {
        print("사용자가 보상을 받음: \(rewardInfo)")
        let rewardData: [String: Any] = [
            "amount": rewardInfo.rewardAmount,
            "name": rewardInfo.rewardName,
        ]
        PangleNativeHandler.channel?.invokeMethod("onUserEarnedReward", arguments: rewardData)
    }
}
