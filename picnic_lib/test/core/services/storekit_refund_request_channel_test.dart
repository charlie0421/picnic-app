import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/storekit_refund_request_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(StoreKitRefundRequestChannel.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  void answer(Future<Object?> Function(MethodCall call) handler) =>
      messenger.setMockMethodCallHandler(channel, handler);

  test('sends the transaction id and reports an approved sheet', () async {
    MethodCall? received;
    answer((call) async {
      received = call;
      return 'success';
    });

    final outcome = await const StoreKitRefundRequestChannel().begin(
      '2000000123456789',
    );

    expect(outcome, StoreKitRefundRequestOutcome.success);
    expect(received?.method, 'beginRefundRequest');
    expect(received?.arguments, {'transactionId': '2000000123456789'});
  });

  test('reports a sheet the tester closed', () async {
    answer((_) async => 'userCancelled');

    expect(
      await const StoreKitRefundRequestChannel().begin('2000000123456789'),
      StoreKitRefundRequestOutcome.userCancelled,
    );
  });

  test('reports a purchase that already has a refund request', () async {
    answer((_) async => throw PlatformException(code: 'DUPLICATE_REQUEST'));

    expect(
      await const StoreKitRefundRequestChannel().begin('2000000123456789'),
      StoreKitRefundRequestOutcome.duplicateRequest,
    );
  });

  test('reports other native failures and unknown answers as failed', () async {
    answer((_) async => throw PlatformException(code: 'REFUND_REQUEST_FAILED'));
    expect(
      await const StoreKitRefundRequestChannel().begin('2000000123456789'),
      StoreKitRefundRequestOutcome.failed,
    );

    answer((_) async => 'somethingNew');
    expect(
      await const StoreKitRefundRequestChannel().begin('2000000123456789'),
      StoreKitRefundRequestOutcome.failed,
    );
  });

  test('reports a build without the native handler as unsupported', () async {
    expect(
      await const StoreKitRefundRequestChannel().begin('2000000123456789'),
      StoreKitRefundRequestOutcome.unsupported,
    );
  });
}
