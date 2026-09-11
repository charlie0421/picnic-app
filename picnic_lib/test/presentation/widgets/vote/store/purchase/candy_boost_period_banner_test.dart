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
