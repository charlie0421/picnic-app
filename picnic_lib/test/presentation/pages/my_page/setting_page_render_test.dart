import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/presentation/providers/platform_info_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({'app_version': <dynamic>[]});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  List<dynamic> _commonOverrides({
    UpdateStatus status = UpdateStatus.upToDate,
    String currentVersion = '1.0.0',
    String latestVersion = '1.0.0',
    String? url,
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
        patchInfoProvider.overrideWith(PatchInfoNotifier.new),
      ];

  group('SettingPage render', () {
    testWidgets('renders upToDate status', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          extraOverrides: _commonOverrides(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(SettingPage), findsOneWidget);
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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(SettingPage), findsOneWidget);
    });

    testWidgets('renders with Korean locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const SettingPage(),
          locale: const Locale('ko'),
          extraOverrides: _commonOverrides(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

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
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(SettingPage), findsOneWidget);
    });
  });
}
