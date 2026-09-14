import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/my_page/admin_menu_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/currency_history_page.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/store_point_info.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/load_test_fonts.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class MockBookmarkedArtists extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [];
}

class _UnusedHistoryClient extends Fake implements SupabaseClient {}

class _MenuHistoryRepository extends WalletRepository {
  _MenuHistoryRepository() : super(_UnusedHistoryClient());
  final historyCalls = <WalletCurrency>[];
  @override
  Future<WalletSummaryModel> getSummary() async => WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.zero,
    bonus: BigInt.zero,
    cotton: BigInt.zero,
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026, 9, 8),
  );
  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) async {
    historyCalls.add(currency);
    return CurrencyHistoryPageModel(
      items: [],
      totalCount: BigInt.zero,
      nextCursor: null,
      snapshotAt: DateTime.utc(2026, 9, 8),
    );
  }
}

void main() {
  late void Function() restore;

  setUpAll(loadTestFonts);

  setUp(() {
    initTestColors();
    setupMockSupabase({'artist_user_bookmark': <dynamic>[]});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpCompactLargeTextMyPage(
    WidgetTester tester, {
    required bool loggedIn,
    String? nickname,
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(320 * 3, 700 * 3);
    addTearDown(tester.view.reset);

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        const MyPage(),
        loggedIn: loggedIn,
        userProfile: loggedIn
            ? MockData.userProfile(nickname: nickname, avatarUrl: null)
            : null,
        extraOverrides: [
          asyncBookmarkedArtistsProvider.overrideWith(
            MockBookmarkedArtists.new,
          ),
        ],
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
  }

  group('MyPage render', () {
    testWidgets('320px 200% long nickname keeps the profile row usable', (
      tester,
    ) async {
      const nickname = '아주 긴 닉네임을 사용하는 피크닉 팬';
      await pumpCompactLargeTextMyPage(
        tester,
        loggedIn: true,
        nickname: nickname,
      );

      final label = find.text(nickname);
      expect(label, findsOneWidget);
      final rect = tester.getRect(label);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    });

    testWidgets(
      '320px 200% logged-out prompt keeps its trailing action visible',
      (tester) async {
        await pumpCompactLargeTextMyPage(tester, loggedIn: false);

        final loggedOutProfile = find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.child is Row,
        );
        final prompt = find.descendant(
          of: loggedOutProfile,
          matching: find.text('로그인해 주세요'),
        );
        expect(prompt, findsOneWidget);
        final rect = tester.getRect(prompt);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      },
    );

    testWidgets('renders logged-in state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('shows candy history and the shared pouch for a regular user', (
      WidgetTester tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(isAdmin: false),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(StorePointInfo), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('알림함'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('알림함'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('설정'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('my-page-currency-history')), findsOneWidget);
      expect(find.text('관리자'), findsNothing);
    });

    testWidgets('keeps administrator tools separate from public history', (
      WidgetTester tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPageScreen(),
          navigation: Navigation.initial(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      expect(find.byType(MyPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('관리자'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final adminAction = find.ancestor(
        of: find.text('관리자'),
        matching: find.byType(InkWell),
      );
      await Scrollable.ensureVisible(
        tester.element(adminAction),
        alignment: 0.5,
      );
      await pumpAndIgnoreErrors(tester);
      expect(find.text('관리자'), findsOneWidget);
      expect(adminAction.hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('my-page-currency-history')), findsOneWidget);
      expect(find.text('충전 내역'), findsNothing);
      expect(find.text('Ad Inspector'), findsNothing);
      expect(find.text('Reset & Reload GDPR'), findsNothing);

      await tester.tap(adminAction);
      await pumpAndIgnoreErrors(tester);
      expect(find.byType(AdminMenuPage), findsOneWidget);
    });

    testWidgets(
      'regular user opens history from the menu without prefetching',
      (tester) async {
        await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
        final repository = _MenuHistoryRepository();
        await tester.pumpWidget(
          buildTestAppPage(
            const MyPageScreen(),
            navigation: Navigation.initial(),
            userProfile: MockData.userProfile(isAdmin: false),
            extraOverrides: [
              asyncBookmarkedArtistsProvider.overrideWith(
                MockBookmarkedArtists.new,
              ),
              walletRepositoryProvider.overrideWithValue(repository),
              walletHistorySessionProvider.overrideWithValue(
                WalletHistorySession('test-user-id'),
              ),
            ],
          ),
        );
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
        final entry = find.byKey(const Key('my-page-currency-history'));
        await tester.scrollUntilVisible(
          entry,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(repository.historyCalls, isEmpty);
        await tester.tap(entry);
        await pumpAndIgnoreErrors(tester);
        await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
        expect(find.byType(CurrencyHistoryPage), findsOneWidget);
        expect(repository.historyCalls, [WalletCurrency.cottonCandy]);
      },
    );

    testWidgets('renders logged-out state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          loggedIn: false,
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
      expect(find.byType(StorePointInfo), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('설정'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('알림함'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(StorePointInfo),
          matching: find.text('로그인해 주세요'),
        ),
        findsOneWidget,
      );
      expect(find.text('캔디 내역'), findsNothing);
      expect(find.text('관리자'), findsNothing);
    });

    testWidgets('keeps 16px space above and below the candy pouch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          loggedIn: false,
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      final pouchRect = tester.getRect(find.byType(StorePointInfo));
      final previousRect = tester.getRect(
        find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.child is Row,
        ),
      );
      final nextRect = tester.getRect(find.text('언어 설정'));

      expect(pouchRect.top - previousRect.bottom, 16);
      expect(nextRect.top - pouchRect.bottom, 16);
    });

    testWidgets('renders admin user with admin menus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);

      // Admin menus should be visible - scroll to find them
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(
          listView.first,
          const Offset(0, -500),
          warnIfMissed: false,
        );
        await pumpAndIgnoreErrors(tester);
      }
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          locale: const Locale('en'),
          setting: MockData.setting(language: 'en'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with user that has avatar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(
            avatarUrl: 'https://example.com/avatar.jpg',
            nickname: 'AvatarUser',
          ),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with user that has no nickname', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(nickname: null),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with bookmarked artists loading error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              () => MockBookmarkedArtistsError(),
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('scroll through all menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll through all the menu items
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, -300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
      }
    });

    testWidgets('tap menu list items', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Tap all InkWell items (menu items)
      final inkWells = find.byType(InkWell);
      for (int i = 0; i < tester.widgetList(inkWells).length && i < 10; i++) {
        try {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          locale: const Locale('ja'),
          setting: MockData.setting(language: 'ja'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('renders with user that has zero candy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(
            starCandy: 0,
            starCandyBonus: 0,
            jmaCandy: 0,
          ),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('scroll through all items including admin menus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll through all menu items including admin-only ones
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, -300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
        // Scroll back up
        for (int i = 0; i < 3; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, 300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
      }
    });

    testWidgets('tap admin menu items', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(isAdmin: true),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll down to admin menus
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        for (int i = 0; i < 4; i++) {
          await tester.drag(
            listView.first,
            const Offset(0, -300),
            warnIfMissed: false,
          );
          await pumpAndIgnoreErrors(tester);
        }
      }

      // Tap InkWells at the bottom (admin menus)
      final inkWells = find.byType(InkWell);
      for (int i = 0; i < tester.widgetList(inkWells).length && i < 15; i++) {
        try {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
    });

    testWidgets('renders profile section for logged-in user with QnA', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          userProfile: MockData.userProfile(id: 'test-id-123'),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Scroll to QnA menu
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(
          listView.first,
          const Offset(0, -200),
          warnIfMissed: false,
        );
        await pumpAndIgnoreErrors(tester);
      }

      expect(find.byType(MyPage), findsOneWidget);
    });

    testWidgets('tap language selector GestureDetectors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const MyPage(),
          extraOverrides: [
            asyncBookmarkedArtistsProvider.overrideWith(
              MockBookmarkedArtists.new,
            ),
          ],
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

      // Language selector uses GestureDetector - try tapping them
      final gestureDetectors = find.byType(GestureDetector);
      for (
        int i = 0;
        i < tester.widgetList(gestureDetectors).length && i < 10;
        i++
      ) {
        try {
          await tester.tap(gestureDetectors.at(i), warnIfMissed: false);
          await pumpAndIgnoreErrors(tester);
        } catch (_) {}
      }
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 300));
    });
  });
}

class MockBookmarkedArtistsError extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async =>
      throw Exception('Failed to load bookmarked artists');
}
