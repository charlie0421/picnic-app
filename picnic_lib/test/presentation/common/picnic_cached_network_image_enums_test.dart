import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';

void main() {
  group('ImageComplexity enum', () {
    test('3개의 값이 정의됨', () {
      expect(ImageComplexity.values.length, equals(3));
    });

    test('low, medium, high 값 존재', () {
      expect(ImageComplexity.low, isNotNull);
      expect(ImageComplexity.medium, isNotNull);
      expect(ImageComplexity.high, isNotNull);
    });

    test('index 순서 확인', () {
      expect(ImageComplexity.low.index, equals(0));
      expect(ImageComplexity.medium.index, equals(1));
      expect(ImageComplexity.high.index, equals(2));
    });
  });

  group('LazyLoadingStrategy enum', () {
    test('4개의 값이 정의됨', () {
      expect(LazyLoadingStrategy.values.length, equals(4));
    });

    test('none, viewport, preload, progressive 값 존재', () {
      expect(LazyLoadingStrategy.none, isNotNull);
      expect(LazyLoadingStrategy.viewport, isNotNull);
      expect(LazyLoadingStrategy.preload, isNotNull);
      expect(LazyLoadingStrategy.progressive, isNotNull);
    });

    test('index 순서 확인', () {
      expect(LazyLoadingStrategy.none.index, equals(0));
      expect(LazyLoadingStrategy.viewport.index, equals(1));
      expect(LazyLoadingStrategy.preload.index, equals(2));
      expect(LazyLoadingStrategy.progressive.index, equals(3));
    });
  });

  group('ImagePriority enum', () {
    test('3개의 값이 정의됨', () {
      expect(ImagePriority.values.length, equals(3));
    });

    test('low, normal, high 값 존재', () {
      expect(ImagePriority.low, isNotNull);
      expect(ImagePriority.normal, isNotNull);
      expect(ImagePriority.high, isNotNull);
    });

    test('index 순서 확인', () {
      expect(ImagePriority.low.index, equals(0));
      expect(ImagePriority.normal.index, equals(1));
      expect(ImagePriority.high.index, equals(2));
    });
  });

  group('PicnicCachedNetworkImage 생성자', () {
    test('기본값 확인', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'https://example.com/img.jpg');
      expect(widget.imageUrl, equals('https://example.com/img.jpg'));
      expect(widget.width, isNull);
      expect(widget.height, isNull);
      expect(widget.fit, equals(BoxFit.cover));
      expect(widget.memCacheWidth, isNull);
      expect(widget.memCacheHeight, isNull);
      expect(widget.borderRadius, isNull);
      expect(widget.timeout, isNull);
      expect(widget.maxRetries, isNull);
      expect(widget.lazyLoadingStrategy, equals(LazyLoadingStrategy.viewport));
      expect(widget.visibilityThreshold, equals(0.1));
      expect(widget.placeholder, isNull);
      expect(widget.showLoadingOverlay, isTrue);
      expect(widget.priority, equals(ImagePriority.normal));
      expect(widget.enableMemoryOptimization, isTrue);
      expect(widget.enableProgressiveLoading, isTrue);
    });

    test('커스텀 값 설정', () {
      const widget = PicnicCachedNetworkImage(
        imageUrl: 'https://example.com/img.webp',
        width: 200,
        height: 300,
        fit: BoxFit.contain,
        memCacheWidth: 100,
        memCacheHeight: 150,
        lazyLoadingStrategy: LazyLoadingStrategy.none,
        visibilityThreshold: 0.5,
        showLoadingOverlay: false,
        priority: ImagePriority.high,
        enableMemoryOptimization: false,
        enableProgressiveLoading: false,
      );
      expect(widget.width, equals(200));
      expect(widget.height, equals(300));
      expect(widget.fit, equals(BoxFit.contain));
      expect(widget.memCacheWidth, equals(100));
      expect(widget.memCacheHeight, equals(150));
      expect(widget.lazyLoadingStrategy, equals(LazyLoadingStrategy.none));
      expect(widget.visibilityThreshold, equals(0.5));
      expect(widget.showLoadingOverlay, isFalse);
      expect(widget.priority, equals(ImagePriority.high));
      expect(widget.enableMemoryOptimization, isFalse);
      expect(widget.enableProgressiveLoading, isFalse);
    });

    test('const 생성자 지원', () {
      const widget = PicnicCachedNetworkImage(imageUrl: 'test');
      expect(widget, isNotNull);
    });
  });
}
