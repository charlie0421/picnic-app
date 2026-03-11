import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';

void main() {
  group('LoadingOverlayWithIcon 생성자', () {
    test('필수 파라미터만으로 생성', () {
      const widget = LoadingOverlayWithIcon(
        child: SizedBox(),
      );
      expect(widget, isA<StatefulWidget>());
      expect(widget.child, isA<SizedBox>());
    });

    test('기본 barrierColor는 Colors.black54', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.barrierColor, equals(Colors.black54));
    });

    test('기본 iconSize는 64.0', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.iconSize, equals(64.0));
    });

    test('기본 iconAssetPath는 null', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.iconAssetPath, isNull);
    });

    test('기본 enableRotation은 true', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.enableRotation, isTrue);
    });

    test('기본 enableScale은 true', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.enableScale, isTrue);
    });

    test('기본 enableFade는 true', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.enableFade, isTrue);
    });

    test('기본 barrierDismissible은 false', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.barrierDismissible, isFalse);
    });

    test('기본 showProgressIndicator는 true', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.showProgressIndicator, isTrue);
    });

    test('기본 enablePerformanceOptimization은 true', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.enablePerformanceOptimization, isTrue);
    });

    test('기본 showPerformanceDebugInfo는 false', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.showPerformanceDebugInfo, isFalse);
    });

    test('커스텀 설정', () {
      const widget = LoadingOverlayWithIcon(
        barrierColor: Colors.red,
        iconSize: 100,
        iconAssetPath: 'test.png',
        loadingMessage: '로딩 중...',
        barrierDismissible: true,
        enableRotation: false,
        enableScale: false,
        enableFade: false,
        minScale: 0.9,
        maxScale: 1.1,
        clockwise: false,
        showProgressIndicator: false,
        enablePerformanceOptimization: false,
        child: SizedBox(),
      );
      expect(widget.barrierColor, equals(Colors.red));
      expect(widget.iconSize, equals(100));
      expect(widget.iconAssetPath, equals('test.png'));
      expect(widget.loadingMessage, equals('로딩 중...'));
      expect(widget.barrierDismissible, isTrue);
      expect(widget.enableRotation, isFalse);
      expect(widget.enableScale, isFalse);
      expect(widget.enableFade, isFalse);
      expect(widget.minScale, equals(0.9));
      expect(widget.maxScale, equals(1.1));
      expect(widget.clockwise, isFalse);
      expect(widget.showProgressIndicator, isFalse);
      expect(widget.enablePerformanceOptimization, isFalse);
    });

    test('rotationDuration 기본값 2초', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.rotationDuration, equals(const Duration(seconds: 2)));
    });

    test('scaleDuration 기본값 1.5초', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.scaleDuration, equals(const Duration(milliseconds: 1500)));
    });

    test('fadeDuration 기본값 1초', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.fadeDuration, equals(const Duration(seconds: 1)));
    });

    test('semanticsLabel 기본값', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.semanticsLabel, equals('로딩 중입니다'));
    });

    test('minScale/maxScale 기본값', () {
      const widget = LoadingOverlayWithIcon(child: SizedBox());
      expect(widget.minScale, equals(0.8));
      expect(widget.maxScale, equals(1.2));
    });
  });
}
