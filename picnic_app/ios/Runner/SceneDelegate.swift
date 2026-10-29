import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        guard let delegate = UIApplication.shared.delegate as? FlutterAppDelegate else { return }

        // Flutter 3.41 does not forward cold links to legacy application callbacks.
        // Plugins are registered by the implicit engine before this replay.
        let urls = connectionOptions.urlContexts.map { context in
            var options: [UIApplication.OpenURLOptionsKey: Any] = [
                .openInPlace: context.options.openInPlace
            ]
            if let source = context.options.sourceApplication {
                options[.sourceApplication] = source
            }
            if let annotation = context.options.annotation {
                options[.annotation] = annotation
            }
            return (context.url, options)
        }
        Self.forwardLaunchEvents(
            activities: Array(connectionOptions.userActivities), urls: urls, to: delegate)
    }

    static func forwardLaunchEvents(
        activities: [NSUserActivity],
        urls: [(URL, [UIApplication.OpenURLOptionsKey: Any])],
        to delegate: FlutterAppDelegate,
        application: UIApplication = .shared
    ) {
        for activity in activities {
            _ = delegate.application(application, continue: activity, restorationHandler: { _ in })
        }
        for (url, options) in urls {
            _ = delegate.application(application, open: url, options: options)
        }
    }
}
