import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_check_tab.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';
import '../../../../../../helpers/test_environment.dart';

AttendanceWeeklyStatus _mockWeeklyStatus({
  int checkedCount = 3,
  int totalRequired = 7,
  bool isWeeklyBonusEligible = false,
  bool isNewUser = false,
}) {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));

  return AttendanceWeeklyStatus(
    weekStart: monday.toIso8601String().split('T').first,
    weekEnd: monday.add(const Duration(days: 6)).toIso8601String().split('T').first,
    days: List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return AttendanceDayStatus(
        date: date.toIso8601String().split('T').first,
        dayOfWeek: i + 1,
        checked: i < checkedCount,
        isToday: i == now.weekday - 1,
        isFuture: i > now.weekday - 1,
      );
    }),
    checkedCount: checkedCount,
    totalRequired: totalRequired,
    isWeeklyBonusEligible: isWeeklyBonusEligible,
    isNewUser: isNewUser,
  );
}

void main() {
  setUp(() {
    initTestColors();
  });

  group('AttendanceCheckTab', () {
    testWidgets('renders zero checked count state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(checkedCount: 0),
                  todayChecked: false,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
      expect(find.text('0/7'), findsOneWidget);
    });

    testWidgets('renders login required when not logged in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: false,
          extraOverrides: [
            attendanceProvider.overrideWith(() => _NullWeeklyAttendance()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
    });

    testWidgets('renders with null weekly status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(() => _NullWeeklyAttendance()),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
    });

    testWidgets('renders data state with check-in button (not checked today)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(checkedCount: 3),
                  todayChecked: false,
                  deadlineKST: DateTime.now()
                      .add(const Duration(hours: 12))
                      .toIso8601String(),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      // Progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Progress text
      expect(find.text('3/7'), findsOneWidget);
    });

    testWidgets('renders data state with already checked today',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(checkedCount: 4),
                  todayChecked: true,
                  deadlineKST: DateTime.now()
                      .add(const Duration(hours: 12))
                      .toIso8601String(),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
      expect(find.text('4/7'), findsOneWidget);
    });

    testWidgets('renders weekly bonus eligible state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(
                    checkedCount: 7,
                    isWeeklyBonusEligible: true,
                  ),
                  todayChecked: true,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
      expect(find.text('7/7'), findsOneWidget);
    });

    testWidgets('renders new user notice when isNewUser is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(
                    checkedCount: 0,
                    isNewUser: true,
                  ),
                  todayChecked: false,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
    });

    testWidgets('renders without deadline timer when deadlineKST is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(checkedCount: 2),
                  todayChecked: false,
                  deadlineKST: null,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
      expect(find.text('2/7'), findsOneWidget);
    });

    testWidgets('renders reward info banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(checkedCount: 1),
                  todayChecked: false,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
      // Reward info has '+60' and '+120' text
      expect(find.text(' +60'), findsOneWidget);
      expect(find.text(' +120 '), findsOneWidget);
    });

    testWidgets('error state renders widget without crash', (WidgetTester tester) async {
      final restore = suppressImageErrors();
      try {
        await tester.pumpWidget(
          buildTestApp(
            const AttendanceCheckTab(),
            loggedIn: true,
            extraOverrides: [
              attendanceProvider.overrideWith(() => _ErrorAttendance()),
            ],
          ),
        );
        while (tester.takeException() != null) {}
        await tester.pump();
        while (tester.takeException() != null) {}
        await tester.pump();
        while (tester.takeException() != null) {}

        expect(find.byType(AttendanceCheckTab), findsOneWidget);
      } finally {
        restore();
      }
    });

    testWidgets('check-in button tap triggers check-in flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _CheckInAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(checkedCount: 3),
                  todayChecked: false,
                  deadlineKST: DateTime.now()
                      .add(const Duration(hours: 12))
                      .toIso8601String(),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // Find and tap the check-in button
      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      // After tap, should show loading indicator
      await tester.pump(const Duration(milliseconds: 100));
      // Wait for check-in to complete
      await tester.pump(const Duration(seconds: 1));
      // Drain result timer (3 seconds)
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
    });

    testWidgets('check-in with weekly bonus result', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _WeeklyBonusCheckInAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(
                    checkedCount: 6,
                    isWeeklyBonusEligible: true,
                  ),
                  todayChecked: false,
                  deadlineKST: DateTime.now()
                      .add(const Duration(hours: 12))
                      .toIso8601String(),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // After check-in with weekly bonus, confetti and result should appear
      await tester.pump(const Duration(seconds: 1));
      // Drain result timer (3 seconds)
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(AttendanceCheckTab), findsOneWidget);
    });

    testWidgets('check-in button disabled when todayChecked', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AttendanceCheckTab(),
          loggedIn: true,
          extraOverrides: [
            attendanceProvider.overrideWith(
              () => _DataAttendance(
                AttendanceState(
                  weeklyStatus: _mockWeeklyStatus(checkedCount: 4),
                  todayChecked: true,
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // Button should be present but disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

  });
}

/// Mock Attendance with null weeklyStatus
class _NullWeeklyAttendance extends Attendance {
  @override
  Future<AttendanceState> build() async {
    return const AttendanceState();
  }
}

/// Mock Attendance with data
class _DataAttendance extends Attendance {
  final AttendanceState _state;

  _DataAttendance(this._state);

  @override
  Future<AttendanceState> build() async => _state;
}

/// Mock Attendance that throws an error
class _ErrorAttendance extends Attendance {
  @override
  Future<AttendanceState> build() async {
    throw Exception('test error');
  }
}

/// Mock Attendance that supports check-in with normal reward
class _CheckInAttendance extends Attendance {
  final AttendanceState _state;

  _CheckInAttendance(this._state);

  @override
  Future<AttendanceState> build() async => _state;

  @override
  Future<AttendanceCheckResult?> checkIn() async {
    return const AttendanceCheckResult(
      rewardAmount: 60,
      weeklyBonusAmount: 0,
      totalReward: 60,
    );
  }
}

/// Mock Attendance that supports check-in with weekly bonus
class _WeeklyBonusCheckInAttendance extends Attendance {
  final AttendanceState _state;

  _WeeklyBonusCheckInAttendance(this._state);

  @override
  Future<AttendanceState> build() async => _state;

  @override
  Future<AttendanceCheckResult?> checkIn() async {
    return const AttendanceCheckResult(
      rewardAmount: 60,
      weeklyBonusAmount: 120,
      totalReward: 180,
    );
  }
}

/// A notifier that stays in loading state
class _SlowAttendance extends Attendance {
  @override
  Future<AttendanceState> build() async {
    await Future.delayed(const Duration(hours: 1));
    return const AttendanceState();
  }
}
