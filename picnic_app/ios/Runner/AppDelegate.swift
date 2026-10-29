import Flutter
import UserNotifications
#if canImport(PAGAdSDK)
import PAGAdSDK
#endif
import PincruxOfferwall
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var pangleAdManager: PangleAdManager?
    private var pincruxOfferwallManager: PincruxOfferwallManager?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 푸시 등록은 엔진과 무관한 앱 생명주기에서 유지한다.
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        let messenger = engineBridge.applicationRegistrar.messenger()

        #if canImport(PAGAdSDK)
        // Pangle 채널 생성 및 저장
        let pangleChannel = FlutterMethodChannel(
            name: "pangle_native_channel",
            binaryMessenger: messenger)

        // Pangle 광고 매니저 초기화
        pangleAdManager = PangleAdManager(channel: pangleChannel)

        // Pangle 채널 메소드 핸들러 설정
        pangleChannel.setMethodCallHandler { [weak self] call, result in
            self?.pangleAdManager?.handleMethodCall(call, result: result)
        }
        #endif

        // Pincrux 채널 생성 및 저장
        let pincruxChannel = FlutterMethodChannel(
            name: "com.pincrux.offerwall.flutter",
            binaryMessenger: messenger)

        // Pincrux 오퍼월 매니저 초기화
        pincruxOfferwallManager = PincruxOfferwallManager(channel: pincruxChannel)

        // Pincrux 채널 메소드 핸들러 설정
        pincruxChannel.setMethodCallHandler { [weak self] call, result in
            self?.pincruxOfferwallManager?.handleMethodCall(call, result: result)
        }
    }

    // iOS 포그라운드 알림 표시 설정
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
}
