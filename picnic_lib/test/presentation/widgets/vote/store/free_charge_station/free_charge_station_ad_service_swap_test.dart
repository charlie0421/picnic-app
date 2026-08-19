import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart';

/// BLOCKER-3 재검증에서 지적된 직접 회귀 테스트 — `_FreeChargeStationState`
/// 는 private 이라 위젯 레벨에서 didChangeDependencies 재호출 타이밍을
/// 안정적으로 재현하기 어렵다. 대신 그 안에서 실제로 쓰는 순서 보장 seam
/// (`recreateAdService`)을 직접 검증한다 — free_charge_station.dart 의
/// didChangeDependencies() 는 이 함수를 통해서만 `_adService` 를 교체한다.
void main() {
  group('recreateAdService (BLOCKER-3 dispose-before-swap)', () {
    test('이전 서비스가 있으면 반드시 dispose 한 뒤에만 새 서비스를 만든다', () {
      final calls = <String>[];

      final result = recreateAdService<String>(
        previous: 'old-service',
        disposePrevious: (service) => calls.add('disposed:$service'),
        builder: () {
          calls.add('created');
          return 'new-service';
        },
      );

      // 회귀 지점: 순서가 뒤집히거나(생성 먼저) dispose 가 생략되면, 옛
      // AdService 안의 AdmobShowFlow 워치독 타이머·pendingAd 가 위젯
      // teardown 이후에도 살아남는다(BLOCKER-3).
      expect(calls, ['disposed:old-service', 'created']);
      expect(result, 'new-service');
    });

    test('이전 서비스가 없으면(첫 호출) dispose 를 호출하지 않고 새로 만든다', () {
      final calls = <String>[];

      final result = recreateAdService<String>(
        previous: null,
        disposePrevious: (service) => calls.add('disposed:$service'),
        builder: () {
          calls.add('created');
          return 'first-service';
        },
      );

      expect(calls, ['created']);
      expect(result, 'first-service');
    });
  });
}
