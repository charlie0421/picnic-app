import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/animation_service.dart';
import 'package:picnic_lib/presentation/widgets/animated_list_item.dart';

void main() {
  group('Task 4.1 - Animation Package Integration Tests', () {
    late AnimationService animationService;

    setUpAll(() {
      animationService = AnimationService();
      animationService.initialize();
    });

    tearDownAll(() {
      animationService.cleanup();
    });

    test('애니메이션 서비스 초기화 테스트', () {
      // Given: 애니메이션 서비스
      final service = AnimationService();

      // When: 초기화
      service.initialize();

      // Then: 통계가 정상적으로 수집됨
      final stats = service.stats;
      expect(stats, isNotNull);
      expect(stats.toJson(), isA<Map<String, dynamic>>());

      // 정리
      service.cleanup();
    });

    test('애니메이션 타입 열거형 테스트', () {
      // Given: 애니메이션 타입들
      final types = AnimationType.values;

      // Then: 모든 타입이 정의됨
      expect(types.contains(AnimationType.slideInFromRight), isTrue);
      expect(types.contains(AnimationType.slideInFromLeft), isTrue);
      expect(types.contains(AnimationType.fadeIn), isTrue);
      expect(types.contains(AnimationType.scaleIn), isTrue);
      expect(types.contains(AnimationType.none), isTrue);
    });

    testWidgets('AnimatedListItem 기본 렌더링 테스트', (tester) async {
      // Given: 애니메이션 리스트 아이템
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              animationType: AnimationType.fadeIn,
              child: const Text('Test Item'),
            ),
          ),
        ),
      );

      // When: 위젯 빌드
      await tester.pump();

      // Then: 위젯이 정상 렌더링됨
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.byType(AnimatedListItem), findsOneWidget);
    });

    testWidgets('애니메이션 비활성화 테스트', (tester) async {
      // Given: 비활성화된 애니메이션
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              animationType: AnimationType.none,
              child: const Text('Static Item'),
            ),
          ),
        ),
      );

      // When: 위젯 빌드
      await tester.pump();

      // Then: 정적 위젯으로 렌더링됨
      expect(find.text('Static Item'), findsOneWidget);
    });

    test('애니메이션 헬퍼 유틸리티 테스트', () {
      // Given: 다양한 입력값들
      const index = 5;
      const distance = 300.0;

      // When: 지연 시간 계산
      final delay = AnimationHelper.calculateDelay(index);
      final duration = AnimationHelper.calculateDuration(distance);

      // Then: 유효한 값들이 반환됨
      expect(delay, isA<Duration>());
      expect(duration, isA<Duration>());
      expect(delay.inMilliseconds, greaterThanOrEqualTo(0));
      expect(duration.inMilliseconds, greaterThan(0));
    });

    group('애니메이션 상수 테스트', () {
      test('애니메이션 지속시간 상수들', () {
        expect(AnimationService.defaultDuration,
            const Duration(milliseconds: 300));
        expect(
            AnimationService.fastDuration, const Duration(milliseconds: 150));
        expect(
            AnimationService.slowDuration, const Duration(milliseconds: 600));
        expect(AnimationService.veryFastDuration,
            const Duration(milliseconds: 100));
        expect(AnimationService.verySlowDuration,
            const Duration(milliseconds: 1000));
      });

      test('애니메이션 커브 상수들', () {
        expect(AnimationService.defaultCurve, Curves.easeInOut);
        expect(AnimationService.bounceCurve, Curves.bounceOut);
        expect(AnimationService.elasticCurve, Curves.elasticOut);
        expect(AnimationService.fastOutSlowIn, Curves.fastOutSlowIn);
      });
    });

    test('슬라이드 방향 열거형 테스트', () {
      final directions = SlideDirection.values;
      expect(directions.length, equals(4));
      expect(directions.contains(SlideDirection.rightToLeft), isTrue);
      expect(directions.contains(SlideDirection.leftToRight), isTrue);
      expect(directions.contains(SlideDirection.topToBottom), isTrue);
      expect(directions.contains(SlideDirection.bottomToTop), isTrue);
    });
  });
}

/// 테스트용 TickerProvider
class TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
