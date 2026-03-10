import 'package:picnic_lib/core/utils/network.dart';
import 'package:test/test.dart';

/// 참고: 이 테스트들은 실제 네트워크 호출을 수행합니다.
/// 네트워크 연결이 필요하며, 오프라인 환경에서는 일부 테스트가 실패할 수 있습니다.
void main() {
  group('NetworkCheck', () {
    test('isOnline은 Future<bool>을 반환한다', () {
      final result = NetworkCheck.isOnline();
      expect(result, isA<Future<bool>>());
    });

    test('isOnline은 bool 값으로 완료된다', () async {
      final result = await NetworkCheck.isOnline();
      expect(result, isA<bool>());
    });

    test('isOnline은 예외를 던지지 않는다 (에러 시에도 false를 반환)', () async {
      // SocketException이 발생해도 false를 반환하므로 예외가 전파되지 않아야 한다
      expect(() async => await NetworkCheck.isOnline(), returnsNormally);
    });

    test('네트워크 연결이 있으면 true를 반환한다 (네트워크 연결 필요)', () async {
      // 이 테스트는 네트워크가 연결된 환경에서만 통과합니다.
      final result = await NetworkCheck.isOnline();
      expect(result, isTrue);
    }, tags: ['network']);
  });
}
