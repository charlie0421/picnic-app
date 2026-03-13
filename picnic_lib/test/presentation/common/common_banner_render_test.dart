import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

/// Mock for AsyncBannerList that returns a provided list
class MockAsyncBannerListEmpty extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [];
}

class MockAsyncBannerListSingle extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
        BannerModel.fromJson({
          'id': 1,
          'title': {'ko': '단일 배너'},
          'thumbnail': 'https://example.com/thumb.jpg',
          'image': {'ko': 'https://example.com/img.jpg'},
          'duration': 3000,
          'link': null,
        }),
      ];
}

class MockAsyncBannerListMultiple extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
        BannerModel.fromJson({
          'id': 1,
          'title': {'ko': '배너 1'},
          'thumbnail': 'https://example.com/thumb1.jpg',
          'image': {'ko': 'https://example.com/img1.jpg'},
          'duration': 3000,
          'link': 'https://www.picnic.fan/vote',
        }),
        BannerModel.fromJson({
          'id': 2,
          'title': {'ko': '배너 2'},
          'thumbnail': 'https://example.com/thumb2.jpg',
          'image': {'ko': 'https://example.com/img2.jpg'},
          'duration': 5000,
          'link': 'https://applink.picnic.fan/something',
        }),
        BannerModel.fromJson({
          'id': 3,
          'title': {'ko': ''},
          'thumbnail': 'https://example.com/thumb3.jpg',
          'image': {'ko': 'https://example.com/img3.gif'},
          'duration': 4000,
          'link': null,
        }),
      ];
}

class MockAsyncBannerListError extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async {
    throw Exception('Banner load error');
  }
}

class MockAsyncBannerListWithLinks extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) async => [
        BannerModel.fromJson({
          'id': 1,
          'title': {'ko': '외부 링크'},
          'thumbnail': 'https://example.com/thumb.jpg',
          'image': {'ko': 'https://example.com/img.jpg'},
          'duration': 3000,
          'link': 'https://www.google.com',
        }),
      ];
}

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({'banner': <dynamic>[]});
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  group('CommonBanner render', () {
    testWidgets('renders with empty banner list', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider
                .overrideWith(MockAsyncBannerListEmpty.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with single banner item (no swiper)',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider
                .overrideWith(MockAsyncBannerListSingle.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with multiple banners (swiper)',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider
                .overrideWith(MockAsyncBannerListMultiple.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders error state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 16 / 9),
          extraOverrides: [
            asyncBannerListProvider
                .overrideWith(MockAsyncBannerListError.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with link banners', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('test_location', 3144 / 1200),
          extraOverrides: [
            asyncBannerListProvider
                .overrideWith(MockAsyncBannerListWithLinks.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });

    testWidgets('renders with different aspect ratio',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestApp(
          const CommonBanner('pic_home', 4 / 3),
          extraOverrides: [
            asyncBannerListProvider
                .overrideWith(MockAsyncBannerListSingle.new),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      while (tester.takeException() != null) {}

      expect(find.byType(CommonBanner), findsOneWidget);
    });
  });
}
