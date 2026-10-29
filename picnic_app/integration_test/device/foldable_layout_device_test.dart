// Runs the production layout without initializing Picnic backend services.
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/ui/fixed_width_layout.dart';

const _inputKey = ValueKey('foldable-input');

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(condition(), isTrue,
      reason: 'Native metrics did not reach the expected state');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase Core can initialize an isolated native app',
      (tester) async {
    // A demo project and named app exercise the real native bridge without
    // requesting a push token, signing in, or writing Analytics events.
    final app = await Firebase.initializeApp(
      name: 'foldable-regression',
      options: const FirebaseOptions(
        apiKey: 'AIza00000000000000000000000000000000000',
        appId: '1:1234567890:ios:0123456789abcdef',
        messagingSenderId: '1234567890',
        projectId: 'demo-foldable-regression',
      ),
    );
    expect(app.options.projectId, 'demo-foldable-regression');
    expect(Firebase.app('foldable-regression').name, app.name);
    // Keep the app until process exit. Immediate deletion races Android's
    // eager Firebase Installations task; production does not delete apps.
  });

  testWidgets('Messaging reads native notification settings without a prompt',
      (tester) async {
    final settings = await const MethodChannel(
      'plugins.flutter.io/firebase_messaging',
    ).invokeMapMethod<String, dynamic>('Messaging#getNotificationSettings');
    expect(settings, isNotNull);
    // Messaging 17 uses -1 for notDetermined (including Android 13+).
    expect(settings!['authorizationStatus'], isIn([-1, 0, 1, 2, 3]));
  });

  testWidgets(
      'native viewport and keyboard reach the content without losing input',
      (tester) async {
    tester.testTextInput.unregister();
    final controller = TextEditingController(text: 'foldable-input');
    addTearDown(controller.dispose);
    MediaQueryData? live;
    MediaQueryData? inherited;
    double? contentWidth;
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      home: Builder(builder: (context) {
        live = MediaQuery.of(context);
        return FixedWidthLayout(child: LayoutBuilder(builder: (context, c) {
          inherited = MediaQuery.of(context);
          contentWidth = c.maxWidth;
          return Scaffold(
            appBar: AppBar(title: const Text('Picnic foldable verification')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Expanded(
                    child: SingleChildScrollView(
                        child: Text(
                  'Production FixedWidthLayout / test screen\n'
                  'Window: ${live!.size}\nContent: $contentWidth\n'
                  'Inherited width: ${inherited!.size.width}\n'
                  'Keyboard: ${live!.viewInsets.bottom} / ${inherited!.viewInsets.bottom}',
                ))),
                TextField(key: _inputKey, controller: controller),
                TextButton(
                  onPressed: () =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  child: const Text('Close keyboard'),
                ),
              ]),
            ),
          );
        }));
      }),
    )));
    await tester.pumpAndSettle();
    expect(inherited!.size.width, contentWidth);
    final initialSize = live!.size;
    await tester.tap(find.byKey(_inputKey));
    await _waitFor(tester, () => (live?.viewInsets.bottom ?? 0) > 0);
    await tester.pumpAndSettle();
    expect(inherited!.viewInsets.bottom, live!.viewInsets.bottom);
    final keyboardTop = live!.size.height - live!.viewInsets.bottom;
    expect(tester.getRect(find.byKey(_inputKey)).bottom,
        lessThanOrEqualTo(keyboardTop));
    expect(find.text('Close keyboard').hitTestable(), findsOneWidget);
    debugPrint(
        'FOLDABLE keyboard visible: window=$initialSize inset=${live!.viewInsets.bottom} inherited=${inherited!.viewInsets.bottom}');

    await tester.tap(find.text('Close keyboard'));
    await _waitFor(tester, () => live!.viewInsets.bottom == 0);
    expect(inherited!.viewInsets.bottom, 0);
    expect(controller.text, 'foldable-input');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('native fold transition preserves the field and current metrics',
      (tester) async {
    final controller = TextEditingController(text: 'foldable-input');
    addTearDown(controller.dispose);
    MediaQueryData? live;
    MediaQueryData? inherited;
    double? width;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      live = MediaQuery.of(context);
      return FixedWidthLayout(child: LayoutBuilder(builder: (context, c) {
        inherited = MediaQuery.of(context);
        width = c.maxWidth;
        return Scaffold(
          appBar: AppBar(title: const Text('Native fold transition')),
          body: Column(children: [
            Text('Window: ${live!.size} / Content: $width'),
            Text('Inherited: ${inherited!.size}'),
            TextField(key: _inputKey, controller: controller),
          ]),
        );
      }));
    })));
    await tester.pumpAndSettle();
    final initialSize = live!.size;
    final field = tester.element(find.byKey(_inputKey));
    await tester.tap(find.byKey(_inputKey));
    debugPrint('FOLDABLE waiting for external transition from $initialSize');
    await _waitFor(tester, () => live!.size != initialSize,
        timeout: const Duration(seconds: 90));
    await tester.pumpAndSettle();
    expect(tester.element(find.byKey(_inputKey)), same(field));
    expect(inherited!.size.width, width);
    expect(inherited!.viewInsets.bottom, live!.viewInsets.bottom);
    expect(controller.text, 'foldable-input');
    debugPrint('FOLDABLE preserved input: $initialSize -> ${live!.size}, '
        'content=$width inherited=${inherited!.size.width}');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, skip: !const bool.fromEnvironment('VERIFY_FOLD_TRANSITION'));

  testWidgets('iOS custom native channels remain registered', (tester) async {
    // Invalid arguments exercise each registered handler without initializing
    // an ad SDK, fetching an ad, or opening an offerwall.
    for (final (channel, method) in [
      ('com.pincrux.offerwall.flutter', 'init'),
      ('pangle_native_channel', 'loadRewardedAd'),
    ]) {
      await expectLater(
        MethodChannel(channel).invokeMethod<void>(method),
        throwsA(isA<PlatformException>()
            .having((error) => error.code, 'code', 'InvalidParams')),
      );
    }
  }, skip: !Platform.isIOS);
}
