import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/factories/artist_factory.dart';
import '../../../helpers/factories/vote_factory.dart';
import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/pixel_probe.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// 로딩 상태에 머무르는 override — 캐러셀의 loading 브랜치를 고정한다.
class PendingActiveFeaturedVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() =>
      Completer<List<FeaturedVoteEntry>>().future;
}

/// 테스트가 직접 loading -> data 를 넘길 수 있는 override.
///
/// 위젯 트리를 새로 pump 하면 Riverpod 이 override 를 갈아끼우지 않아 상태가
/// 그대로 남는다. 한 트리 안에서 completer 를 완료시켜야 실제 전환이 재현된다.
class ControllableActiveFeaturedVotes extends AsyncActiveFeaturedVotes {
  ControllableActiveFeaturedVotes(this.completer);

  final Completer<List<FeaturedVoteEntry>> completer;

  @override
  Future<List<FeaturedVoteEntry>> build() => completer.future;
}

/// 실기기 논리 해상도(포인트). iOS 최소 지원(15.4)에 들어오는 최소 기기부터
/// 현행 최대 기기까지 커버한다.
const _devices = <String, Size>{
  'iPhone SE 2/3 (375x667)': Size(375, 667),
  'iPhone 13 mini (375x812)': Size(375, 812),
  'iPhone 14 (390x844)': Size(390, 844),
  'iPhone 16 (393x852)': Size(393, 852),
  'iPhone 17 Pro (402x874)': Size(402, 874),
  'iPhone 17 Pro Max (440x956)': Size(440, 956),
  'small Android (360x640)': Size(360, 640),
};

/// 골든/픽셀 검사가 캐러셀 뷰포트만 정확히 잡도록 두는 캡처 경계.
///
/// 명시적으로 두지 않으면 `matchesGoldenFile` 이 위로 올라가며 처음 만나는
/// repaint boundary(여기서는 `ListView` 가 자식마다 붙이는 것)를 잡게 되어,
/// 호스트 위젯을 바꾸는 순간 캡처 범위가 조용히 달라진다.
const Key _captureBoundary = ValueKey('carousel_capture_boundary');

/// PageView 첫 페이지(= 실제 카드)가 쉬는 자리를, 캐러셀 좌상단 기준으로 계산한다.
///
/// `padEnds: true` 인 PageView 는 페이지 폭을 `뷰포트 폭 * viewportFraction` 으로
/// 잡고 가운데 정렬한다. 그 안에서 카드는 [HomeFeaturedVoteCarousel.pageMargin]
/// 만큼 더 들어간다. 로딩 플레이스홀더는 이 사각형을 그대로 차지해야 한다.
Rect _expectedCardRect(double viewportWidth) {
  const margin = HomeFeaturedVoteCarousel.pageMargin;
  final pageWidth = viewportWidth * HomeFeaturedVoteCarousel.viewportFraction;
  return Rect.fromLTWH(
    (viewportWidth - pageWidth) / 2 + margin.left,
    margin.top,
    pageWidth - margin.horizontal,
    HomeFeaturedVoteCarousel.viewportHeight - margin.vertical,
  );
}

/// 캐러셀 좌상단을 원점으로 한 [finder] 의 사각형.
Rect _rectInCarousel(WidgetTester tester, Finder finder) {
  final origin = tester.getRect(find.byType(HomeFeaturedVoteCarousel)).topLeft;
  return tester.getRect(finder).shift(-origin);
}

/// 한 행([FeaturedVoteSkeletonKeys.rowsTopToBottom] 의 원소)이 차지하는 사각형.
Rect _rowRect(WidgetTester tester, List<Key> row) => row
    .map((key) => tester.getRect(find.byKey(key)))
    .reduce((a, b) => a.expandToInclude(b));

Matcher _closeToRect(Rect expected) => isA<Rect>()
    .having((r) => r.left, 'left', closeTo(expected.left, 0.01))
    .having((r) => r.top, 'top', closeTo(expected.top, 0.01))
    .having((r) => r.width, 'width', closeTo(expected.width, 0.01))
    .having((r) => r.height, 'height', closeTo(expected.height, 0.01));

