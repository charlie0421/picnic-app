import 'package:flutter/services.dart';

/// Result of asking StoreKit 2 to show Apple's refund request sheet.
enum StoreKitRefundRequestOutcome {
  /// The tester submitted the sheet. In the sandbox, Apple approves it.
  success,

  /// The tester closed the sheet without submitting.
  userCancelled,

  /// Apple already has a refund request for this transaction.
  duplicateRequest,

  failed,

  /// This build has no native handler (for example, a non-iOS host).
  unsupported,
}

/// Opens Apple's refund request sheet through the iOS Runner's
/// `StoreKitRefundRequestManager` (`Transaction.beginRefundRequest`).
class StoreKitRefundRequestChannel {
  const StoreKitRefundRequestChannel({
    MethodChannel channel = const MethodChannel(channelName),
  }) : _channel = channel;

  static const String channelName = 'picnic/storekit_refund_request';

  final MethodChannel _channel;

  Future<StoreKitRefundRequestOutcome> begin(String transactionId) async {
    try {
      final status = await _channel.invokeMethod<String>('beginRefundRequest', {
        'transactionId': transactionId,
      });
      return switch (status) {
        'success' => StoreKitRefundRequestOutcome.success,
        'userCancelled' => StoreKitRefundRequestOutcome.userCancelled,
        _ => StoreKitRefundRequestOutcome.failed,
      };
    } on PlatformException catch (e) {
      return e.code == 'DUPLICATE_REQUEST'
          ? StoreKitRefundRequestOutcome.duplicateRequest
          : StoreKitRefundRequestOutcome.failed;
    } on MissingPluginException {
      return StoreKitRefundRequestOutcome.unsupported;
    }
  }
}
