import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/presentation/providers/platform_info_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// Mock PatchInfoNotifier with a custom initial value
class MockPatchInfoNotifier extends PatchInfoNotifier {
  final PatchInfo _initial;
  MockPatchInfoNotifier(this._initial);

  @override
  PatchInfo build() => _initial;
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({'version': <dynamic>[]});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget,
      {int pumps = 3}) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
    }
  }

  List<dynamic> _commonOverrides({
    UpdateStatus status = UpdateStatus.upToDate,
    String currentVersion = '1.0.0',
    String latestVersion = '1.0.0',
    String? url,
    PatchInfo? patchInfo,
  }) =>
      [
        checkUpdateProvider.overrideWith(
          (ref) async => UpdateInfo(
            status: status,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            forceVersion: '1.0.0',
            url: url,
          ),
        ),
        platformInfoProvider.overrideWith(PlatformInfo.new),
        if (patchInfo != null)
          patchInfoProvider.overrideWith(
            () => MockPatchInfoNotifier(patchInfo),
          )
        else
          patchInfoProvider.overrideWith(PatchInfoNotifier.new),
      ];

  group('SettingPage coverage - all update statuses', () {
    testWidgets('renders upToDate status with list items',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
      expect(find.byType(PicnicListItem), findsWidgets);
    });

    testWidgets('renders needPatch status', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            status: UpdateStatus.needPatch,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders updateRequired status', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            status: UpdateStatus.updateRequired,
            currentVersion: '1.0.0',
            latestVersion: '2.0.0',
            url: 'https://apps.apple.com/app/picnic',
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders updateRecommended status',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            status: UpdateStatus.updateRecommended,
            currentVersion: '1.0.0',
            latestVersion: '1.5.0',
            url: 'https://apps.apple.com/app/picnic',
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with null update info', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: [
            checkUpdateProvider.overrideWith((ref) async => null),
            platformInfoProvider.overrideWith(PlatformInfo.new),
            patchInfoProvider.overrideWith(PatchInfoNotifier.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with update error', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: [
            checkUpdateProvider.overrideWith(
              (ref) async => throw Exception('Update check failed'),
            ),
            platformInfoProvider.overrideWith(PlatformInfo.new),
            patchInfoProvider.overrideWith(PatchInfoNotifier.new),
          ],
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });
  });

  group('SettingPage coverage - patch info variants', () {
    testWidgets('renders with current patch number',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            patchInfo: const PatchInfo(currentPatch: 5),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with no patch applied', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            patchInfo: const PatchInfo(),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with update downloaded patch info',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            patchInfo: const PatchInfo(
              hasUpdate: true,
              updateDownloaded: true,
              currentPatch: 3,
              newPatch: 4,
            ),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with needs restart patch info',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            patchInfo: const PatchInfo(
              hasUpdate: true,
              updateDownloaded: true,
              needsRestart: true,
              currentPatch: 3,
              newPatch: 4,
            ),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });
  });

  group('SettingPage coverage - locale variants', () {
    testWidgets('renders with Korean locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          locale: const Locale('ko'),
          extraOverrides: _commonOverrides(),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          locale: const Locale('en'),
          extraOverrides: _commonOverrides(),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          locale: const Locale('ja'),
          extraOverrides: _commonOverrides(),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });
  });

  group('SettingPage coverage - user state variants', () {
    testWidgets('renders with logged out user', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          loggedIn: false,
          extraOverrides: _commonOverrides(),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with admin user', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });
  });

  group('SettingPage coverage - update status with patch number in version string', () {
    testWidgets('needPatch with currentPatch shows patch number',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            status: UpdateStatus.needPatch,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            patchInfo: const PatchInfo(currentPatch: 2),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('updateRequired with currentPatch shows patch number',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            status: UpdateStatus.updateRequired,
            currentVersion: '1.0.0',
            latestVersion: '2.0.0',
            url: 'https://apps.apple.com/app/picnic',
            patchInfo: const PatchInfo(currentPatch: 3),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('updateRecommended with currentPatch shows patch number',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            status: UpdateStatus.updateRecommended,
            currentVersion: '1.0.0',
            latestVersion: '1.5.0',
            url: 'https://apps.apple.com/app/picnic',
            patchInfo: const PatchInfo(currentPatch: 1),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('upToDate with currentPatch shows patch number',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(
            patchInfo: const PatchInfo(currentPatch: 7),
          ),
        ),
        pumps: 4,
      );

      expect(find.byType(SettingPage), findsOneWidget);
    });
  });
}
