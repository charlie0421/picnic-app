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
    Locale locale = const Locale('ko'),
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
      locale: locale,
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
      expect(find.text('+보너스 스타캔디 획득'), findsOneWidget);
      expect(find.textContaining('Unlimited'), findsNothing);
      expect(find.text('+코튼캔디 1 획득'), findsOneWidget);
    });

    testWidgets('renders currency icons for mission and ad reward rows', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget());
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      final rewardTiles = tester.widgetList<StoreListTile>(
        find.byType(StoreListTile),
      );

      expect(rewardTiles, hasLength(2));
      expect(
        (rewardTiles.first.icon.image as AssetImage).assetName,
        'assets/icons/store/currency_bonus_star_candy.png',
      );
      expect(
        (rewardTiles.last.icon.image as AssetImage).assetName,
        'assets/icons/store/currency_cotton_candy.png',
      );
    });

    testWidgets(
      'does not overflow long Spanish mission copy at 320px and 1.3x text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await pumpWidgetAndIgnoreErrors(
          tester,
          buildWidget(
            loggedIn: false,
            locale: const Locale('es'),
            missionBuilder: (_) => [
              ChargeStationItem(
                id: 'tapjoy',
                title: 'Recompensas ilimitadas',
                isMission: true,
                platformType: AdPlatformType.tapjoy,
                onPressed: () {},
                bonusText: 'Recompensas ilimitadas',
              ),
            ],
            adBuilder: (_) => [],
          ),
        );
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester);

        expect(tester.takeException(), isNull);
        expect(
          find.text(
            '+Caramelo de Estrella de Bonificación '
            'Recompensas ilimitadas obtenido',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows StorePointInfo when logged in', (tester) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget(loggedIn: true));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsOneWidget);
    });

    testWidgets('keeps 16px space around the logged-in candy pouch', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget(loggedIn: true));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      final pouchRect = tester.getRect(find.byType(StorePointInfo));
      final previousRect = tester.getRect(find.byType(ListView));
      final nextRect = tester.getRect(find.text('미션에서 보너스 스타캔디 받기'));

      expect(pouchRect.top - previousRect.top, 16);
      expect(nextRect.top - pouchRect.bottom, 16);
    });

    testWidgets('hides StorePointInfo when logged out', (tester) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget(loggedIn: false));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(StorePointInfo), findsNothing);
    });

    testWidgets('leaves no logged-in pouch spacing when logged out', (
      tester,
    ) async {
      await pumpWidgetAndIgnoreErrors(tester, buildWidget(loggedIn: false));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      final listRect = tester.getRect(find.byType(ListView));
      final missionRect = tester.getRect(find.text('미션에서 보너스 스타캔디 받기'));

      expect(missionRect.top - listRect.top, 8);
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
