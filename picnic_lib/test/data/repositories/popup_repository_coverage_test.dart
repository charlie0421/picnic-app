import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../helpers/mock_supabase.dart';

/// PopupRepository의 fetchPopups 로직을 재현하여 테스트합니다.
/// PopupRepository는 필드에서 Supabase.instance.client를 직접 초기화하므로
/// 인스턴스를 생성할 수 없습니다. 대신 동일한 쿼리 로직을 supabase getter로 테스트합니다.
void main() {
  group('PopupRepository fetchPopups 로직', () {
    setUp(() {
      setupMockSupabase({
        'popup': [
          {
            'id': 1,
            'title': {'ko': '테스트 팝업 1', 'en': 'Test Popup 1'},
            'content': {'ko': '내용 1', 'en': 'Content 1'},
            'start_at': '2025-01-01T00:00:00.000Z',
            'stop_at': '2026-12-31T23:59:59.000Z',
            'deleted_at': null,
            'created_at': '2025-01-01T00:00:00.000Z',
            'updated_at': '2025-01-01T00:00:00.000Z',
          },
          {
            'id': 2,
            'title': {'ko': '테스트 팝업 2'},
            'content': {'ko': '내용 2'},
            'start_at': '2025-06-01T00:00:00.000Z',
            'stop_at': '2026-12-31T23:59:59.000Z',
            'deleted_at': null,
            'created_at': '2025-06-01T00:00:00.000Z',
            'updated_at': '2025-06-01T00:00:00.000Z',
          },
        ],
      });
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('popup 테이블에서 데이터를 가져와 Popup 모델로 변환한다', () async {
      final response = await supabase
          .from('popup')
          .select()
          .lte('start_at', DateTime.now().toIso8601String())
          .gte('stop_at', DateTime.now().toIso8601String())
          .filter('deleted_at', 'is', null)
          .order('start_at', ascending: true);

      final popups = (response as List)
          .map((e) => Popup.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(popups, isNotEmpty);
      expect(popups.first.id, 1);
      expect(popups.first.title['ko'], '테스트 팝업 1');
    });

    test('빈 popup 테이블에서 빈 리스트를 반환한다', () async {
      tearDownMockSupabase();
      setupMockSupabase({'popup': []});

      final response = await supabase
          .from('popup')
          .select()
          .lte('start_at', DateTime.now().toIso8601String())
          .gte('stop_at', DateTime.now().toIso8601String())
          .filter('deleted_at', 'is', null)
          .order('start_at', ascending: true);

      final popups = (response as List)
          .map((e) => Popup.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(popups, isEmpty);
    });

    test('popup 데이터가 없는 경우 기본 빈 응답을 받는다', () async {
      tearDownMockSupabase();
      setupMockSupabase({}); // popup 키 없음

      final response = await supabase
          .from('popup')
          .select()
          .lte('start_at', DateTime.now().toIso8601String())
          .gte('stop_at', DateTime.now().toIso8601String())
          .filter('deleted_at', 'is', null)
          .order('start_at', ascending: true);

      final popups = (response as List)
          .map((e) => Popup.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(popups, isEmpty);
    });

    test('Popup 변환 시 에러 처리', () {
      // 잘못된 JSON으로 Popup 생성 시 에러 발생
      expect(
        () => Popup.fromJson({'invalid': 'data'}),
        throwsA(anything),
      );
    });
  });
}
