import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/candy_boost_period_banner.dart';

import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

void main() {
  setUp(initTestColors);

  testWidgets('shows the boost title and localized server period compactly', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        CandyBoostPeriodBanner(
          startsAt: DateTime.utc(2026, 9, 7, 15),
          endsAt: DateTime.utc(2026, 9, 8, 14, 59, 59),
          bonusPercent: 100,
        ),
        locale: const Locale('ko'),
      ),
    );

    expect(find.byKey(const Key('candy-boost-period-banner')), findsOneWidget);
    expect(find.text('캔디 부스트 데이'), findsOneWidget);
    expect(
      find.byKey(const Key('candy-boost-banner-bonus-icon')),
      findsOneWidget,
    );
    expect(find.text('+100%'), findsOneWidget);
    expect(
      find.text('2026. 9. 8. (화) 00:00 – 9. 8. (화) 23:59 KST'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows concrete dates for a bounded multi-day occurrence, without year '
    'on the end date when it does not cross a year boundary',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CandyBoostPeriodBanner(
            startsAt: DateTime.utc(2026, 9, 20, 15),
            endsAt: DateTime.utc(2026, 9, 23, 15),
            bonusPercent: 100,
          ),
          locale: const Locale('ko'),
        ),
      );

      expect(find.text('2026. 9. 21. (월) – 9. 23. (수) KST'), findsOneWidget);
    },
  );

  testWidgets(
    'keeps the year on both sides when the occurrence crosses a year '
    'boundary',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CandyBoostPeriodBanner(
            startsAt: DateTime.utc(2026, 12, 30, 15),
            endsAt: DateTime.utc(2027, 1, 1, 15),
            bonusPercent: 100,
          ),
          locale: const Locale('ko'),
        ),
      );

      expect(
        find.text('2026. 12. 31. (목) – 2027. 1. 1. (금) KST'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'preserves the non-midnight time of day when the first day is clipped '
    'to a partial-day campaign start',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CandyBoostPeriodBanner(
            // 2026-09-21 06:30 KST (a partial-day campaign start).
            startsAt: DateTime.utc(2026, 9, 20, 21, 30),
            // 2026-09-24 00:00 KST (a plain midnight, exclusive, boundary).
            endsAt: DateTime.utc(2026, 9, 23, 15),
            bonusPercent: 100,
          ),
          locale: const Locale('ko'),
        ),
      );

      expect(
        find.text('2026. 9. 21. (월) 06:30 – 9. 23. (수) 23:59 KST'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows 23:59 on the previous day for a same-day partial-start-to-midnight '
    'occurrence, never advertising the exclusive midnight itself',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CandyBoostPeriodBanner(
            // 2026-09-21 06:30 KST (a partial-day campaign start).
            startsAt: DateTime.utc(2026, 9, 20, 21, 30),
            // 2026-09-22 00:00 KST (a plain midnight, exclusive, boundary) —
            // same calendar day as the start once rolled back.
            endsAt: DateTime.utc(2026, 9, 21, 15),
            bonusPercent: 100,
          ),
          locale: const Locale('ko'),
        ),
      );

      expect(
        find.text('2026. 9. 21. (월) 06:30 – 9. 21. (월) 23:59 KST'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'rolls a partial-time exclusive next-year midnight back to 23:59 of '
    'the prior Dec 31, which stays within the start year',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CandyBoostPeriodBanner(
            // 2026-12-30 06:30 KST (a partial-day campaign start).
            startsAt: DateTime.utc(2026, 12, 29, 21, 30),
            // 2027-01-01 00:00 KST (a plain midnight, exclusive, boundary) —
            // rolls back to 2026-12-31 23:59, so the resolved range never
            // actually crosses into 2027.
            endsAt: DateTime.utc(2026, 12, 31, 15),
            bonusPercent: 100,
          ),
          locale: const Locale('ko'),
        ),
      );

      expect(
        find.text('2026. 12. 30. (수) 06:30 – 12. 31. (목) 23:59 KST'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a microsecond before midnight is not treated as the exclusive midnight '
    'boundary and is displayed as-is',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CandyBoostPeriodBanner(
            startsAt: DateTime.utc(2026, 9, 20, 21, 30),
            // 2026-09-23 23:59:59.999999 KST — one microsecond shy of the
            // exclusive midnight boundary, so it must not be rolled back.
            endsAt: DateTime.utc(
              2026,
              9,
              23,
              14,
              59,
              59,
              999,
              999,
            ),
            bonusPercent: 100,
          ),
          locale: const Locale('ko'),
        ),
      );

      expect(
        find.text('2026. 9. 21. (월) 06:30 – 9. 23. (수) 23:59 KST'),
        findsOneWidget,
      );
    },
  );

  testWidgets('disables decorative motion when reduced motion is requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CandyBoostPeriodBanner(
            startsAt: DateTime.utc(2026, 9, 7, 15),
            endsAt: DateTime.utc(2026, 9, 8, 14, 59, 59),
            bonusPercent: 100,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('candy-boost-banner-shine')), findsNothing);
    expect(
      find.byKey(const Key('candy-boost-banner-static-bonus-icon')),
      findsOneWidget,
    );
  });
}
