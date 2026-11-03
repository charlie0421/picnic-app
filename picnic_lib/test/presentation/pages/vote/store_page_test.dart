import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/providers/product_provider.dart';
import 'package:picnic_lib/presentation/providers/promotion_badge_resolver_provider.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/load_test_fonts.dart';

void main() {
  setUpAll(loadTestFonts);
  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });
  tearDown(tearDownMockSupabase);

  testWidgets('store tab labels fit at 320px and 200% text', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      buildTestApp(
        const StorePage(),
        locale: const Locale('en'),
        designSize: const Size(393, 892),
        splitScreenMode: true,
        textScaler: TextScaler.linear(2),
        extraOverrides: [
          serverProductsProvider.overrideWithBuild((ref, notifier) => []),
          storeProductsProvider.overrideWithBuild((ref, notifier) => []),
          paymentBadgePromotionProvider.overrideWith((ref) async => null),
          paymentBadgePromotionPeriodProvider.overrideWith((ref) async => null),
        ],
      ),
    );
    await tester.pump();
    final tabs = find.byType(Tab);
    expect(tabs, findsNWidgets(2));
    for (final tab in tabs.evaluate()) {
      final target = find.byWidget(tab.widget);
      final label = find.descendant(of: target, matching: find.byType(Text));
      final tabBounds = tester.getRect(target);
      final labelBounds = tester.getRect(label);
      expect(tabBounds.height, greaterThanOrEqualTo(48));
      expect(labelBounds.top, greaterThanOrEqualTo(tabBounds.top));
      expect(labelBounds.bottom, lessThanOrEqualTo(tabBounds.bottom));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  group('StorePage widget', () {
    test('can be const-constructed', () {
      const page = StorePage();
      expect(page, isA<StorePage>());
    });

    test('with key can be constructed', () {
      const page = StorePage(key: ValueKey('store'));
      expect(page.key, equals(const ValueKey('store')));
    });
  });
}
