import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item_skeleton.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VideoListItemSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VideoListItemSkeleton(),
          ),
        ),
      );

      expect(find.byType(VideoListItemSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('contains Shimmer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VideoListItemSkeleton(),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('contains Card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VideoListItemSkeleton(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('is a StatelessWidget with const constructor', (tester) async {
      const widget = VideoListItemSkeleton();
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('contains Row for channel info area', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const VideoListItemSkeleton(),
          ),
        ),
      );

      // Should have a Row for the channel avatar + name
      expect(find.byType(Row), findsOneWidget);
    });
  });
}
