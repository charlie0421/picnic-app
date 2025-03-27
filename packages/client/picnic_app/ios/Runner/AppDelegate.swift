import Flutter
import PAGAdSDK
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var pangleAdManager: PangleAdManager?

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

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
