import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

void main() {
  group('PulseLoadingIndicator', () {
    test('기본값 확인', () {
      const widget = PulseLoadingIndicator();
      expect(widget.size, equals(40));
      expect(widget.duration, equals(const Duration(milliseconds: 800)));
      expect(widget.minScale, equals(0.98));
      expect(widget.maxScale, equals(1.02));
    });

    test('커스텀 값 설정', () {
      const widget = PulseLoadingIndicator(
        size: 80,
        duration: Duration(milliseconds: 1200),
        minScale: 0.9,
        maxScale: 1.1,
      );
      expect(widget.size, equals(80));
      expect(widget.duration, equals(const Duration(milliseconds: 1200)));
      expect(widget.minScale, equals(0.9));
      expect(widget.maxScale, equals(1.1));
    });

    test('StatefulWidget임', () {
      const widget = PulseLoadingIndicator();
      expect(widget, isA<StatefulWidget>());
    });

    test('const 생성자 지원', () {
      const widget = PulseLoadingIndicator();
      expect(widget, isNotNull);
    });
  });

  group('SmallPulseLoadingIndicator', () {
    test('const 생성자 지원', () {
      const widget = SmallPulseLoadingIndicator();
      expect(widget, isA<StatelessWidget>());
    });

    test('생성 확인', () {
      const widget = SmallPulseLoadingIndicator();
      expect(widget, isNotNull);
    });
  });

  group('MediumPulseLoadingIndicator', () {
    test('const 생성자 지원', () {
      const widget = MediumPulseLoadingIndicator();
      expect(widget, isA<StatelessWidget>());
    });

    test('생성 확인', () {
      const widget = MediumPulseLoadingIndicator();
      expect(widget, isNotNull);
    });
  });

  group('LargePulseLoadingIndicator', () {
    test('const 생성자 지원', () {
      const widget = LargePulseLoadingIndicator();
      expect(widget, isA<StatelessWidget>());
    });

    test('생성 확인', () {
      const widget = LargePulseLoadingIndicator();
      expect(widget, isNotNull);
    });
  });
}
