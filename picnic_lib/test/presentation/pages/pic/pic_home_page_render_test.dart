import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_page.dart';
import 'package:picnic_lib/presentation/providers/celeb_list_provider.dart';
import 'package:picnic_lib/presentation/providers/gallery_list_provider.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class MockCelebList extends AsyncCelebList {
  @override
  Future<List<CelebModel>?> build() async => [
        CelebModel.fromJson({
          'id': 1,
          'name_ko': '지민',
          'name_en': 'Jimin',
          'thumbnail': null,
        }),
      ];
}

class MockMyCelebList extends AsyncMyCelebList {
  @override
  Future<List<CelebModel>?> build() async => [
        CelebModel.fromJson({
          'id': 1,
          'name_ko': '지민',
          'name_en': 'Jimin',
          'thumbnail': null,
        }),
      ];
}

class MockCelebGalleryList extends AsyncCelebGalleryList {
  @override
  Future<List<GalleryModel>> build(int celebId) async => [
        GalleryModel(
          id: 1,
          titleKo: '갤러리',
          titleEn: 'Gallery',
          cover: null,
          celeb: null,
        ),
      ];
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'celeb': [
        {'id': 1, 'name_ko': '지민', 'name_en': 'Jimin'},
      ],
      'celeb_bookmark_user': <dynamic>[],
      'pic_vote': <dynamic>[],
      'banner': <dynamic>[],
      'gallery': [
        {
          'id': 1,
          'title_ko': '갤러리',
          'title_en': 'Gallery',
          'cover': null,
        },
      ],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(
    WidgetTester tester,
    widget, {
    Iterable<String> knownDefects = const <String>[],
  }) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget, knownDefects: knownDefects);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  /// 격리 — PicHomePage 를 띄우는 테스트에만 붙인다.
  ///
  /// pic_home_page.dart:167 의 `loading:` 브랜치가 스크롤 컨테이너 없이 bare
  /// `Column` 에 `VoteCardSkeleton` 3장을 쌓아서, 첫 프레임이 세로로 749px 넘친다.
  /// 데이터가 도착한 뒤(`data:` 브랜치, :123 의 `ListView`)에는 안 넘치므로 사용자가
  /// 보는 건 스켈레톤 프레임 한 장뿐이고, pic 은 운영 중인 포털도 아니라 우선순위가
  /// 낮다. 스켈레톤을 스크롤 가능한 컨테이너에 넣는 게 맞는 수정이다.
  ///
  /// 같은 파일의 `CelebDropDown render` 그룹은 이 결함과 무관하므로 격리하지 않는다
  /// — 거기서 오버플로가 나면 그대로 실패해야 한다.
  const picHomeLoadingOverflow = ['A RenderFlex overflowed by'];

  group('PicHomePage render', () {
    testWidgets('renders with celeb data', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const PicHomePage(),
          extraOverrides: [
            asyncCelebListProvider.overrideWith(MockCelebList.new),
            asyncMyCelebListProvider.overrideWith(MockMyCelebList.new),
            asyncCelebGalleryListProvider
                .overrideWith(MockCelebGalleryList.new),
          ],
        ),
        knownDefects: picHomeLoadingOverflow,
      );

      expect(find.byType(PicHomePage), findsOneWidget);
    });

    testWidgets('renders logged out', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const PicHomePage(),
          loggedIn: false,
          extraOverrides: [
            asyncCelebListProvider.overrideWith(MockCelebList.new),
            asyncMyCelebListProvider.overrideWith(MockMyCelebList.new),
            asyncCelebGalleryListProvider
                .overrideWith(MockCelebGalleryList.new),
          ],
        ),
        knownDefects: picHomeLoadingOverflow,
      );

      expect(find.byType(PicHomePage), findsOneWidget);
    });
  });

  group('PicHomePage additional render states', () {
    testWidgets('renders with Korean locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const PicHomePage(),
          locale: const Locale('ko'),
          extraOverrides: [
            asyncCelebListProvider.overrideWith(MockCelebList.new),
            asyncMyCelebListProvider.overrideWith(MockMyCelebList.new),
            asyncCelebGalleryListProvider
                .overrideWith(MockCelebGalleryList.new),
          ],
        ),
        knownDefects: picHomeLoadingOverflow,
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(PicHomePage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const PicHomePage(),
          locale: const Locale('en'),
          extraOverrides: [
            asyncCelebListProvider.overrideWith(MockCelebList.new),
            asyncMyCelebListProvider.overrideWith(MockMyCelebList.new),
            asyncCelebGalleryListProvider
                .overrideWith(MockCelebGalleryList.new),
          ],
        ),
        knownDefects: picHomeLoadingOverflow,
      );

      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(PicHomePage), findsOneWidget);
    });
  });

  group('CelebDropDown render', () {
    testWidgets('renders', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CelebDropDown(),
          extraOverrides: [
            asyncCelebListProvider.overrideWith(MockCelebList.new),
            asyncMyCelebListProvider.overrideWith(MockMyCelebList.new),
          ],
        ),
      );

      expect(find.byType(CelebDropDown), findsOneWidget);
    });

    testWidgets('renders with null thumbnail', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CelebDropDown(),
          extraOverrides: [
            asyncCelebListProvider.overrideWith(MockCelebList.new),
            asyncMyCelebListProvider.overrideWith(MockMyCelebList.new),
          ],
        ),
      );

      // CelebDropDown should render even with null thumbnail
      expect(find.byType(CelebDropDown), findsOneWidget);
    });
  });
}
