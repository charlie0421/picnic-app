import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/fullscreen_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../helpers/load_test_fonts.dart';
import '../../../../../helpers/mock_supabase.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

/// 소멸 예정 캔디 안내 팝업의 **기하 회귀** 테스트.
///
/// 기존 `usage_policy_dialog_test.dart` 는 `buildTestAppPage` 를 쓰는데 그쪽은
/// 375x812 / `splitScreenMode: false` 를 하드코딩한다(test_app.dart:114-116).
/// 프로덕션은 `kAppDesignSize` 393x892 + `splitScreenMode: true` 이고 그 차이가
/// `.h` 환산을 바꾸므로, 레이아웃은 여기서 프로덕션 기하로만 측정한다.
class _UnusedClient extends Fake implements SupabaseClient {}

class _WalletRepository extends WalletRepository {
  _WalletRepository.value(WalletSummaryModel summary)
    : loadSummary = (() async => summary),
      super(_UnusedClient());

  final Future<WalletSummaryModel> Function() loadSummary;

  @override
  Future<WalletSummaryModel> getSummary() => loadSummary();

  @override
  Future<CurrencyHistoryPageModel> getHistory({
    required WalletCurrency currency,
    String? cursor,
    int limit = 20,
  }) => throw UnimplementedError();
}

final _summary = WalletSummaryModel(
  contractVersion: 'wallet.v1',
  star: BigInt.zero,
  bonus: BigInt.from(1500),
  cotton: BigInt.from(50),
  cottonExpiringAmount: BigInt.from(10),
  cottonNextExpiresAt: DateTime.utc(2026, 7, 24, 3, 30),
  snapshotAt: DateTime.utc(2026, 7, 23),
);

/// 일부러 월 오름차순이 아니게 둔다 — 화면이 정렬하는지 보려고.
const _bonusRows = [
  {'prediction_month': '2026-09', 'expiring_amount': 300},
  {'prediction_month': '2026-08', 'expiring_amount': 1200},
];

/// 실기기에서 보고된 기기(1080x2400 @ DPR 3.0 = 360x800)와 레포가 이미 하한으로
/// 못박아 둔 320dp 를 포함한다.
const _devices = <Size>[
  Size(320, 568),
  Size(320, 640),
  Size(360, 800),
  Size(375, 667),
  Size(393, 873),
  Size(411.4, 914.3),
];

