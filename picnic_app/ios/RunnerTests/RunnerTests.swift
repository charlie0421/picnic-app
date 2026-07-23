import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

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
