import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_loading_page.dart';

void main() {
  group('calculateLoadingProgress', () {
    test('returns 1.0 when loading has not started', () {
      final result = calculateLoadingProgress(
        isLoadingStarted: false,
        seconds: 30,
        totalSeconds: 30,
      );
      expect(result, 1.0);
    });

    test('returns 1.0 when loading started and seconds equals total', () {
      final result = calculateLoadingProgress(
        isLoadingStarted: true,
        seconds: 30,
        totalSeconds: 30,
      );
      expect(result, 1.0);
    });

    test('returns 0.5 when half time elapsed', () {
      final result = calculateLoadingProgress(
        isLoadingStarted: true,
        seconds: 15,
        totalSeconds: 30,
      );
      expect(result, 0.5);
    });

    test('returns 0.0 when time is up', () {
      final result = calculateLoadingProgress(
        isLoadingStarted: true,
        seconds: 0,
        totalSeconds: 30,
      );
      expect(result, 0.0);
    });

    test('returns correct fraction for arbitrary values', () {
      final result = calculateLoadingProgress(
        isLoadingStarted: true,
        seconds: 10,
        totalSeconds: 30,
      );
      expect(result, closeTo(0.333, 0.001));
    });

    test('returns 1.0 when not started regardless of seconds value', () {
      final result = calculateLoadingProgress(
        isLoadingStarted: false,
        seconds: 0,
        totalSeconds: 30,
      );
      expect(result, 1.0);
    });
  });
}
