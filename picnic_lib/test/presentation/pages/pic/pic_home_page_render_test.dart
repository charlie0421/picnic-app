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

  Future<void> pumpAndDrain(WidgetTester tester, widget) async {
    await tester.pumpWidget(widget);
    drainExpectedImageErrors(tester);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

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
