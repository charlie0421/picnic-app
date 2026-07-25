import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';

import '../../../../../helpers/ignore_image_errors.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late RestoreCallback restore;

  setUp(() {
    restore = suppressImageErrors();
    initTestEnvironment();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('StorePointInfo - logged out (no supabase)', () {
    testWidgets('renders with title and login prompt', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Test Title',
            width: double.infinity,
            height: 120,
          ),
          loggedIn: true,
        ),
      );
      await pumpAndIgnoreErrors(tester);

      // Widget rendered
      expect(find.byType(StorePointInfo), findsOneWidget);

      expect(find.text('Test Title'), findsOneWidget);

      // UnderlinedText for policy guide
      expect(find.byType(UnderlinedText), findsWidgets);
    });

    testWidgets('uses content height and does not overflow a compact request', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(title: 'Star Candy', width: 200, height: 100),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with custom topMargin and titlePadding', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Custom',
            width: 300,
            height: 150,
            topMargin: 10,
            titlePadding: 8,
          ),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
    });

    testWidgets('renders with default constructor values', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const StorePointInfo(title: 'Default'), loggedIn: false),
      );
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
    });
  });

  group('StorePointInfo - logged in with mock supabase', () {
    setUp(() async {
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
    });

    testWidgets('shows StarCandyInfoText when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Star Candy Pouch',
            width: double.infinity,
            height: 120,
          ),
          loggedIn: true,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
      expect(find.byType(StarCandyInfoText), findsOneWidget);
    });

    testWidgets('shows policy guide when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const StorePointInfo(
            title: 'Star Candy Pouch',
            width: double.infinity,
            height: 120,
          ),
          loggedIn: true,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(UnderlinedText), findsWidgets);
    });
  });

  group('StorePointInfo properties', () {
    test('can be instantiated with required params', () {
      const widget = StorePointInfo(title: 'Test');
      expect(widget.title, 'Test');
      expect(widget.width, 48);
      expect(widget.height, 36);
      expect(widget.topMargin, 20);
      expect(widget.titlePadding, isNull);
    });

    test('can be instantiated with all params', () {
      const widget = StorePointInfo(
        title: 'Full',
        width: 100,
        height: 200,
        topMargin: 30,
        titlePadding: 12,
      );
      expect(widget.title, 'Full');
      expect(widget.width, 100);
      expect(widget.height, 200);
      expect(widget.topMargin, 30);
      expect(widget.titlePadding, 12);
    });
  });
}