Future<void> _pumpPopup(
  WidgetTester tester, {
  required Size size,
  Locale locale = const Locale('ko'),
  double textScale = 1.0,
  bool loggedIn = true,
  List<Map<String, dynamic>>? bonusRows = _bonusRows,
  Object? bonusError,
}) async {
  if (loggedIn) {
    await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
  }
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    buildTestApp(
      const Material(color: Colors.transparent, child: UsagePolicyPopup()),
      loggedIn: loggedIn,
      locale: locale,
      // 프로덕션과 같은 ScreenUtil 기하.
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
      extraOverrides: [
        expireBonusProvider.overrideWith(
          (ref) async =>
              bonusError != null ? throw bonusError : (bonusRows ?? const []),
        ),
        walletRepositoryProvider.overrideWithValue(
          _WalletRepository.value(_summary),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(UsagePolicyPopup)));

/// ARB 에 리터럴로 박힌 불릿 접두사를 위젯과 같은 규칙으로 떼어낸다.
String _stripBullet(String raw) =>
    raw.replaceFirst(RegExp(r'^\s*[-•·]\s*'), '');

/// 접힘 헤더는 스크롤 밖에 있을 수 있다. 눌러야 하면 먼저 화면 안으로 끌어온다.
///
/// 탭 이후에 `pumpAndSettle` 만 하면 부족하다. 펼침 애니메이션(200ms) 이 끝난
/// 뒤에 스크롤을 걸기 위해 위젯이 232ms 타이머를 쓰는데, 그 사이에 예약된
/// 프레임이 없으면 `pumpAndSettle` 은 200ms 에서 멈춰서 타이머가 발화하지 않는다
/// (가짜 시계라서 실기기와 달리 저절로 흐르지 않는다).
Future<void> _openDisclosure(WidgetTester tester, String title) async {
  final header = find.text(title);
  expect(header, findsOneWidget, reason: 'disclosure header "$title"');
  await tester.ensureVisible(header);
  await tester.pumpAndSettle();
  await tester.tap(header);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// 이미 펼쳐진 블록은 건드리지 않는다 — 누르면 오히려 닫힌다.
bool _isOpen(WidgetTester tester, String title) {
  final l = _l10n(tester);
  if (title == l.bonus_candy_expiration_time_title) {
    return find
        .text(l.bonus_candy_expiration_policy_earn_period)
        .evaluate()
        .isNotEmpty;
  }
  if (title == l.bonus_candy_example_title) {
    return find.text(l.bonus_candy_example_earn_date).evaluate().isNotEmpty;
  }
  return find.text(_stripBullet(l.bonus_candy_policy_1)).evaluate().isNotEmpty;
}

Future<void> _openAllDisclosures(WidgetTester tester) async {
  final l = _l10n(tester);
  for (final title in [
    l.bonus_candy_expiration_time_title,
    l.bonus_candy_example_title,
    l.bonus_candy_policy_title,
  ]) {
    if (_isOpen(tester, title)) continue;
    await _openDisclosure(tester, title);
  }
}

Finder get _shellFinder => find.byType(FullScreenDialog);

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

double _cueOpacity(WidgetTester tester, {bool top = false}) => tester
    .widget<AnimatedOpacity>(
      find.descendant(
        of: find.byKey(Key(top ? 'scroll-cue-top' : 'scroll-cue-bottom')),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

Rect _globalRect(Element element) {
  final box = element.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// 전체 화면 셸은 라운드 코너 없이 화면 경계에서 콘텐츠를 자른다.
RRect _shellClip(WidgetTester tester) =>
    RRect.fromRectAndRadius(tester.getRect(_shellFinder), Radius.zero);

/// 지금 화면에서 읽으라고 내놓은 모든 텍스트가 코너 웨지 밖에 있는지 본다.
///
/// 바닥 신호(56px)에 덮이는 구간은 제외한다 — 거기 있는 글자는 스크롤 도중
/// 흰색으로 지워지는 게 설계다. 뷰포트 위로 밀려난 글자도 제외한다(뷰포트가
/// 자기 경계에서 잘라내므로 카드 코너와 무관하다).
void _expectTextInsideClip(WidgetTester tester, {required String at}) {
  final clip = _shellClip(tester);
  final viewport = tester.getRect(find.byType(SingleChildScrollView));
  final cue = _position(tester).extentAfter > 1 ? 56.0 : 0.0;
  final offenders = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final rect = _globalRect(element);
    if (rect.isEmpty) continue;
    if (rect.top < viewport.top - 0.01) continue;
    if (rect.bottom > viewport.bottom - cue + 0.01) continue;
    final outside = <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ].where((p) => !clip.contains(p));
    if (outside.isEmpty) continue;
    offenders.add('"${(element.widget as Text).data}" $rect');
  }
  expect(offenders, isEmpty, reason: 'clipped by the card corner arc ($at)');
}

void main() {
  // 이 패키지에는 flutter_test_config.dart 가 없어서 파일마다 직접 폰트를
  // 실어야 한다. 폴백 폰트로 재면 오버플로 측정이 전부 어긋난다.
  setUpAll(() async {
    await loadTestFonts();
  });

  setUp(() {
    initTestColors();
    setupMockSupabase({});
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('T1 오버플로 없음', () {
    // 설정마다 새 위젯 트리여야 한다 — RenderFlex 는 렌더 오브젝트당 오버플로를
    // 한 번만 보고하므로, 트리를 공유하면 두 번째 설정부터 조용해진다.
    for (final size in _devices) {
      for (final locale in const [
        Locale('ko'),
        Locale('en'),
        Locale('fil'),
        Locale('bn'),
      ]) {
        for (final scale in const [1.0, 1.5, 2.0]) {
          testWidgets(
            '${size.width}x${size.height} ${locale.languageCode} x$scale',
            (tester) async {
              await _pumpPopup(
                tester,
                size: size,
                locale: locale,
                textScale: scale,
              );
              expect(tester.takeException(), isNull);
              await _openAllDisclosures(tester);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });

  group('T2 전체 화면 경계 안전 — 쉬는 상태와 끝까지 내린 상태', () {
    for (final size in const [
      Size(320, 640),
      Size(360, 800),
      Size(411.4, 914.3),
    ]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('${size.width}x${size.height} x$scale', (tester) async {
          await _pumpPopup(tester, size: size, textScale: scale);

          final shell = tester.getRect(_shellFinder);
          expect(shell.left, closeTo(0, 0.01));
          expect(shell.top, closeTo(0, 0.01));
          expect(shell.width, closeTo(size.width, 0.01));
          expect(shell.height, closeTo(size.height, 0.01));

          _expectTextInsideClip(tester, at: 'at rest');

          await _openAllDisclosures(tester);
          final position = _position(tester);
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          _expectTextInsideClip(tester, at: 'at maxScrollExtent');
        });
      }
    }
  });

  group('T3 점진적 공개', () {
    testWidgets('소멸 예정 행이 있으면 예시는 접혀 있고, 눌러야 열린다', (tester) async {
      await _pumpPopup(tester, size: const Size(393, 873));
      final l = _l10n(tester);

      // 접힌 본문은 트리에서 아예 빠진다(Offstage 가 아니다).
      expect(find.text(l.bonus_candy_example_earn_date), findsNothing);
      expect(
        find.text(l.bonus_candy_expiration_policy_earn_period),
        findsNothing,
      );
      // 헤더는 접혀 있어도 보인다.
      expect(find.text(l.bonus_candy_example_title), findsOneWidget);
      expect(find.byKey(const Key('candy-policy-section')), findsOneWidget);
      // 정책은 소비자 고지라서 **처음부터 펼쳐져 있다**. 접힌 본문은 트리에서
      // 빠지므로, 접어 두면 '아래에 있다' 가 아니라 '안 보여준다' 가 된다.
      expect(find.text(_stripBullet(l.bonus_candy_policy_1)), findsOneWidget);
      expect(find.text(_stripBullet(l.bonus_candy_policy_2)), findsOneWidget);
      expect(find.text(_stripBullet(l.bonus_candy_policy_3)), findsOneWidget);

      await _openDisclosure(tester, l.bonus_candy_example_title);
      // 레이블은 그룹마다 반복돼 행이 스스로를 설명한다.
      expect(find.text(l.bonus_candy_example_earn_date), findsNWidgets(2));
      expect(
        find.text(l.bonus_candy_example_expiration_date),
        findsNWidgets(2),
      );
    });

    testWidgets('소멸 예정 행이 없으면 소멸 시점 안내가 처음부터 펼쳐진다', (tester) async {
      await _pumpPopup(tester, size: const Size(393, 873), bonusRows: const []);
      final l = _l10n(tester);
      expect(
        find.text(l.bonus_candy_expiration_policy_earn_period),
        findsNWidgets(2),
      );
      expect(find.text(l.bonus_candy_earn_period_1_to_14), findsOneWidget);
      expect(find.text(l.bonus_candy_earn_period_15_to_end), findsOneWidget);
      // 예시는 그대로 접혀 있다.
      expect(find.text(l.bonus_candy_example_earn_date), findsNothing);
    });

    testWidgets('소멸 예정 행은 prediction_month 오름차순으로 정렬된다', (tester) async {
      await _pumpPopup(tester, size: const Size(393, 873));
      final first = tester.getTopLeft(find.text('2026-08-15 (KST)'));
      final second = tester.getTopLeft(find.text('2026-09-15 (KST)'));
      expect(first.dy, lessThan(second.dy));
    });
  });

  testWidgets('T4 기본 상태에서는 스크롤이 없다 (393x873, ko, 소멸 예정 2건)', (tester) async {
    await _pumpPopup(tester, size: const Size(393, 873));
    expect(_position(tester).maxScrollExtent, 0.0);

    // 셸은 이전의 0.82H 라운드 카드가 아니라 정확히 전체 화면을 사용한다.
    final shellRect = tester.getRect(_shellFinder);
    expect(shellRect, const Rect.fromLTWH(0, 0, 393, 873));
  });

  group('T5 예시 플레이스홀더 치환 (대소문자 무관)', () {
    // vi/fil 은 __Month__, th 는 전부 소문자, bn 은 올바른 __NEXT_MONTH__ 와
    // 깨진 __The_month_after_next__ 를 섞어 싣고 있다. 대소문자를 구분하던
    // 예전 replaceAll 에서는 이 로케일들이 24자 토큰을 그대로 노출했다.
    for (final locale in const [
      Locale('fil'),
      Locale('th'),
      Locale('vi'),
      Locale('bn'),
    ]) {
      testWidgets(locale.languageCode, (tester) async {
        await _pumpPopup(
          tester,
          size: const Size(393, 873),
          locale: locale,
          loggedIn: false,
        );
        await _openDisclosure(tester, _l10n(tester).bonus_candy_example_title);

        final leaked = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .where((s) => s.contains('__'))
            .toList();
        expect(leaked, isEmpty, reason: 'raw placeholder leaked to the user');
      });
    }
  });

  group('T6 상태 매트릭스', () {
    testWidgets('보너스 조회 실패가 다이얼로그를 대체하지 않는다', (tester) async {
      await _pumpPopup(
        tester,
        size: const Size(393, 873),
        bonusError: StateError('bonus unavailable'),
      );
      final l = _l10n(tester);

      // 실패는 보너스 카드 안에서만 말하고, 나머지는 전부 살아 있다.
      expect(
        find.text(l.bonus_candy_expiration_policy_load_fail),
        findsOneWidget,
      );
      expect(find.byKey(const Key('cotton-candy-section')), findsOneWidget);
      expect(find.byKey(const Key('bonus-star-candy-section')), findsOneWidget);
      expect(find.byKey(const Key('candy-policy-section')), findsOneWidget);
      expect(find.text(l.cotton_candy_daily_expiry_notice), findsOneWidget);
      // 개인 행이 없으니 소멸 시점 안내는 펼쳐져 있다.
      expect(
        find.text(l.bonus_candy_expiration_policy_earn_period),
        findsNWidgets(2),
      );

      // 보너스를 모르는 상태에서 "오늘 만료 : 코튼캔디 N" 이라고 단정하면 안
      // 된다. 실제 소멸일(매월 15일 KST)에는 그 문장이 틀린다.
      expect(find.byKey(const Key('expiry-today-summary')), findsNothing);
      expect(find.text(l.expiring_today_cotton_only('10')), findsNothing);
    });

    testWidgets('비로그인: 히어로가 없고 두 카드와 세 구분선은 남는다', (tester) async {
      await _pumpPopup(tester, size: const Size(393, 873), loggedIn: false);
      final l = _l10n(tester);
      expect(find.byKey(const Key('expiry-today-summary')), findsNothing);
      expect(find.byKey(const Key('cotton-candy-section')), findsOneWidget);
      expect(find.byKey(const Key('bonus-star-candy-section')), findsOneWidget);
      // 표를 지운 뒤에도 구분선은 남아야 한다(기존 테스트 :281 이 이걸 본다).
      expect(find.byType(Divider), findsWidgets);

      // 소멸 예정 행이 없어도 보너스 카드는 제목만 남은 빈 분홍 막대가 되면
      // 안 된다 — 코튼캔디 카드의 규칙 한 줄과 짝이 되는 문장을 갖는다.
      expect(
        find.descendant(
          of: find.byKey(const Key('bonus-star-candy-section')),
          matching: find.textContaining(l.bonus_candy_expiration_next_month),
        ),
        findsOneWidget,
      );
    });

    testWidgets('0 소멸 예정은 긴급 강조색을 쓰지 않는다', (tester) async {
      final zero = WalletSummaryModel(
        contractVersion: 'wallet.v1',
        star: BigInt.zero,
        bonus: BigInt.zero,
        cotton: BigInt.zero,
        cottonExpiringAmount: BigInt.zero,
        cottonNextExpiresAt: null,
        snapshotAt: DateTime.utc(2026, 7, 23),
      );
      await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
      tester.view.physicalSize = const Size(393, 873) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          const Material(color: Colors.transparent, child: UsagePolicyPopup()),
          loggedIn: true,
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
          extraOverrides: [
            expireBonusProvider.overrideWith((ref) async => const []),
            walletRepositoryProvider.overrideWithValue(
              _WalletRepository.value(zero),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final hero = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('expiry-today-summary')),
          matching: find.byType(Text),
        ),
      );
      expect(hero.style?.fontSize, 14.0);
      expect(hero.style?.fontWeight, FontWeight.w500);
    });
  });

  group('T7 펼친 내용이 전체 화면 뷰포트 안에 드러난다', () {
    for (final size in const [Size(320, 568), Size(320, 640)]) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpPopup(tester, size: size);
        final l = _l10n(tester);
        final position = _position(tester);
        expect(position.pixels, 0.0);

        // 이 헤더는 쉬는 상태에서 이미 화면에 있다. `tester.ensureVisible` 로
        // 미리 스크롤하면 위젯이 스크롤했는지 테스트가 스크롤했는지 구분할 수
        // 없어지므로, 여기서는 절대 쓰지 않는다.
        final header = find.text(l.bonus_candy_expiration_time_title);
        expect(
          tester.getRect(header).bottom,
          lessThan(tester.getRect(find.byType(SingleChildScrollView)).bottom),
        );
        await tester.tap(header);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // 드러난 첫 행이 뷰포트 안에 완전히 들어와야 한다.
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        final firstRow = tester.getRect(
          find.text(l.bonus_candy_expiration_policy_earn_period).first,
        );
        expect(firstRow.top, greaterThanOrEqualTo(viewport.top - 0.01));
        expect(firstRow.bottom, lessThanOrEqualTo(viewport.bottom + 0.01));
        // 제목은 밀려나지 않는다 — 블록이 뷰포트보다 길어도 머리는 남긴다.
        expect(
          tester.getRect(header).top,
          greaterThanOrEqualTo(viewport.top - 0.01),
        );
      });
    }
  });

  group('T8 바닥 신호', () {
    testWidgets('내용이 다 보이면 꺼져 있다 (360x800 = 보고된 기기)', (tester) async {
      await _pumpPopup(tester, size: const Size(360, 800));
      expect(_position(tester).maxScrollExtent, 0.0);
      expect(_cueOpacity(tester), 0.0);
    });

    testWidgets('펼쳐서 내용이 넘치면 손대지 않아도 켜진다 (360x800)', (tester) async {
      await _pumpPopup(tester, size: const Size(360, 800));
      final l = _l10n(tester);
      final position = _position(tester);
      expect(_cueOpacity(tester), 0.0);

      // 이 기기에서는 소멸 시점 안내를 펼쳐도 블록 자체는 뷰포트 안에 들어가서
      // **스크롤이 일어나지 않는다**. 즉 ScrollNotification 도 오지 않는다.
      // 그래도 아래로 밀려난 예시 · 정책이 생기므로 신호는 켜져야 한다 —
      // 내용 크기 변화는 ScrollMetricsNotification 으로만 오기 때문에, 이걸
      // 듣지 않으면 사용자가 손으로 끌기 전까지 신호가 뜨지 않는다.
      await _openDisclosure(tester, l.bonus_candy_expiration_time_title);

      expect(position.pixels, 0.0, reason: 'no scroll happened in this case');
      expect(position.extentAfter, greaterThan(1.0));
      expect(_cueOpacity(tester), 1.0);
    });

    testWidgets('끝까지 내리면 아래 신호가 꺼지고 위 신호가 켜진다 (320x568)', (tester) async {
      await _pumpPopup(tester, size: const Size(320, 568));
      final position = _position(tester);
      expect(position.maxScrollExtent, greaterThan(0.0));
      expect(_cueOpacity(tester), 1.0);
      expect(_cueOpacity(tester, top: true), 0.0);

      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(_cueOpacity(tester), 0.0);
      // 위쪽도 같은 문제를 갖는다: 뷰포트 위 경계에서 글자가 생으로 잘리고 그
      // 위에 흰 여백이 남는다.
      expect(_cueOpacity(tester, top: true), 1.0);
    });
  });
}
