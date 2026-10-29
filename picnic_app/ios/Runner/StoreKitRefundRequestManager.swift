import Flutter
import StoreKit
import UIKit

/// Opens Apple's refund request sheet for a StoreKit 2 transaction.
///
/// Only the admin test tool (`SandboxRefundRequestPage`) calls this. That tool
/// lists sandbox (TestFlight) purchases only, and in the sandbox Apple approves
/// a submitted request automatically and sends a REFUND server notification.
class StoreKitRefundRequestManager: NSObject {
    private weak var viewController: FlutterViewController?

    init(viewController: FlutterViewController) {
        super.init()
        self.viewController = viewController
    }

    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "beginRefundRequest" else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard let args = call.arguments as? [String: Any],
            let rawTransactionId = args["transactionId"] as? String,
            let transactionId = UInt64(rawTransactionId)
        else {
            result(
                FlutterError(
                    code: "INVALID_TRANSACTION_ID", message: "Invalid transaction id",
                    details: nil))
            return
        }

        Task { @MainActor in
            guard let scene = self.viewController?.view.window?.windowScene else {
                result(
                    FlutterError(
                        code: "NO_WINDOW_SCENE", message: "No window scene", details: nil))
                return
            }
            do {
                let status = try await StoreKit.Transaction.beginRefundRequest(
                    for: transactionId, in: scene)
                switch status {
                case .success:
                    result("success")
                case .userCancelled:
                    result("userCancelled")
                @unknown default:
                    result("unknown")
                }
            } catch StoreKit.Transaction.RefundRequestError.duplicateRequest {
                result(
                    FlutterError(
                        code: "DUPLICATE_REQUEST", message: "Refund already requested",
                        details: nil))
            } catch {
                result(
                    FlutterError(
                        code: "REFUND_REQUEST_FAILED", message: error.localizedDescription,
                        details: nil))
            }
        }
    }
}
