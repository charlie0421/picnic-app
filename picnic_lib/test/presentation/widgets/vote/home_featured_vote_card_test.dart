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
import '../../../helpers/load_test_fonts.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

// 이 파일에는 렌더 오류 억제 헬퍼가 없다.
//
// 예전에는 `_ignoreRenderErrors` 가 `overflowed` 가 들어간 FlutterError 를 전부
// 삼켰고, 그 바람에 카드가 캐러셀 페이지 폭에서 가로로 넘치는 결함이 이 파일에서
// 영영 보이지 않았다. 같이 삼키던 LateInitializationError 도 지금은 나지 않는다
// (억제를 걷어도 전부 초록). 다시 넣지 말 것 — 넣는 순간 아래 회귀 그룹이
// 무력해진다.

void _setMobileViewSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1125, 2436);
  tester.view.devicePixelRatio = 3.0;
}

/// 실기기 논리 해상도(포인트). `home_featured_vote_carousel_test.dart` 와 같은
/// 매트릭스 — 같은 위젯의 같은 기하를 재므로 두 파일이 갈라지면 안 된다.
///
/// **320dp 가 이 목록의 핵심이다.** 프로덕션 폰트에서 남은시간 행이 실제로
/// 카드 밖까지 잘려 보이던 폭이 거기뿐이기 때문이다(아래 그룹 주석의 표 참고).
/// 예전 매트릭스는 360dp 가 하한이었는데, 그건 기기 목록의 판단이 아니라 하네스
/// 기본 폰트의 한계였다: 그 폰트로 재면 폭 수요가 22px 부풀어(224.5 vs 202.8),
/// **수정 후** 레이아웃마저 320dp 에서 2.2px(배율 1.3 이면 13.0px) 넘쳤다. 정작
/// 프로덕션이 잘리는 폭이 320dp 인데, 하네스 폰트로는 그 한 칸을 빨갛지 않게
/// 넣을 방법이 없었던 것이다. 이제 [loadTestFonts] 로 진짜 폰트를 물려 재므로
/// 320dp 를 넣을 수 있다.
const _devices = <String, Size>{
  // 320dp: iPhone SE 1세대 급 하드웨어, 그리고 360dp 기기에서 안드로이드
  // "디스플레이 크기" 를 키운 상태. 결함이 눈에 보이던 유일한 구간이다.
  'narrow Android (320x640)': Size(320, 640),
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

/// 화면에 찍힌 숫자 타일의 한 변이 이보다 작으면 안에 든 12px 글자가 잘린다.
///
/// [CountdownTimer.digitSize] 를 그대로 쓰면 "타일을 0 으로 줄여 오버플로를
/// 없앤다" 는 회귀가 그대로 통과한다. 그래서 기대값을 테스트에 박아 둔다.
/// 가로·세로 **양쪽**에 건다 — 이유는 `_expectCountdownFitsCard` 참고.
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
///   * 타일을 0 으로 줄이기 -> [_minTileExtent] 를 가로·세로 **양쪽**에 건다.
///     부족한 축은 가로뿐이라 `width: 0, height: 18` 처럼 한 축만 눌러도
///     오버플로가 사라진다. 높이만 재던 시절에는 그 우회가 전 케이스 초록이었다.
///   * 타일을 아예 지우기 -> `findsOneWidget` 이 잡는다.
///   * 폭 수요를 되돌린 뒤 가로 스크롤뷰나 [FittedBox]/[Transform] 으로 예외만
///     지우기 -> 오른쪽 타일이 카드 프레임 밖에 놓이거나(스크롤뷰), 레이아웃
///     크기와 화면 크기가 달라져서(FittedBox) 잡힌다. `getSize` 는 레이아웃,
///     `getRect` 는 변환 뒤 값이라 둘을 비교하면 축소가 드러난다.
///
/// 반대로 폭이 이미 맞는 상태에서 스크롤뷰만 씌우는 건 이 헬퍼가 잡지 않는다.
/// 그때는 감출 오버플로 자체가 없어서 사용자 화면도 달라지지 않는다.
void _expectCountdownFitsCard(WidgetTester tester, String label) {
  final frame = find.byKey(HomeFeaturedVoteCard.frameKey);
  expect(frame, findsOneWidget);
  // 넘친 행 자체는 아무것도 자르지 않는다(`Flex.clipBehavior` 기본값은
  // `Clip.none`). 실제로 잘라내는 경계는 `clipBehavior: Clip.antiAlias` 인 카드
  // 프레임뿐이고, 행에서 흘러넘친 몫은 먼저 카드의 `16.w` 좌우 패딩이 삼킨다.
  // 그래서 "행 밖으로 나갔는가" 가 아니라 "프레임 안에 있는가" 가 곧 "사용자가
  // 볼 수 있는가" 다.
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
    // 가로를 먼저 본다. 부족한 축이 가로뿐이라 `width: 0` 으로 타일을 납작하게
    // 눌러도 여덟 개를 다 그린 채 오버플로만 사라진다 — 세로만 재면 그 우회가
    // 전부 초록이다(높이만 재던 이전 판 실측: `width: 0, height: 18` 로 11개
    // 테스트가 숫자 여덟 개를 폭 0 으로 그린 채 전부 통과했다).
    expect(
      size.width,
      greaterThanOrEqualTo(_minTileExtent),
      reason: '$label: $i 번째 타일이 가로로 너무 좁다(${size.width}) — 타일을 눌러 '
          '폭 수요를 줄이는 것은 수정이 아니다. 안의 12px 숫자가 잘린다',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(_minTileExtent),
      reason: '$label: $i 번째 타일이 세로로 너무 낮다(${size.height}) — 안의 12px '
          '숫자가 잘린다',
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
  // 이 파일은 폭을 px 단위로 재므로, 글리프 폭이 실제와 다른 폰트로 재면 결론이
  // 통째로 바뀐다. 하네스 기본 폰트는 12px 공백 글리프가 13.5px(Pretendard 는
  // 5.1px)이라 남은시간 행의 폭 수요를 76px(수정 전) / 22px(수정 후) 부풀리고,
  // 히어로 행에서는 배율 1.8 이상에서 실제로는 없는 오버플로를 만든다.
  //
  // 한때 `getTextStyle` 이 `package:` 없이 맨 'Pretendard' 를 요청해 프로덕션이
  // 플랫폼 기본 폰트로 렌더되는 이슈가 있었고, 그때는 "Pretendard 로 재도
  // Roboto/SF Pro 와 0.5px 안쪽" 이라는 근거로 이 폰트를 물렸다. 그 이슈가
  // 고쳐진 지금은 프로덕션이 문자 그대로 Pretendard 이므로, 여기 측정이 곧
  // 프로덕션 측정이다.
  //
  // [loadTestFonts] 는 Regular(400)/Bold(700)만 물린다. 이 행이 쓰는 w500 은
  // Regular 로 대체되는데 폭 차이는 0.3px 수준이라 결론에 영향이 없다. 골든
  // 테스트 두 개가 같은 헬퍼를 쓰므로 여기 사정으로 헬퍼를 늘리지 않는다.
  setUpAll(loadTestFonts);

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
  // 넘쳤다. 원인은 이 행의 폭 수요가 기기와 무관한 상수였다는 것 — 숫자 타일
  // 여덟 개가 고정 18px + 좌우 4px 마진(= 208px)이고 구분자 문자열(`' : '`)이
  // 공백으로 여백을 한 번 더 냈다. 반면 공급(카드 안쪽 폭)은 화면 폭에 비례한다.
  //
  // 결함의 크기를 정확히 적어 둔다. 폰트마다 다르고, 이 파일이 무엇을 지키는지가
  // 거기 달려 있다. 배율 1.0 에서 잰 행의 폭 수요:
  //
  //   폰트                     수정 전   수정 후
  //   하네스 기본 폰트          329.5    224.5
  //   Pretendard               253.9    202.8
  //   Roboto (Android 프로덕션)  253.6    202.7
  //   SF Pro (iOS 프로덕션)     257.5    204.8
  //
  // 공급(카드 안쪽 폭)은 320dp 222.3 / 360dp 251.9 / 375dp 263.0 / 390dp 274.0 /
  // 393dp 276.3 / 402dp 282.9 / 440dp 311.0. 프로덕션 폰트 기준으로 정리하면:
  //
  //   * 배율 1.0 에서 행이 넘치는(= 디버그 빌드에서 예외가 나는) 구간은 폭
  //     363dp 미만이다. 360dp 는 아슬아슬하게 들어가고 375dp 부터는 남는다.
  //   * 넘친다고 잘리는 게 아니다. 행 자체는 자르지 않고(`Clip.none`) 넘친 몫을
  //     카드의 `16.w` 좌우 패딩이 먼저 삼킨다. **눈에 보이게 잘리는** 구간은
  //     342dp 미만(SF Pro 는 347dp)이다. 360dp 는 수정 전에도 마지막 타일이 행
  //     밖으로 2.0px 나갔을 뿐 카드 프레임 안으로는 13.7px 여유가 있었다.
  //   * 배율을 올리면 잘리는 폭도 올라간다(수정 전 실측, 프레임 밖으로 나간 양):
  //     320dp 는 배율 1.0 부터 17.5px, 360dp 는 1.5 부터 2.5px, 375dp 는 1.8
  //     부터 0.6px. 390dp 이상은 배율 2.0 에서도 프레임 안이다.
  //   * 그러니 사용자가 잘린 카운트다운을 실제로 본 건 320dp 하드웨어,
  //     360dp 기기에서 안드로이드 "디스플레이 크기" 를 키운 경우, 또는 글자
  //     크기를 크게 키운 좁은 기기다. "지원 기기 전부" 가 아니다.
  //   * 잘리는 쪽은 **오른쪽 한쪽뿐**이다. `MainAxisAlignment.center` 는 남는
  //     공간을 0 으로 clamp 하므로, 넘치는 순간 앞쪽 여백이 0 이 되고 넘친 몫이
  //     전부 오른쪽으로 간다(실측: 넘칠 때 첫 타일의 left == 행의 left).
  //
  // 수정이 옳은 이유는 "사용자 화면이 잘리고 있었다" 가 아니라, 폭 수요가 폰트와
  // 텍스트 배율에 좌우되던 걸 레이아웃으로 바꿔 여유를 확보했다는 것이다.
  // 프로덕션 폰트 기준 여유는 360dp 에서 49px, 440dp 에서 108px, 가장 좁은
  // 320dp 에서도 19.5px(배율 2.0 에서 5.2px)이다.
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
    // 배율을 탄다). 그래서 폭 수요 회귀를 가장 잘 무는 차원이기도 하다: 구분자
    // 여백을 다시 공백 문자로 되돌리면 여백까지 배율을 타서 수요가 배율 1.0
    // 253.9px -> 2.0 286.3px 로 커진다. 1.0 에서는 320dp / 360dp 만 공급을
    // 넘지만, 2.0 에서는 440dp(공급 311.0px)를 뺀 모든 기기가 넘는다.
    //
    // 상한을 2.0 으로 잡은 근거는 실측이다. 예전 주석은 "1.3 이 플랫폼 상한" 이라
    // 거기까지만 못박는다고 했지만, 진짜 이유는 하네스 폰트였다 — 그 폰트로는
    // 배율 1.8 / 360dp 에서 **수정 후** 남은시간 행이 1.4px(2.0 이면 8.6px)
    // 넘쳤고, 375~402dp 에서는 히어로 행이 따로 넘쳤다. 둘 다 프로덕션 폰트에서는
    // 재현되지 않는다. 실제 폰트로는 320~440dp 전 구간이 배율 2.0 까지 깨끗하다.
    for (final scale in <double>[1.3, 2.0]) {
      for (final entry in <String, Size>{
        'narrow Android (320x640)': const Size(320, 640),
        'small Android (360x640)': const Size(360, 640),
        'iPhone 16 (393x852)': const Size(393, 852),
      }.entries) {
        testWidgets('countdown fits on ${entry.key} at textScale $scale',
            (tester) async {
          await _pumpCardInPage(tester, entry.value, textScale: scale);

          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} @$scale: 카드 렌더 중 예외가 났다',
          );
          _expectCountdownFitsCard(tester, '${entry.key} @$scale');
        });
      }
    }
  });
}
