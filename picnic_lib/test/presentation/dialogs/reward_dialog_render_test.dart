import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/reward.dart';
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
    await tester.pumpWidget(widget);
    drainExpectedImageErrors(tester);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

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
    testWidgets('overview returns true when images present',
        (WidgetTester tester) async {
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

    testWidgets('overview returns false when no images',
        (WidgetTester tester) async {
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

    testWidgets('location returns false when no location data',
        (WidgetTester tester) async {
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
