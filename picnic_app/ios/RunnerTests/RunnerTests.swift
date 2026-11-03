import Flutter
import UIKit
import UserNotifications
import ObjectiveC
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testNotificationDelegateRemainsTheApplicationDelegate() {
    XCTAssertTrue(UNUserNotificationCenter.current().delegate === UIApplication.shared.delegate)
    XCTAssertTrue(UIApplication.shared.delegate is AppDelegate)
  }

  func testMessagingSceneCallbackUsesTheFlutterBooleanABI() throws {
    // The old void signature could consume a cold link with an undefined return value.
    let plugin = try XCTUnwrap(NSClassFromString("FLTFirebaseMessagingPlugin"))
    let method = try XCTUnwrap(class_getInstanceMethod(
      plugin, NSSelectorFromString("scene:willConnectToSession:options:")))
    let returnType = try XCTUnwrap(method_copyReturnType(method))
    defer { free(returnType) }
    XCTAssertTrue(["B", "c"].contains(String(cString: returnType)))
  }

  func testColdLaunchDeliversUniversalLinkWithRestorationHandler() {
    let delegate = LaunchEventDelegate()
    let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    activity.webpageURL = URL(string: "https://example.invalid/foldable")!
    SceneDelegate.forwardLaunchEvents(activities: [activity], urls: [], to: delegate)
    XCTAssertEqual(delegate.activities.count, 1)
    XCTAssertTrue(delegate.activities.first === activity)
  }

  func testColdLaunchPreservesSchemeURLAndSourceOptions() {
    let delegate = LaunchEventDelegate()
    let url = URL(string: "io.iconcasting.picnic.app://foldable-test?value=1")!
    let options: [UIApplication.OpenURLOptionsKey: Any] = [
      .sourceApplication: "com.apple.mobilesafari", .openInPlace: true,
      .annotation: ["test": "preserved"]
    ]
    SceneDelegate.forwardLaunchEvents(activities: [], urls: [(url, options)], to: delegate)
    XCTAssertEqual(delegate.urls, [url])
    XCTAssertEqual(delegate.options.first?[.sourceApplication] as? String, "com.apple.mobilesafari")
    XCTAssertEqual(delegate.options.first?[.openInPlace] as? Bool, true)
    XCTAssertEqual(delegate.options.first?[.annotation] as? [String: String], ["test": "preserved"])
  }

  func testPlainLaunchDoesNotFabricateLinkEvents() {
    let delegate = LaunchEventDelegate()
    SceneDelegate.forwardLaunchEvents(activities: [], urls: [], to: delegate)
    XCTAssertTrue(delegate.activities.isEmpty)
    XCTAssertTrue(delegate.urls.isEmpty)
  }

  func testPangleMediaExtraAcceptsAndPreservesSignedV2Value() throws {
    let value = "user-a,ios,v2.signed-token"
    XCTAssertEqual(try PangleMediaExtra.requireV2(value), value)
  }

  func testPangleMediaExtraRejectsInvalidValues() {
    for value in ["user-a,ios,v2.", "user-a,android,v2.token", ",ios,v2.token"] {
      XCTAssertThrowsError(try PangleMediaExtra.requireV2(value))
    }
  }

  func testPangleSdkEnvironmentDefaultsToProtectedProduction() {
    XCTAssertEqual(PangleSdkEnvironment.parse(nil), .prod)
    XCTAssertEqual(PangleSdkEnvironment.parse("sandbox"), .sandbox)
    XCTAssertNil(PangleSdkEnvironment.parse("invalid"))
  }

}

private final class LaunchEventDelegate: FlutterAppDelegate {
  var activities: [NSUserActivity] = []
  var urls: [URL] = []
  var options: [[UIApplication.OpenURLOptionsKey: Any]] = []

  override func application(_ application: UIApplication, continue activity: NSUserActivity,
                           restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    activities.append(activity)
    restorationHandler([])
    return true
  }

  override func application(_ app: UIApplication, open url: URL,
                           options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    urls.append(url)
    self.options.append(options)
    return true
  }
}
