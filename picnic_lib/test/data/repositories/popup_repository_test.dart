import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/popup.dart';

// NOTE: PopupRepository는 Supabase.instance.client를 필드에서 직접 초기화하므로
// 단위 테스트에서 인스턴스 생성이 불가능하다. Popup 모델 테스트에 집중한다.

void main() {
  group('PopupRepository', () {
    // NOTE: PopupRepository는 constructor injection을 지원하지 않고
    // 필드 초기화 시 Supabase.instance.client에 접근하므로
    // Supabase 초기화 없이는 인스턴스 생성이 불가능하다.
    // 따라서 Popup 모델 직렬화/역직렬화 및 리스트 변환 로직을 중심으로 테스트한다.

    group('Popup 모델 fromJson', () {
      test('필수 필드만 있는 JSON에서 Popup을 생성할 수 있다', () {
        final json = {
          'id': 1,
          'title': {'ko': '테스트 팝업', 'en': 'Test Popup'},
          'content': {'ko': '내용', 'en': 'Content'},
        };

        final popup = Popup.fromJson(json);
        expect(popup.id, 1);
        expect(popup.title['ko'], '테스트 팝업');
        expect(popup.content['en'], 'Content');
        expect(popup.image, isNull);
        expect(popup.deletedAt, isNull);
      });

      test('모든 필드가 있는 JSON에서 Popup을 생성할 수 있다', () {
        final json = {
          'id': 2,
          'title': {'ko': '전체 팝업'},
          'content': {'ko': '전체 내용'},
          'image': {'ko': 'https://example.com/image.png'},
          'created_at': '2025-01-01T00:00:00.000Z',
          'updated_at': '2025-01-02T00:00:00.000Z',
          'deleted_at': null,
          'start_at': '2025-01-01T00:00:00.000Z',
          'stop_at': '2025-12-31T23:59:59.000Z',
        };

        final popup = Popup.fromJson(json);
        expect(popup.id, 2);
        expect(popup.image?['ko'], 'https://example.com/image.png');
        expect(popup.startAt, isNotNull);
        expect(popup.stopAt, isNotNull);
        expect(popup.deletedAt, isNull);
      });

      test('Popup을 JSON으로 직렬화하고 다시 역직렬화할 수 있다', () {
        final original = Popup(
          id: 3,
          title: {'ko': '직렬화 테스트'},
          content: {'ko': '직렬화 내용'},
          startAt: DateTime(2025, 1, 1),
          stopAt: DateTime(2025, 12, 31),
        );

        final json = original.toJson();
        final restored = Popup.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.content, original.content);
        expect(restored.startAt, original.startAt);
        expect(restored.stopAt, original.stopAt);
      });
    });

    group('Popup 모델 동등성', () {
      test('같은 데이터를 가진 Popup 인스턴스는 동일하다', () {
        final popup1 = Popup(
          id: 1,
          title: {'ko': '테스트'},
          content: {'ko': '내용'},
        );
        final popup2 = Popup(
          id: 1,
          title: {'ko': '테스트'},
          content: {'ko': '내용'},
        );

        expect(popup1, equals(popup2));
      });

      test('다른 데이터를 가진 Popup 인스턴스는 동일하지 않다', () {
        final popup1 = Popup(
          id: 1,
          title: {'ko': '테스트1'},
          content: {'ko': '내용1'},
        );
        final popup2 = Popup(
          id: 2,
          title: {'ko': '테스트2'},
          content: {'ko': '내용2'},
        );

        expect(popup1, isNot(equals(popup2)));
      });
    });

    group('Popup 리스트 변환', () {
      test('JSON 리스트에서 Popup 리스트를 생성할 수 있다', () {
        final jsonList = [
          {
            'id': 1,
            'title': {'ko': '팝업1'},
            'content': {'ko': '내용1'},
          },
          {
            'id': 2,
            'title': {'ko': '팝업2'},
            'content': {'ko': '내용2'},
          },
          {
            'id': 3,
            'title': {'ko': '팝업3'},
            'content': {'ko': '내용3'},
          },
        ];

        final popups = jsonList
            .map((e) => Popup.fromJson(e as Map<String, dynamic>))
            .toList();

        expect(popups.length, 3);
        expect(popups[0].id, 1);
        expect(popups[1].title['ko'], '팝업2');
        expect(popups[2].content['ko'], '내용3');
      });

      test('빈 JSON 리스트에서 빈 Popup 리스트를 반환한다', () {
        final jsonList = <Map<String, dynamic>>[];

        final popups = jsonList.map((e) => Popup.fromJson(e)).toList();

        expect(popups, isEmpty);
      });
    });

    group('Popup copyWith', () {
      test('copyWith으로 title을 변경할 수 있다', () {
        final popup = Popup(
          id: 1,
          title: {'ko': '원래'},
          content: {'ko': '내용'},
        );

        final updated = popup.copyWith(title: {'ko': '수정됨'});
        expect(updated.title['ko'], '수정됨');
        expect(updated.id, 1);
        expect(updated.content['ko'], '내용');
      });

      test('copyWith으로 날짜를 추가할 수 있다', () {
        final popup = Popup(
          id: 1,
          title: {'ko': '테스트'},
          content: {'ko': '내용'},
        );

        final withDates = popup.copyWith(
          startAt: DateTime(2025, 6, 1),
          stopAt: DateTime(2025, 12, 31),
        );
        expect(withDates.startAt, isNotNull);
        expect(withDates.stopAt, isNotNull);
        expect(withDates.startAt!.month, 6);
      });

      test('copyWith으로 image를 설정할 수 있다', () {
        final popup = Popup(
          id: 1,
          title: {'ko': '팝업'},
          content: {'ko': '내용'},
        );

        final withImage = popup.copyWith(
          image: {'ko': 'https://example.com/popup.png'},
        );
        expect(withImage.image, isNotNull);
        expect(withImage.image!['ko'], 'https://example.com/popup.png');
      });
    });

    group('Popup 날짜 파싱', () {
      test('다양한 ISO 8601 날짜 형식을 파싱할 수 있다', () {
        final json = {
          'id': 1,
          'title': {'ko': '날짜 테스트'},
          'content': {'ko': '내용'},
          'start_at': '2025-06-15T09:30:00.000+09:00',
          'stop_at': '2025-12-31T23:59:59.999Z',
        };

        final popup = Popup.fromJson(json);
        expect(popup.startAt, isNotNull);
        expect(popup.stopAt, isNotNull);
      });

      test('deleted_at이 설정된 Popup을 파싱할 수 있다', () {
        final json = {
          'id': 1,
          'title': {'ko': '삭제된 팝업'},
          'content': {'ko': '내용'},
          'deleted_at': '2025-06-01T00:00:00.000Z',
        };

        final popup = Popup.fromJson(json);
        expect(popup.deletedAt, isNotNull);
      });
    });

    group('Popup 다국어 필드', () {
      test('다국어 title과 content를 올바르게 저장한다', () {
        final json = {
          'id': 1,
          'title': {'ko': '한국어', 'en': 'English', 'ja': '日本語'},
          'content': {'ko': '내용', 'en': 'Content', 'ja': 'コンテンツ'},
        };

        final popup = Popup.fromJson(json);
        expect(popup.title.length, 3);
        expect(popup.content['ja'], 'コンテンツ');
      });
    });
  });
}
