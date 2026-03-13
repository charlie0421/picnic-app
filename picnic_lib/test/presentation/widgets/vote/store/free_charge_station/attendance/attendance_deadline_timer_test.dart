import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_deadline_timer.dart';

import '../../../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  Widget buildTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: Scaffold(body: child),
        );
      },
    );
  }

  group('AttendanceDeadlineTimer', () {
    testWidgets('renders without errors', (tester) async {
      final futureDeadline =
          DateTime.now().add(const Duration(hours: 2)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: futureDeadline,
            label: '',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AttendanceDeadlineTimer), findsOneWidget);
    });

    testWidgets('shows time format HH:MM:SS', (tester) async {
      final futureDeadline =
          DateTime.now().add(const Duration(hours: 1, minutes: 30)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: futureDeadline,
            label: '',
          ),
        ),
      );
      await tester.pump();

      // Should contain colon-separated time
      final textFinder = find.textContaining(':');
      expect(textFinder, findsWidgets);
    });

    testWidgets('shows label when non-empty', (tester) async {
      final futureDeadline =
          DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: futureDeadline,
            label: '마감까지',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('마감까지'), findsOneWidget);
    });

    testWidgets('hides label when empty', (tester) async {
      final futureDeadline =
          DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: futureDeadline,
            label: '',
          ),
        ),
      );
      await tester.pump();

      // Should not find any label text widget (only time)
      expect(find.text(''), findsNothing);
    });

    testWidgets('contains schedule icon', (tester) async {
      final futureDeadline =
          DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: futureDeadline,
            label: '',
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows 00:00:00 when deadline is past', (tester) async {
      final pastDeadline =
          DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: pastDeadline,
            label: '',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('00:00:00'), findsOneWidget);
    });

    testWidgets('calls onDeadlineReached when deadline is past', (tester) async {
      bool callbackCalled = false;
      final pastDeadline =
          DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: pastDeadline,
            label: '',
            onDeadlineReached: () => callbackCalled = true,
          ),
        ),
      );
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets('is a StatefulWidget', (tester) async {
      const widget = AttendanceDeadlineTimer(
        deadlineUTC: '2099-01-01T00:00:00Z',
        label: '',
      );
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('disposes without error', (tester) async {
      final futureDeadline =
          DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String();

      await tester.pumpWidget(
        buildTestWidget(
          AttendanceDeadlineTimer(
            deadlineUTC: futureDeadline,
            label: '',
          ),
        ),
      );
      await tester.pump();

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        buildTestWidget(const SizedBox()),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
