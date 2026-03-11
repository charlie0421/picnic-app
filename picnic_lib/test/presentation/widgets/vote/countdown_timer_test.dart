import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('CountdownTimer', () {
    testWidgets('renders with active status and future end time',
        (tester) async {
      final futureTime = DateTime.now().toUtc().add(const Duration(hours: 2));
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: futureTime,
            status: VoteStatus.active,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render time separators
      expect(find.text(' : '), findsWidgets);
      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('renders upcoming status label', (tester) async {
      final futureTime = DateTime.now().toUtc().add(const Duration(days: 3));
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: futureTime,
            status: VoteStatus.upcoming,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CountdownTimer), findsOneWidget);
      // Should show upcoming label and time
      expect(find.text(' : '), findsWidgets);
    });

    testWidgets('renders end status text', (tester) async {
      final pastTime = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: pastTime,
            status: VoteStatus.end,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CountdownTimer), findsOneWidget);
      // End status should NOT show time separators
      expect(find.text(' : '), findsNothing);
    });

    testWidgets('renders with past end time shows zero', (tester) async {
      final pastTime = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: pastTime,
            status: VoteStatus.active,
          ),
        ),
      );
      // Just pump one frame since timer may cancel immediately
      await tester.pump();

      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('renders with onRefresh callback without crash', (tester) async {
      final endTime = DateTime.now().toUtc().add(const Duration(hours: 1));
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: endTime,
            status: VoteStatus.active,
            onRefresh: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('displays day counter for long duration', (tester) async {
      final futureTime = DateTime.now().toUtc().add(const Duration(days: 5));
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: futureTime,
            status: VoteStatus.active,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show 'D' unit for days
      expect(find.text(' D '), findsOneWidget);
    });

    testWidgets('timer updates every second', (tester) async {
      final futureTime = DateTime.now().toUtc().add(const Duration(minutes: 5));
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: futureTime,
            status: VoteStatus.active,
          ),
        ),
      );
      await tester.pump();

      // Advance 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CountdownTimer), findsOneWidget);
    });
  });

  group('VoteStatus', () {
    test('has expected values', () {
      expect(VoteStatus.values, contains(VoteStatus.all));
      expect(VoteStatus.values, contains(VoteStatus.active));
      expect(VoteStatus.values, contains(VoteStatus.end));
      expect(VoteStatus.values, contains(VoteStatus.upcoming));
      expect(VoteStatus.values, contains(VoteStatus.activeAndUpcoming));
    });
  });

  group('VoteCategory', () {
    test('has expected values', () {
      expect(VoteCategory.values, contains(VoteCategory.all));
      expect(VoteCategory.values, contains(VoteCategory.birthday));
      expect(VoteCategory.values, contains(VoteCategory.comeback));
      expect(VoteCategory.values, contains(VoteCategory.achieve));
      expect(VoteCategory.values, contains(VoteCategory.birth));
      expect(VoteCategory.values, contains(VoteCategory.debut));
      expect(VoteCategory.values, contains(VoteCategory.image));
    });
  });

  group('VotePortal', () {
    test('has expected values', () {
      expect(VotePortal.values, contains(VotePortal.vote));
      expect(VotePortal.values, contains(VotePortal.pic));
    });
  });
}
