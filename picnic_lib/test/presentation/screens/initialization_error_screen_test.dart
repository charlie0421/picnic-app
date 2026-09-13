import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/screens/initialization_error_screen.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(initTestColors);

  testWidgets('shows localized initialization failure and retries', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      buildTestApp(InitializationErrorScreen(onRetry: () => retries++)),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('initialization-error-screen')),
      findsOneWidget,
    );
    expect(find.text('오류'), findsOneWidget);
    expect(find.text('오류가 발생했습니다.'), findsOneWidget);
    expect(find.text('재시도'), findsOneWidget);

    await tester.tap(find.byKey(const Key('initialization-retry-button')));
    expect(retries, 1);
  });
}
