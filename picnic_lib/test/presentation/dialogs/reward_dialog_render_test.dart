import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
  });

  RewardModel makeReward({
    int id = 1,
    String titleKo = '포토카드',
    String? thumbnail = 'https://example.com/reward.jpg',
    List<String>? overviewImages,
    Map<String, dynamic>? location,
    Map<String, dynamic>? sizeGuide,
  }) {
    return RewardModel(
      id: id,
      title: {'ko': titleKo, 'en': 'Photocard'},
      thumbnail: thumbnail,
      overviewImages: overviewImages,
      location: location,
      sizeGuide: sizeGuide,
    );
  }

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('RewardDialog CDN variant', () {
    // 리워드 원본은 1000px 로 업로드된다. CDN 은 query 가 하나라도 붙으면
    // 리사이저를 거치고, 이미지별 첫 요청이 8~12초 걸린다(2026-09-19 실측 —
    // 고정 변형 w=1000&q=80 도 배포 5일 뒤까지 아무도 만들지 않아 콜드였다).
    // 원본은 0.1~0.3초라 다이얼로그 이미지는 변환 없는 원본을 요청해야 한다.
    List<String> collectRequestUrls(WidgetTester tester) {
      return tester
          .widgetList<PicnicCachedNetworkImage>(
            find.descendant(
              of: find.byType(RewardDialog),
              matching: find.byType(PicnicCachedNetworkImage),
            ),
          )
          .map((widget) => widget.imageRequest?.url ?? '<layout-dependent>')
          .toList();
    }

    RewardModel makeFullReward() => makeReward(
      thumbnail: '/reward/thumb.png',
      overviewImages: ['/reward/overview-1.png', '/reward/overview-2.png'],
      location: {
        'ko': {
          'map': ['/reward/map.png'],
          'address': ['서울시 강남구'],
          'images': ['/reward/location.png'],
          'desc': ['설명'],
        },
      },
      sizeGuide: {
        'ko': [
          {
            'image': ['/reward/size.png'],
            'desc': ['사이즈'],
          },
        ],
      },
    );

    testWidgets('every image requests the untransformed original', (
      tester,
    ) async {
      await pumpAndDrain(
        tester,
        buildTestApp(RewardDialog(data: makeFullReward())),
      );

      final urls = collectRequestUrls(tester);
      expect(urls, hasLength(6));
      for (final url in urls) {
        expect(url, endsWith('.png'), reason: url);
        expect(Uri.parse(url).hasQuery, isFalse, reason: url);
      }
    });

    testWidgets('decode stays bounded to the source size', (tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(RewardDialog(data: makeFullReward())),
      );

      final requests = tester
          .widgetList<PicnicCachedNetworkImage>(
            find.descendant(
              of: find.byType(RewardDialog),
              matching: find.byType(PicnicCachedNetworkImage),
            ),
          )
          .map((widget) => widget.imageRequest!);
      for (final request in requests) {
        expect(request.decodeWidth, 1000, reason: request.url);
      }
      expect(RewardDialogConstants.imageDecodeWidth, 1000);
    });

    testWidgets('variant key does not change with device pixel ratio', (
      tester,
    ) async {
      final reward = makeFullReward();
      await pumpAndDrain(
        tester,
        buildTestApp(
          RewardDialog(data: reward),
          mediaQueryData: const MediaQueryData(
            size: Size(393, 852),
            devicePixelRatio: 3,
          ),
        ),
      );
      final urlsAt3x = collectRequestUrls(tester);

      await pumpAndDrain(
        tester,
        buildTestApp(
          RewardDialog(data: reward),
          mediaQueryData: const MediaQueryData(
            size: Size(360, 780),
            devicePixelRatio: 2,
          ),
        ),
      );
      final urlsAt2x = collectRequestUrls(tester);

      expect(urlsAt3x, isNotEmpty);
      expect(urlsAt2x, urlsAt3x);
    });
  });

  group('RewardDialog render', () {
    testWidgets('renders basic RewardDialog', (WidgetTester tester) async {
      final reward = makeReward();

      await pumpAndDrain(tester, buildTestApp(RewardDialog(data: reward)));

      expect(find.byType(RewardDialog), findsOneWidget);
    });

    testWidgets('renders with overview images', (WidgetTester tester) async {
      final reward = makeReward(
        overviewImages: [
          'https://example.com/overview1.jpg',
          'https://example.com/overview2.jpg',
        ],
      );

      await pumpAndDrain(tester, buildTestApp(RewardDialog(data: reward)));

      expect(find.byType(RewardDialog), findsOneWidget);
    });

    testWidgets('renders with location data', (WidgetTester tester) async {
      final reward = makeReward(
        location: {
          'ko': {
            'map': ['https://example.com/map.jpg'],
            'address': ['서울시 강남구 테헤란로 123'],
            'images': ['https://example.com/location.jpg'],
            'desc': ['위치 설명'],
          },
        },
      );

      await pumpAndDrain(tester, buildTestApp(RewardDialog(data: reward)));

      expect(find.byType(RewardDialog), findsOneWidget);
    });

    testWidgets('renders with size guide data', (WidgetTester tester) async {
      final reward = makeReward(
        sizeGuide: {
          'ko': [
            {
              'image': ['https://example.com/size.jpg'],
              'desc': ['사이즈 가이드 설명', '추가 설명'],
            },
          ],
        },
      );

      await pumpAndDrain(tester, buildTestApp(RewardDialog(data: reward)));

      expect(find.byType(RewardDialog), findsOneWidget);
    });

    testWidgets('renders with all sections', (WidgetTester tester) async {
      final reward = makeReward(
        overviewImages: ['https://example.com/overview.jpg'],
        location: {
          'ko': {
            'address': ['주소'],
          },
        },
        sizeGuide: {
          'ko': [
            {
              'desc': ['설명'],
            },
          ],
        },
      );

      await pumpAndDrain(tester, buildTestApp(RewardDialog(data: reward)));

      expect(find.byType(RewardDialog), findsOneWidget);
    });

    testWidgets('renders with null thumbnail', (WidgetTester tester) async {
      final reward = makeReward(thumbnail: null);

      await pumpAndDrain(tester, buildTestApp(RewardDialog(data: reward)));

      expect(find.byType(RewardDialog), findsOneWidget);
    });

    testWidgets('reward with null title renders instead of crashing', (
      WidgetTester tester,
    ) async {
      // `RewardModel.title` 은 순수 nullable DB 컬럼이다 — 운영자가 제목을
      // 비워두면 실제로 널이 온다. `widget.data.title!` 로 되돌리면 다이얼로그
      // 전체가 RenderErrorBox 가 되어 여기서 널 단언이 터진다.
      const reward = RewardModel(id: 1, title: null, thumbnail: null);

      await pumpAndDrain(
        tester,
        buildTestApp(const RewardDialog(data: reward)),
      );

      expect(find.byType(RewardDialog), findsOneWidget);
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: '제목이 널이면 빈 문자열로 접히고 다이얼로그는 계속 그려져야 한다',
      );
    });
  });

  group('RewardSection render', () {
    testWidgets('renders overview section', (WidgetTester tester) async {
      final reward = makeReward(
        overviewImages: ['https://example.com/img.jpg'],
      );

      await pumpAndDrain(
        tester,
        buildTestApp(
          SingleChildScrollView(
            child: RewardSection(type: RewardType.overview, data: reward),
          ),
        ),
      );

      expect(find.byType(RewardSection), findsOneWidget);
    });

    testWidgets('renders location section', (WidgetTester tester) async {
      final reward = makeReward(
        location: {
          'ko': {
            'address': ['서울시 강남구'],
            'desc': ['교통편 안내'],
          },
        },
      );

      await pumpAndDrain(
        tester,
        buildTestApp(
          SingleChildScrollView(
            child: RewardSection(type: RewardType.location, data: reward),
          ),
        ),
      );

      expect(find.byType(RewardSection), findsOneWidget);
    });

    testWidgets('renders sizeGuide section', (WidgetTester tester) async {
      final reward = makeReward(
        sizeGuide: {
          'ko': [
            {
              'image': ['https://example.com/size.jpg'],
              'desc': ['S - 90', 'M - 95'],
            },
          ],
        },
      );

      await pumpAndDrain(
        tester,
        buildTestApp(
          SingleChildScrollView(
            child: RewardSection(type: RewardType.sizeGuide, data: reward),
          ),
        ),
      );

      expect(find.byType(RewardSection), findsOneWidget);
    });
  });

  group('RewardDialogConstants', () {
    test('imageRadius has expected value', () {
      expect(RewardDialogConstants.imageRadius, 24);
    });

    test('topSectionHeight has expected value', () {
      expect(RewardDialogConstants.topSectionHeight, 400);
    });

    test('closeButtonSize has expected value', () {
      expect(RewardDialogConstants.closeButtonSize, 48);
    });

    test('transitionDuration has expected value', () {
      expect(
        RewardDialogConstants.transitionDuration,
        const Duration(milliseconds: 300),
      );
    });
  });

  group('RewardType enum', () {
    test('has all expected values', () {
      expect(RewardType.values, hasLength(3));
      expect(RewardType.values, contains(RewardType.overview));
      expect(RewardType.values, contains(RewardType.location));
      expect(RewardType.values, contains(RewardType.sizeGuide));
    });
  });

  group('RewardSection.hasContent', () {
    testWidgets('overview returns true when images present', (
      WidgetTester tester,
    ) async {
      final reward = makeReward(
        overviewImages: ['https://example.com/img.jpg'],
      );
      final section = RewardSection(type: RewardType.overview, data: reward);

      late BuildContext capturedContext;
      await pumpAndDrain(
        tester,
        buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(section.hasContent(capturedContext), isTrue);
    });

    testWidgets('overview returns false when no images', (
      WidgetTester tester,
    ) async {
      final reward = makeReward(overviewImages: null);
      final section = RewardSection(type: RewardType.overview, data: reward);

      late BuildContext capturedContext;
      await pumpAndDrain(
        tester,
        buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(section.hasContent(capturedContext), isFalse);
    });

    testWidgets('location returns false when no location data', (
      WidgetTester tester,
    ) async {
      final reward = makeReward(location: null);
      final section = RewardSection(type: RewardType.location, data: reward);

      late BuildContext capturedContext;
      await pumpAndDrain(
        tester,
        buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(section.hasContent(capturedContext), isFalse);
    });
  });
}
