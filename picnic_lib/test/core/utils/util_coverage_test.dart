import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/util.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('checkSession', () {
    setUp(() {
      setupMockSupabase({});
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('현재 세션이 없으면 false를 반환한다', () async {
      // setupMockSupabase는 인증되지 않은 상태로 설정됨
      final result = await checkSession();
      expect(result, isFalse);
    });
  });

  group('numberFormatter 추가 테스트', () {
    test('소수점이 있는 수는 소수점 이하를 무시한다', () {
      expect(numberFormatter.format(1234.56), '1,235');
    });

    test('매우 큰 수를 포맷한다', () {
      expect(numberFormatter.format(999999999999), '999,999,999,999');
    });

    test('1을 포맷한다', () {
      expect(numberFormatter.format(1), '1');
    });
  });
}