void _useDevice(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

List<FeaturedVoteEntry> _entries(int count) => List.generate(
      count,
      (i) => FeaturedVoteEntry(
        vote: VoteFactory.create(
          id: i + 1,
          title: {'ko': '진행중 투표 ${i + 1}', 'en': 'Active vote ${i + 1}'},
          voteItem: [
            VoteItemFactory.create(
              id: i + 1,
              voteTotal: 1000,
              artist: ArtistFactory.create(id: i + 1),
            ),
          ],
        ),
        totalVotes: 2000,
      ),
    );

/// 프로덕션과 동일한 조건으로 캐러셀을 띄운다.
///
/// 1. ScreenUtil 기준: 하네스 기본값([kLegacyTestDesignSize] = 375x812,
///    splitScreenMode 없음)은 실제 앱(393x892 + splitScreenMode)과 달라 `.w`/`.r`
///    환산이 어긋난다. 오버플로 회귀는 그 환산값에 직접 좌우되므로 프로덕션 값을
///    쓴다. 하네스 기본값으로 재면 iPhone 17 Pro 에서 프로덕션 131px 대신 153px
///    이 나온다 — 앱에 존재하지 않는 기하를 측정하는 셈이다.
/// 2. 폭 제약: 캐러셀은 `home_page.dart` 의 [ListView] 자식이라 가로로 **tight**
///    한 제약을 받는다. `buildTestApp` 의 Scaffold body 는 loose 라서 그대로 두면
///    프로덕션에 없는 제약에서 재게 된다.
Future<void> _pumpCarousel(
  WidgetTester tester, {
  required List<dynamic> overrides,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      ListView(
        children: const [
          RepaintBoundary(
            key: _captureBoundary,
            child: HomeFeaturedVoteCarousel(),
          ),
        ],
      ),
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
      extraOverrides: overrides,
    ),
  );
  // 시간을 진행시키지 않는다. Shimmer 는 initState 에서 `forward()` 를 걸므로
  // 여기서 프레임은 애니메이션 0 지점 — 그라디언트 창이 자식 왼쪽 바깥에 있어
  // 마스크가 자식 전체를 baseColor 하나로 칠한다. 덕분에 픽셀 단언과 골든이
  // 애니메이션 위상에 흔들리지 않는다.
  await tester.pump();
}

Future<void> _pumpLoading(WidgetTester tester) => _pumpCarousel(
      tester,
      overrides: [
        asyncActiveFeaturedVotesProvider.overrideWith(
          PendingActiveFeaturedVotes.new,
        ),
      ],
    );

/// 이 PR 범위 밖의 알려진 선행 결함.
///
/// [HomeFeaturedVoteCard] 의 제목/타이머 Row 가 캐러셀 페이지 폭에서 가로로
/// 넘친다(`home_featured_vote_card.dart` 의 [CountdownTimer] 행, 기기별 19~78px).
/// 카드 자체를 단독으로 페이지 폭에 놓아도 재현되는 별개 버그라 여기서 고치지
/// 않는다. 다만 "예외를 전부 비운다" 로 넘기면 이 테스트가 어떤 렌더 오류에도
/// 실패하지 못하게 되므로, **이 하나만** 통과시킨다.
final Matcher _isKnownCardRowOverflow = isA<FlutterError>().having(
  (e) => e.toString(),
  'toString()',
  allOf(
    contains('A RenderFlex overflowed by'),
    contains('on the right'),
  ),
);

/// [completer] 를 완료시켜 실제 카드가 그려질 때까지 프레임을 돌린다.
Future<void> _completeWithData(
  WidgetTester tester,
  Completer<List<FeaturedVoteEntry>> completer, {
  int count = 1,
}) async {
  completer.complete(_entries(count));
  await tester.pump();
  await tester.pump();
  for (Object? error = tester.takeException();
      error != null;
      error = tester.takeException()) {
    expect(
      error,
      _isKnownCardRowOverflow,
      reason: '허용된 선행 오버플로 외의 예외가 났다 — 플레이스홀더/카드 렌더가 깨졌다',
    );
  }
}

