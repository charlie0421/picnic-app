import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/factories/artist_factory.dart';
import '../../../helpers/factories/vote_factory.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

// 이 파일에는 렌더 오류 억제 헬퍼가 없다.
//
// 예전에는 `_ignoreRenderErrors` 가 `overflowed` 가 들어간 FlutterError 를 전부
// 삼켰고, 그 바람에 카드가 캐러셀 페이지 폭에서 가로로 넘치는 결함(기기별
// 19~78px)이 이 파일에서 영영 보이지 않았다. 같이 삼키던
// LateInitializationError 도 지금은 나지 않는다(억제를 걷어도 전부 초록).
// 다시 넣지 말 것 — 넣는 순간 아래 회귀 그룹이 무력해진다.

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
}

/// 실기기 논리 해상도(포인트). `home_featured_vote_carousel_test.dart` 와 같은
/// 매트릭스 — 같은 위젯의 같은 기하를 재므로 두 파일이 갈라지면 안 된다.
const _devices = <String, Size>{
  'iPhone SE 2/3 (375x667)': Size(375, 667),
  'iPhone 13 mini (375x812)': Size(375, 812),
  'iPhone 14 (390x844)': Size(390, 844),
  'iPhone 16 (393x852)': Size(393, 852),
  'iPhone 17 Pro (402x874)': Size(402, 874),
  'iPhone 17 Pro Max (440x956)': Size(440, 956),
  'small Android (360x640)': Size(360, 640),
};

/// `DD D HH : MM : SS` — 남은 일수가 두 자리인 동안 타일은 여덟 개다.
const _digitTileCount = 8;

/// 화면에 찍힌 숫자 타일이 이보다 작으면 안에 든 12px 글자가 잘린다.
///
/// [CountdownTimer.digitSize] 를 그대로 쓰면 "타일을 0 으로 줄여 오버플로를
/// 없앤다" 는 회귀가 그대로 통과한다. 그래서 기대값을 테스트에 박아 둔다.
const _minTileExtent = 16.0;

/// 캐러셀이 카드에게 **실제로** 주는 사각형.
///
/// `PageView(viewportFraction: 0.82)` 는 페이지에 `뷰포트 폭 * 0.82` 를 tight
/// 하게 물려주고, 그 안에서 카드가 [HomeFeaturedVoteCarousel.pageMargin] 만큼
/// 더 들어간다. 카드를 화면 폭 그대로 놓고 재면 앱에 존재하지 않는(20% 더 넓은)
/// 폭에서 재게 되어 오버플로가 사라진다.
Widget _carouselPage(double viewportWidth, Widget card) => SizedBox(
      width: viewportWidth * HomeFeaturedVoteCarousel.viewportFraction,
      height: HomeFeaturedVoteCarousel.viewportHeight,
      child: Padding(
        padding: HomeFeaturedVoteCarousel.pageMargin,
        child: card,
      ),
    );

Future<void> _pumpCardInPage(
  WidgetTester tester,
  Size device, {
  double textScale = 1.0,
}) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = device * 3.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final vote = VoteFactory.create(
    id: 1,
    title: const {'ko': '진행중 투표', 'en': 'Active vote'},
    // 남은 일수 두 자리 = 타일 여덟 개. 실제 운영 투표의 일반적인 상태다.
    stopAt: DateTime.now().toUtc().add(const Duration(days: 7)),
    voteItem: [
      VoteItemFactory.create(
        id: 1,
        voteTotal: 1000,
        artist: ArtistFactory.create(id: 1),
      ),
    ],
  );

  await tester.pumpWidget(
    buildTestApp(
      Align(
        alignment: Alignment.topCenter,
        child: _carouselPage(
          device.width,
          HomeFeaturedVoteCard(vote: vote, percent: 0.62),
        ),
      ),
      // 하네스 기본값(375x812, splitScreenMode 없음)은 실제 앱과 달라 `.w`/`.r`
      // 환산이 어긋난다. 오버플로는 그 환산값에 직접 좌우된다.
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
    ),
  );
  await tester.pump();
}

