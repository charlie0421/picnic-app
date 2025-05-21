import Flutter
import PAGAdSDK
import PincruxOfferwall
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var pangleAdManager: PangleAdManager?
    private var pincruxOfferwallManager: PincruxOfferwallManager?

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

        // Pincrux 채널 생성 및 저장
        let pincruxChannel = FlutterMethodChannel(
            name: "com.pincrux.offerwall.flutter",
            binaryMessenger: controller.binaryMessenger)

        // Pincrux 오퍼월 매니저 초기화
        pincruxOfferwallManager = PincruxOfferwallManager(channel: pincruxChannel)

        // Pincrux 채널 메소드 핸들러 설정
        pincruxChannel.setMethodCallHandler { [weak self] call, result in
            self?.pincruxOfferwallManager?.handleMethodCall(call, result: result)
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