/// [_captureBoundary] 서브트리의 실제 픽셀. 프로브 구현은
/// `test/helpers/pixel_probe.dart` 에 있다 (스켈레톤 회귀 테스트 공용).
Future<PixelProbe> _captureCarousel(WidgetTester tester) =>
    capturePixels(tester, find.byKey(_captureBoundary));

void main() {
  late void Function() restoreImages;

  setUp(() {
    initTestColors();
    restoreImages = suppressImageErrors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({});
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });

  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    tearDownMockSupabase();
    restoreImages();
  });

  group('HomeFeaturedVoteCarousel loading placeholder', () {
    // 회귀 방지: 캐러셀은 로딩 플레이스홀더에 고정 높이 뷰포트를 tight 하게
    // 물려준다. 자연 높이가 그보다 큰 스켈레톤을 넣으면 "A RenderFlex overflowed
    // by N pixels on the bottom" 이 나면서 하단이 잘린다(실제로 iPhone 17 Pro 에서
    // 131px). 어떤 지원 기기에서도 플레이스홀더가 뷰포트 안에 들어가야 한다.
    //
    // 캐러셀 자체의 높이만 재면 안 된다 — loading 브랜치가 SizedBox(372) 라서
    // 자식이 무엇이든 372 가 나오고, 플레이스홀더를 통째로 지우거나 스크롤뷰로
    // 감싸도 초록이 뜬다. 그래서 플레이스홀더 프레임의 사각형을 직접 잰다.
    for (final entry in _devices.entries) {
      testWidgets('fills the first page slot on ${entry.key}', (tester) async {
        _useDevice(tester, entry.value);
        await _pumpLoading(tester);

        final carousel = find.byType(HomeFeaturedVoteCarousel);
        expect(carousel, findsOneWidget);
        expect(
          tester.getSize(carousel).height,
          HomeFeaturedVoteCarousel.viewportHeight,
        );

        final frame = find.byKey(FeaturedVoteSkeletonKeys.frame);
        expect(
          frame,
          findsOneWidget,
          reason: '로딩 브랜치는 전용 플레이스홀더를 렌더해야 한다',
        );
        expect(
          _rectInCarousel(tester, frame),
          _closeToRect(_expectedCardRect(tester.getSize(carousel).width)),
          reason: '플레이스홀더는 실제 카드가 차지할 사각형을 그대로 채워야 한다 '
              '— 축소하거나 스크롤뷰로 감싸 오버플로를 피하는 것도 회귀다',
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'loading placeholder overflowed the carousel viewport on '
              '${entry.key}',
        );
      });
    }

    testWidgets('has no text, so text scale is not a risk dimension', (
      tester,
    ) async {
      // 이전 버전은 이 매트릭스를 textScale [1.0, 1.3] 로 두 배 돌렸지만
      // 플레이스홀더에는 글자가 하나도 없어 7개 케이스가 바이트 단위로 같은
      // 중복이었다. 매트릭스를 부풀리는 대신 "글자가 없다 + 배율에 불변" 을 한 번만
      // 못박는다. 나중에 플레이스홀더에 텍스트가 생기면 이 테스트가 깨지면서
      // 배율 차원을 다시 매트릭스에 넣어야 한다는 신호가 된다.
      final frame = find.byKey(FeaturedVoteSkeletonKeys.frame);

      _useDevice(tester, const Size(402, 874));
      await _pumpLoading(tester);
      expect(
        find.descendant(of: frame, matching: find.byType(Text)),
        findsNothing,
      );
      final atDefaultScale = _rectInCarousel(tester, frame);

      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      await tester.pump();
      expect(_rectInCarousel(tester, frame), atDefaultScale);
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeFeaturedVoteCarousel loading -> loaded transition', () {
    // 오버플로가 사라져도 플레이스홀더가 카드와 다른 자리를 차지하면 데이터가
    // 도착하는 순간 카드가 눈에 띄게 튄다. 수정 전 iPhone 17 Pro(402x874) 실측:
    // 플레이스홀더 369.2x372 @x=16.4 -> 카드 317.6x364 @x=42.2, 즉 오른쪽으로
    // 25.8px 이동 + 폭 51.6px(16%) 축소 + 높이 8px 축소 + 글로우 없음 -> 있음.
    for (final entry in <String, Size>{
      'iPhone 17 Pro (402x874)': const Size(402, 874),
      'small Android (360x640)': const Size(360, 640),
    }.entries) {
      testWidgets('placeholder hands over to the card in place on ${entry.key}',
          (tester) async {
        _useDevice(tester, entry.value);
        final completer = Completer<List<FeaturedVoteEntry>>();
        await _pumpCarousel(
          tester,
          overrides: [
            asyncActiveFeaturedVotesProvider.overrideWith(
              () => ControllableActiveFeaturedVotes(completer),
            ),
          ],
        );

        final placeholderRect = _rectInCarousel(
          tester,
          find.byKey(FeaturedVoteSkeletonKeys.frame),
        );
        final loadingHeight =
            tester.getSize(find.byType(HomeFeaturedVoteCarousel)).height;

        await _completeWithData(tester, completer);

        final card = find.byType(HomeFeaturedVoteCard);
        expect(card, findsOneWidget);
        expect(
          placeholderRect,
          _closeToRect(_rectInCarousel(tester, card)),
          reason: '데이터 도착 시 카드가 튀지 않으려면 두 사각형이 같아야 한다',
        );
        // 페이지가 하나면 _Dots 가 없으므로 캐러셀 전체 높이도 그대로여야 한다.
        // (페이지가 둘 이상이면 인디케이터가 아래로 18px 붙는다. 로딩 중에는
        // 페이지 수를 알 수 없어 그 자리를 미리 잡아둘 수 없다 — 잡아두면
        // 한 장짜리 캐러셀이 정반대 방향으로 튄다.)
        expect(
          tester.getSize(find.byType(HomeFeaturedVoteCarousel)).height,
          loadingHeight,
        );
      });
    }

    testWidgets('placeholder wears the same frame as the card', (tester) async {
      _useDevice(tester, const Size(402, 874));
      final completer = Completer<List<FeaturedVoteEntry>>();
      await _pumpCarousel(
        tester,
        overrides: [
          asyncActiveFeaturedVotesProvider.overrideWith(
            () => ControllableActiveFeaturedVotes(completer),
          ),
        ],
      );

      final placeholder = tester
          .widget<Container>(find.byKey(FeaturedVoteSkeletonKeys.frame))
          .decoration! as BoxDecoration;

      await _completeWithData(tester, completer);

      // 카드 프레임은 전용 키로 집는다. `find.descendant(..., Container).first` 는
      // 카드 위에 Container 가 하나만 끼어들어도 조용히 다른 위젯을 비교한다.
      final cardFrame = find.byKey(HomeFeaturedVoteCard.frameKey);
      expect(cardFrame, findsOneWidget);
      final card =
          tester.widget<Container>(cardFrame).decoration! as BoxDecoration;

      // 테두리/라운드/글로우가 같아야 로딩 -> 로드 전환에서 윤곽이 바뀌지 않는다.
      expect(placeholder.borderRadius, card.borderRadius);
      expect(placeholder.border, card.border);
      expect(placeholder.boxShadow, card.boxShadow);
      expect(
        placeholder.boxShadow,
        isNotEmpty,
        reason: '카드에는 primary500 글로우가 있다 — 플레이스홀더도 있어야 한다',
      );
    });
  });

  group('HomeFeaturedVoteCarousel placeholder structure', () {
    // Shimmer 는 자식을 BlendMode.srcIn ShaderMask 로 덮으므로, Shimmer 안에
    // 불투명 배경이 있으면 그 위의 모든 블록이 같은 그라디언트로 뭉개져 아무
    // 구조도 없는 회색 사각형 하나가 렌더된다. 카드 프레임은 Shimmer 바깥,
    // 블록들은 Shimmer 안 — 이 관계가 뒤집히면 골격이 통째로 안 보인다.
    testWidgets('frame sits outside the shimmer', (tester) async {
      _useDevice(tester, const Size(402, 874));
      await _pumpLoading(tester);

      final shimmer = find.byType(Shimmer);
      final frame = find.byKey(FeaturedVoteSkeletonKeys.frame);
      expect(shimmer, findsOneWidget);
      expect(find.ancestor(of: shimmer, matching: frame), findsOneWidget);
      expect(
        find.descendant(of: shimmer, matching: frame),
        findsNothing,
        reason: '카드 프레임은 Shimmer 밖에 있어야 한다',
      );
    });

    testWidgets('mirrors the card blocks with visible gaps between them', (
      tester,
    ) async {
      _useDevice(tester, const Size(402, 874));
      await _pumpLoading(tester);

      final shimmer = find.byType(Shimmer);
      final frameRect = tester.getRect(
        find.byKey(FeaturedVoteSkeletonKeys.frame),
      );

      var previousBottom = frameRect.top;
      for (final row in FeaturedVoteSkeletonKeys.rowsTopToBottom) {
        Rect? previousInRow;
        for (final key in row) {
          final block = find.byKey(key);
          expect(block, findsOneWidget, reason: '$key 블록이 없다');
          expect(
            find.descendant(of: shimmer, matching: block),
            findsOneWidget,
            reason: '$key 는 Shimmer 안에서 반짝여야 한다',
          );

          final rect = tester.getRect(block);
          expect(
            rect.top,
            greaterThanOrEqualTo(previousBottom - 0.01),
            reason: '$key 가 위 행과 겹친다 — 순서가 어긋났다',
          );
          if (previousInRow != null) {
            expect(
              rect.left,
              greaterThanOrEqualTo(previousInRow.right - 0.01),
              reason: '$key 가 같은 행의 왼쪽 블록과 겹친다',
            );
          }
          expect(
            frameRect.inflate(0.01).contains(rect.topLeft),
            isTrue,
            reason: '$key 가 카드 프레임 밖으로 나갔다',
          );
          expect(
            frameRect.inflate(0.01).contains(rect.bottomRight),
            isTrue,
            reason: '$key 가 카드 프레임 밖으로 나갔다',
          );
          previousInRow = rect;
        }
        previousBottom = _rowRect(tester, row).bottom;
      }
    });

    // 아래 두 테스트가 이 스위트의 핵심이다. 위젯 종류로 "불투명 배경 금지" 를
    // 잡으려던 이전 판은 `Material(color: ...)` 로도, 1px 안쪽으로 들여놓은
    // ColoredBox 로도, 블록을 2x2 로 줄여도 전부 초록이 떴다. 금지 목록을 늘리는
    // 대신 실제로 칠해진 픽셀을 본다.
    for (final entry in <String, Size>{
      'small Android (360x640)': const Size(360, 640),
      'iPhone 17 Pro Max (440x956)': const Size(440, 956),
    }.entries) {
      testWidgets('paints grey blocks on a white card on ${entry.key}', (
        tester,
      ) async {
        _useDevice(tester, entry.value);
        await _pumpLoading(tester);

        final capture = await _captureCarousel(tester);
        final frameRect = tester.getRect(
          find.byKey(FeaturedVoteSkeletonKeys.frame),
        );
        final rows = FeaturedVoteSkeletonKeys.rowsTopToBottom;

        // 1. 블록은 실제로 회색으로 칠해져야 한다.
        //    바 자체는 흰색이고, Shimmer 의 srcIn 마스크가 색을 baseColor 로
        //    갈아끼운 결과만 흰 카드 배경과 구분된다. 블록이 사라지거나(2x2 로
        //    줄이면 중앙 픽셀만 남고 아래 3번이 잡는다) 마스크가 걷히면 흰색이 온다.
        for (final row in rows) {
          for (final key in row) {
            final rect = tester.getRect(find.byKey(key));
            expect(
              capture.at(rect.center),
              colorHex(AppColors.grey300),
              reason: '$key 중앙이 셔머 베이스 색으로 칠해져 있어야 한다 '
                  '— 흰색이면 카드 배경과 구분되지 않아 사용자에겐 없는 것과 같다',
            );
          }
        }

        // 2. 행 사이 여백에는 카드 흰 배경이 그대로 보여야 한다.
        //    Shimmer 안에 불투명한 무언가가 있으면 — 위젯 종류가 무엇이든,
        //    1px 안쪽으로 들여놨든 — srcIn 이 여백까지 회색으로 칠해 여기서 깨진다.
        for (var i = 1; i < rows.length; i++) {
          final above = _rowRect(tester, rows[i - 1]);
          final below = _rowRect(tester, rows[i]);
          expect(
            below.top - above.bottom,
            greaterThan(1),
            reason: '${rows[i]} 와 ${rows[i - 1]} 사이에 여백이 없다',
          );
          final gap = Offset(
            frameRect.center.dx,
            (above.bottom + below.top) / 2,
          );
          expect(
            capture.at(gap),
            colorHex(AppColors.grey00),
            reason: '${rows[i - 1]} 와 ${rows[i]} 사이에서 카드 배경이 보여야 한다 '
                '— 회색이면 Shimmer 안의 불투명 배경이 골격을 통째로 삼킨 것이다',
          );
        }
        // 좌우 여백도 마찬가지.
        for (final dx in [frameRect.left + 4, frameRect.right - 4]) {
          expect(
            capture.at(Offset(dx, frameRect.center.dy)),
            colorHex(AppColors.grey00),
            reason: '카드 좌우 여백에서 배경이 보여야 한다',
          );
        }

        // 3. 골격이 카드를 실제로 채워야 한다.
        //    블록을 점처럼 줄여 놓고 "높이 > 0" 만 만족시키는 회귀를 여기서 잡는다.
        //    현재 실측 약 0.71 (블록 면적 합 / 프레임 면적).
        final painted = capture.fractionNot(
          AppColors.grey00,
          frameRect.deflate(4),
        );
        expect(
          painted,
          inInclusiveRange(0.5, 0.9),
          reason: '카드 면적의 절반 이상이 골격으로 덮여야 실제 카드처럼 읽힌다 '
              '(너무 꽉 차면 여백이 사라져 단색 덩어리가 된다). 실측 $painted',
        );
      });
    }

    // 위 단언들은 "내가 물어본 것" 만 지킨다. 비율을 조금씩 망가뜨리거나 순서를
    // 바꾸는 변경은 여전히 통과할 수 있고, 실패해도 사람이 그림을 볼 수 없다.
    // 골든은 그 둘을 동시에 메운다 — 어떤 픽셀이든 달라지면 빨간불이고, 실패
    // 아티팩트로 기대/실제/차이 PNG 가 나와 리뷰어가 눈으로 비교할 수 있다.
    //
    // 플레이스홀더는 텍스트도 이미지도 없고(위 "has no text" 테스트가 못박는다)
    // 셔머 위상도 0 으로 고정돼 있어, 골든이 깨지기 쉬운 흔한 원인(폰트 힌팅,
    // 애셋 디코딩, 애니메이션 타이밍)이 전부 해당하지 않는다.
    //
    // 의도적으로 모양을 바꿨다면:
    //   flutter test --update-goldens \
    //     test/presentation/widgets/vote/home_featured_vote_carousel_test.dart
    // 로 갱신하고, PR 에서 PNG diff 를 확인할 것.
    testWidgets('looks like the card it stands in for (golden)', (tester) async {
      _useDevice(tester, const Size(402, 874));
      await _pumpLoading(tester);

      await expectLater(
        find.byKey(_captureBoundary),
        matchesGoldenFile('../../../goldens/home_featured_vote_placeholder.png'),
      );
    });
  });
}