/// 남은시간 표시가 카드 안에 **온전한 크기로** 들어갔는지 확인한다.
///
/// 오버플로 예외 하나만 보면 다음 우회들이 전부 초록으로 통과한다:
///   * 타일을 0 으로 줄이기 -> [_minTileExtent] 가 잡는다.
///   * 타일을 아예 지우기 -> `findsOneWidget` 이 잡는다.
///   * 행을 가로 스크롤뷰로 감싸기 -> 오른쪽 타일이 프레임 밖에 놓여 잡힌다.
///   * [FittedBox]/[Transform] 으로 축소 -> 레이아웃 크기와 화면 크기가
///     달라지므로 잡힌다(`getSize` 는 레이아웃, `getRect` 는 변환 후).
void _expectCountdownFitsCard(WidgetTester tester, String label) {
  final frame = find.byKey(HomeFeaturedVoteCard.frameKey);
  expect(frame, findsOneWidget);
  // 카드는 clipBehavior: Clip.antiAlias 라 프레임 밖은 릴리즈 빌드에서 조용히
  // 잘린다. "프레임 안에 있는가" 가 곧 "사용자가 볼 수 있는가" 다.
  final bounds = tester.getRect(frame).inflate(0.01);

  void expectIntact(Finder finder, String what) {
    final layout = tester.getSize(finder);
    final onScreen = tester.getRect(finder);
    expect(
      onScreen.size.width,
      closeTo(layout.width, 0.01),
      reason: '$label: $what — 화면에서 가로로 축소됐다. FittedBox/Transform 으로 '
          '오버플로를 숨기면 남은시간이 읽히지 않는다',
    );
    expect(
      onScreen.size.height,
      closeTo(layout.height, 0.01),
      reason: '$label: $what — 화면에서 세로로 축소됐다',
    );
    expect(
      bounds.contains(onScreen.topLeft) && bounds.contains(onScreen.bottomRight),
      isTrue,
      reason: '$label: $what — 카드 프레임($bounds) 밖으로 나갔다. 카드가 잘라내므로 '
          '실기기에서는 보이지 않는다. 실측 $onScreen',
    );
  }

  for (var i = 0; i < _digitTileCount; i++) {
    final tile = find.byKey(CountdownTimer.digitKey(i));
    expect(
      tile,
      findsOneWidget,
      reason: '$label: 남은시간 $i 번째 숫자 타일이 없다 — 타일을 지워 오버플로를 '
          '없애는 것은 수정이 아니다',
    );
    final size = tester.getSize(tile);
    expect(
      size.height,
      greaterThanOrEqualTo(_minTileExtent),
      reason: '$label: $i 번째 타일이 너무 작다(${size.height}) — 안의 12px 숫자가 '
          '잘린다',
    );
    expectIntact(tile, '$i 번째 숫자 타일');
  }

  final timer = find.byType(CountdownTimer);
  final dayUnit = find.descendant(of: timer, matching: find.text('D'));
  final colons = find.descendant(of: timer, matching: find.text(':'));
  expect(dayUnit, findsOneWidget, reason: '$label: 일(D) 단위 표기가 없다');
  expect(colons, findsNWidgets(2), reason: '$label: 시:분:초 구분자가 없다');
  expectIntact(dayUnit, '일(D) 단위 표기');
  for (var i = 0; i < 2; i++) {
    expectIntact(colons.at(i), '$i 번째 구분자');
  }
}

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({});
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });

  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    tearDownMockSupabase();
  });

  group('HomeFeaturedVoteCard widget rendering', () {
    testWidgets('renders title and rank-1 item only', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final rank1 = VoteItemFactory.create(
        id: 1,
        voteTotal: 12345,
        artist: ArtistFactory.create(
          id: 1,
          name: const {'ko': '지민', 'en': 'Jimin'},
        ),
      );
      final rank2 = VoteItemFactory.create(
        id: 2,
        voteTotal: 9999,
        artist: ArtistFactory.create(
          id: 2,
          name: const {'ko': '정국', 'en': 'Jungkook'},
        ),
      );
      final vote = VoteFactory.create(
        id: 1,
        title: const {'ko': '홈 투표 테스트', 'en': 'Home Vote Test'},
        voteItem: [rank1, rank2],
      );

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 420,
            child: HomeFeaturedVoteCard(vote: vote, percent: 0.62),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomeFeaturedVoteCard), findsOneWidget);
      // 제목 렌더 확인
      expect(find.text('홈 투표 테스트'), findsOneWidget);
      // rank-1 아티스트 이름 렌더 확인
      expect(find.text('지민'), findsOneWidget);
      // 퍼센트 렌더 확인(숫자 대신 퍼센트)
      expect(find.text('62.0%'), findsOneWidget);
      // rank-2는 렌더되지 않아야 함
      expect(find.text('정국'), findsNothing);
    });

    testWidgets('renders gracefully with empty vote items', (tester) async {
      _setMobileViewSize(tester);
      addTearDown(() => tester.view.resetPhysicalSize());

      final vote = VoteFactory.create(
        id: 2,
        title: const {'ko': '빈 투표', 'en': 'Empty Vote'},
        voteItem: [],
      );

      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            height: 420,
            child: HomeFeaturedVoteCard(vote: vote),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomeFeaturedVoteCard), findsOneWidget);
      expect(find.text('빈 투표'), findsOneWidget);
    });
  });

  // 회귀 방지: 카드가 캐러셀 페이지(뷰포트의 82%)에 놓이면 남은시간 행이 가로로
  // 넘쳤다. 수정 전 실측(하네스 폰트): 360x640 78px, 375 67px, 390 55px,
  // 393 53px, 402 47px, 440 19px — 즉 지원 기기 **전부**. 릴리즈 빌드에는 노란
  // 줄무늬가 없으므로 사용자는 카운트다운 양끝이 잘린 화면을 보게 된다.
  //
  // 원인은 이 행의 폭 수요가 기기와 무관한 상수였다는 것: 숫자 타일 여덟 개가
  // 고정 18px + 좌우 4px 마진(= 208px)이고 구분자 문자열(`' : '`)이 공백으로
  // 여백을 한 번 더 냈다. 반면 공급(카드 폭)은 화면 폭에 비례한다.
  group('HomeFeaturedVoteCard fits the carousel page', () {
    for (final entry in _devices.entries) {
      testWidgets('countdown fits on ${entry.key}', (tester) async {
        await _pumpCardInPage(tester, entry.value);

        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key}: 카드 렌더 중 예외가 났다 '
              '(가로 오버플로면 남은시간이 잘린다)',
        );
        _expectCountdownFitsCard(tester, entry.key);
      });
    }

    // 텍스트 배율은 이 행의 유일한 가변 차원이다(타일은 고정, 구분자 글자만
    // 배율을 탄다). 대부분 플랫폼의 "가장 크게" 설정이 1.3 부근이므로 거기까지
    // 못박는다. 구분자 여백을 다시 공백 문자로 되돌리면 여백까지 배율을 타면서
    // 여기서 깨진다.
    for (final entry in <String, Size>{
      'small Android (360x640)': const Size(360, 640),
      'iPhone 16 (393x852)': const Size(393, 852),
    }.entries) {
      testWidgets('countdown fits on ${entry.key} at textScale 1.3',
          (tester) async {
        await _pumpCardInPage(tester, entry.value, textScale: 1.3);

        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} @1.3: 카드 렌더 중 예외가 났다',
        );
        _expectCountdownFitsCard(tester, '${entry.key} @1.3');
      });
    }
  });
}
