import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/charge_station_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';

import '../../../../../helpers/ignore_image_errors.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late RestoreCallback restore;

  Widget buildWidget({
    List<ChargeStationItem> Function(BuildContext)? missionBuilder,
    List<ChargeStationItem> Function(BuildContext)? adBuilder,
    bool loggedIn = true,
  }) {
    return buildTestApp(
      _AnimationHost(
        builder: (ac, rc) {
          final buttonScaleAnimation = Tween<double>(
            begin: 0.5,
            end: 2.0,
          ).animate(ac);
          return FreeChargeContent(
            buttonScaleAnimation: buttonScaleAnimation,
            onPolicyTap: () {},
            missionItemBuilder:
                missionBuilder ??
                (_) => [
                  ChargeStationItem(
                    id: 'tapjoy',
                    title: 'Mission #1',
                    isMission: true,
                    platformType: AdPlatformType.tapjoy,
                    onPressed: () {},
                    bonusText: 'Unlimited',
                  ),
                ],
            adItemBuilder:
                adBuilder ??
                (_) => [
                  ChargeStationItem(
                    id: 'admob',
                    title: 'Ad #1',
                    isMission: false,
                    platformType: AdPlatformType.admob,
                    onPressed: () {},
                    bonusText: '1',
                  ),
                ],
            onPincruxOfferwallPressed: () {},
            rotationController: rc,
          );
        },
      ),
      loggedIn: loggedIn,
    );
  }

  setUp(() {
    restore = suppressImageErrors();
    initTestEnvironment();
  });

  tearDown(() {
    restore();
  });

  group('FreeChargeContent', () {
    testWidgets('renders with missions and ads when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget());
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(FreeChargeContent), findsOneWidget);
      expect(find.byType(StoreListTile), findsWidgets);
    });

    testWidgets('renders section headers', (tester) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget());
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      // Section headers should be present
      expect(find.byType(Divider), findsWidgets);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows reward type specific Korean copy for missions and ads', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget());
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.text('미션에서 보너스 스타캔디 받기'), findsOneWidget);
      expect(find.text('광고에서 코튼캔디 받기'), findsOneWidget);
      expect(find.text('+보너스 스타캔디 Unlimited 획득'), findsOneWidget);
      expect(find.text('+코튼캔디 1 획득'), findsOneWidget);
    });

    testWidgets('shows StorePointInfo when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget(loggedIn: true));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
    });

    testWidgets('hides StorePointInfo when logged out', (tester) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget(loggedIn: false));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsNothing);
    });

    testWidgets('renders empty missions list', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildWidget(missionBuilder: (_) => []),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(FreeChargeContent), findsOneWidget);
    });

    testWidgets('renders empty ads list', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildWidget(adBuilder: (_) => []),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(FreeChargeContent), findsOneWidget);
    });

    testWidgets('renders multiple missions and ads', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildWidget(
          missionBuilder: (_) => [
            ChargeStationItem(
              id: 'tapjoy',
              title: 'Mission #1',
              isMission: true,
              platformType: AdPlatformType.tapjoy,
              onPressed: () {},
              bonusText: 'Unlimited',
            ),
            ChargeStationItem(
              id: 'pincrux',
              title: 'Mission #2',
              isMission: true,
              platformType: AdPlatformType.pincrux,
              onPressed: () {},
              bonusText: 'Unlimited',
            ),
          ],
          adBuilder: (_) => [
            ChargeStationItem(
              id: 'admob',
              title: 'Ad #1',
              isMission: false,
              platformType: AdPlatformType.admob,
              onPressed: () {},
              bonusText: '1',
            ),
            ChargeStationItem(
              id: 'pangle',
              title: 'Ad #2',
              isMission: false,
              platformType: AdPlatformType.pangle,
              onPressed: () {},
              bonusText: '1',
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StoreListTile), findsNWidgets(4));
    });

    testWidgets('renders items with empty bonusText', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildWidget(
          adBuilder: (_) => [
            ChargeStationItem(
              id: 'custom',
              title: 'No Bonus',
              isMission: false,
              platformType: AdPlatformType.custom,
              onPressed: () {},
              bonusText: '',
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(FreeChargeContent), findsOneWidget);
    });

    testWidgets('renders rotation button when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget(loggedIn: true));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(RotationTransition), findsWidgets);
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}

/// Helper widget that creates AnimationControllers with a valid TickerProvider
class _AnimationHost extends StatefulWidget {
  final Widget Function(AnimationController, AnimationController) builder;

  const _AnimationHost({required this.builder});

  @override
  State<_AnimationHost> createState() => _AnimationHostState();
}

class _AnimationHostState extends State<_AnimationHost>
    with TickerProviderStateMixin {
  late AnimationController _ac;
  late AnimationController _rc;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rc = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _ac.dispose();
    _rc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_ac, _rc);
}
