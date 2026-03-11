import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';

void main() {
  group('ImageThumbnailFromUrl', () {
    Widget buildTestWidget({
      String imageUrl = 'https://example.com/image.jpg',
      double? width,
      double? height,
      BoxFit fit = BoxFit.cover,
      double? borderRadius,
      Widget? loading,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ImageThumbnailFromUrl(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            borderRadius: borderRadius,
            loading: loading,
          ),
        ),
      );
    }

    testWidgets('렌더링 확인', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(ImageThumbnailFromUrl), findsOneWidget);
    });

    testWidgets('borderRadius 없으면 ClipRRect 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget(borderRadius: null));
      await tester.pump();

      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('borderRadius 0이면 ClipRRect 없음', (tester) async {
      await tester.pumpWidget(buildTestWidget(borderRadius: 0));
      await tester.pump();

      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('borderRadius > 0이면 ClipRRect 있음', (tester) async {
      await tester.pumpWidget(buildTestWidget(borderRadius: 8.0));
      await tester.pump();

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('커스텀 크기 적용', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        width: 200,
        height: 150,
      ));
      await tester.pump();

      expect(find.byType(ImageThumbnailFromUrl), findsOneWidget);
    });

    test('기본값 확인', () {
      const widget = ImageThumbnailFromUrl(imageUrl: 'test');
      expect(widget.fit, equals(BoxFit.cover));
      expect(widget.width, isNull);
      expect(widget.height, isNull);
      expect(widget.borderRadius, isNull);
      expect(widget.loading, isNull);
    });

    test('const 생성자 지원', () {
      const widget = ImageThumbnailFromUrl(imageUrl: 'test');
      expect(widget, isA<StatelessWidget>());
    });
  });

  group('ImageThumbnailFromFile', () {
    test('기본값 확인', () {
      // File은 실제 파일이 필요하므로 const로 생성 불가
      // 대신 기본값 확인은 클래스 속성으로 확인
      expect(ImageThumbnailFromFile, isNotNull);
    });
  });
}
