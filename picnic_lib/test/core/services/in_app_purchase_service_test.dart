import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';

void main() {
  late InAppPurchaseService service;

  setUp(() {
    service = InAppPurchaseService();
    // 테스트 시작 시 디버그 모드 초기화
    service.debugMode = false;
    service.debugTimeoutMode = 'normal';
    service.simulateSlowPurchase = false;
    service.forceTimeoutSimulation = false;
  });

  group('InAppPurchaseService singleton', () {
    test('동일한 인스턴스 반환', () {
      final s1 = InAppPurchaseService();
      final s2 = InAppPurchaseService();
      expect(identical(s1, s2), isTrue);
    });
  });

  group('초기 상태', () {
    test('products는 빈 리스트', () {
      expect(service.products, isEmpty);
    });

    test('isAvailable는 false', () {
      expect(service.isAvailable, isFalse);
    });

    test('lastPurchaseWasCancelled는 false', () {
      expect(service.lastPurchaseWasCancelled, isFalse);
    });
  });

  group('setDebugMode', () {
    test('활성화 시 debugMode true, debugTimeoutMode debug', () {
      service.setDebugMode(true);
      expect(service.debugMode, isTrue);
      expect(service.debugTimeoutMode, equals('debug'));
    });

    test('비활성화 시 debugMode false, debugTimeoutMode normal', () {
      service.setDebugMode(true);
      service.setDebugMode(false);
      expect(service.debugMode, isFalse);
      expect(service.debugTimeoutMode, equals('normal'));
    });
  });

  group('setTimeoutMode', () {
    test('debug 모드 설정', () {
      service.setTimeoutMode('debug');
      expect(service.debugTimeoutMode, equals('debug'));
      expect(service.debugMode, isTrue);
    });

    test('ultrafast 모드 설정', () {
      service.setTimeoutMode('ultrafast');
      expect(service.debugTimeoutMode, equals('ultrafast'));
      expect(service.debugMode, isTrue);
    });

    test('instant 모드 설정', () {
      service.setTimeoutMode('instant');
      expect(service.debugTimeoutMode, equals('instant'));
      expect(service.debugMode, isTrue);
    });

    test('normal 모드로 돌아가면 debugMode false', () {
      service.setTimeoutMode('debug');
      service.setTimeoutMode('normal');
      expect(service.debugTimeoutMode, equals('normal'));
      expect(service.debugMode, isFalse);
    });
  });

  group('setSlowPurchaseSimulation', () {
    test('활성화', () {
      service.setSlowPurchaseSimulation(true);
      expect(service.simulateSlowPurchase, isTrue);
    });

    test('비활성화', () {
      service.setSlowPurchaseSimulation(true);
      service.setSlowPurchaseSimulation(false);
      expect(service.simulateSlowPurchase, isFalse);
    });

    test('커스텀 딜레이 설정', () {
      service.setSlowPurchaseSimulation(
        true,
        delay: const Duration(seconds: 3),
      );
      expect(service.simulateSlowPurchase, isTrue);
    });
  });

  group('setForceTimeoutSimulation', () {
    test('활성화', () {
      service.setForceTimeoutSimulation(true);
      expect(service.forceTimeoutSimulation, isTrue);
    });

    test('비활성화', () {
      service.setForceTimeoutSimulation(true);
      service.setForceTimeoutSimulation(false);
      expect(service.forceTimeoutSimulation, isFalse);
    });
  });

  group('onPurchaseTimeout 콜백', () {
    test('초기값은 null', () {
      expect(service.onPurchaseTimeout, isNull);
    });

    test('콜백 설정 가능', () {
      service.onPurchaseTimeout = (productId) {};
      expect(service.onPurchaseTimeout, isNotNull);
    });

    test('콜백 해제 가능', () {
      service.onPurchaseTimeout = (productId) {};
      service.onPurchaseTimeout = null;
      expect(service.onPurchaseTimeout, isNull);
    });
  });
}
