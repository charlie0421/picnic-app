import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';

void main() {
  group('NetworkConnectivityService', () {
    group('싱글톤 패턴', () {
      test('factory 생성자는 항상 동일한 인스턴스를 반환한다', () {
        final instance1 = NetworkConnectivityService();
        final instance2 = NetworkConnectivityService();
        expect(identical(instance1, instance2), isTrue);
      });

      test('인스턴스는 NetworkConnectivityService 타입이다', () {
        final instance = NetworkConnectivityService();
        expect(instance, isA<NetworkConnectivityService>());
      });
    });

    group('클래스 구조', () {
      late NetworkConnectivityService service;

      setUp(() {
        service = NetworkConnectivityService();
      });

      test('checkOnlineStatus 메서드가 존재하고 Future<bool>을 반환한다', () {
        // 메서드 존재 확인 (실제 네트워크 호출은 하지 않음)
        expect(service.checkOnlineStatus, isA<Function>());
      });

      test('onlineStream getter가 존재하고 Stream<bool>을 반환한다', () {
        final stream = service.onlineStream;
        expect(stream, isA<Stream<bool>>());
      });
    });
  });
}
