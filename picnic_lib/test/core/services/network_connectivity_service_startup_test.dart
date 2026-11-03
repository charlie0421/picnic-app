import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final interfaces in <List<String>>[
    [],
    ['none'],
  ]) {
    testWidgets('offline interfaces $interfaces finish without a DNS wait', (
      tester,
    ) async {
      messenger.setMockMethodCallHandler(channel, (_) async => interfaces);
      bool? result;
      Object? failure;
      NetworkConnectivityService().checkOnlineStatus().then<void>(
        (value) => result = value,
        onError: (Object error) => failure = error,
      );

      await tester.pump();

      expect(failure, isNull);
      expect(result, false);
    });
  }

  testWidgets('an unresponsive platform check releases startup as offline', (
    tester,
  ) async {
    final reply = Completer<List<String>>();
    messenger.setMockMethodCallHandler(channel, (_) => reply.future);
    bool? result;
    NetworkConnectivityService().checkOnlineStatus().then<void>(
      (value) => result = value,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(result, false);
    // A late platform reply cannot change the result already shown to the app.
    reply.complete(['none']);
    await tester.pump();
    expect(result, false);
  });

  testWidgets('platform failure returns offline instead of aborting startup', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'network-unavailable');
    });
    bool? result;
    Object? failure;
    NetworkConnectivityService().checkOnlineStatus().then<void>(
      (value) => result = value,
      onError: (Object error) => failure = error,
    );
    await tester.pump();
    expect(failure, isNull);
    expect(result, false);
  });
}
