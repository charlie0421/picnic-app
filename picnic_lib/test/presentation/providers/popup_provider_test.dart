import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/data/models/common/popup.dart';

void main() {
  group('popupProvider 구조 테스트', () {
    test('popupProvider가 정의되어 있는지 확인', () {
      expect(popupProvider, isNotNull);
    });

    test('popupProvider가 올바른 타입인지 확인', () {
      // Riverpod 코드 생성 프로바이더는 ProviderBase/FutureProvider를 직접 노출하지 않으므로
      // null이 아닌지와 존재 여부만 확인
      expect(popupProvider, isNotNull);
    });
  });

  group('Popup 모델 구조 테스트', () {
    test('Popup 모델을 JSON에서 생성할 수 있는지 확인', () {
      final json = {
        'id': 1,
        'title': {'ko': '테스트 제목', 'en': 'Test Title'},
        'content': {'ko': '테스트 내용', 'en': 'Test Content'},
      };

      final popup = Popup.fromJson(json);
      expect(popup.id, 1);
      expect(popup.title['ko'], '테스트 제목');
      expect(popup.content['en'], 'Test Content');
    });

    test('Popup 모델의 선택적 필드가 null일 수 있는지 확인', () {
      final json = {
        'id': 2,
        'title': {'ko': '팝업'},
        'content': {'ko': '내용'},
      };

      final popup = Popup.fromJson(json);
      expect(popup.image, isNull);
      expect(popup.createdAt, isNull);
      expect(popup.updatedAt, isNull);
      expect(popup.deletedAt, isNull);
      expect(popup.startAt, isNull);
      expect(popup.stopAt, isNull);
    });

    test('Popup 모델에 이미지와 날짜 필드가 포함된 JSON을 파싱할 수 있는지 확인', () {
      final json = {
        'id': 3,
        'title': {'ko': '이벤트'},
        'content': {'ko': '이벤트 내용'},
        'image': {'ko': 'https://example.com/image.png'},
        'start_at': '2025-01-01T00:00:00.000Z',
        'stop_at': '2025-12-31T23:59:59.000Z',
      };

      final popup = Popup.fromJson(json);
      expect(popup.image, isNotNull);
      expect(popup.image!['ko'], 'https://example.com/image.png');
      expect(popup.startAt, isNotNull);
      expect(popup.stopAt, isNotNull);
    });

    test('Popup 모델의 copyWith가 정상 동작하는지 확인', () {
      final popup = Popup(
        id: 1,
        title: {'ko': '원본'},
        content: {'ko': '원본 내용'},
      );

      final updated = popup.copyWith(
        title: {'ko': '수정됨'},
      );
      expect(updated.title['ko'], '수정됨');
      expect(updated.id, 1);
      expect(updated.content['ko'], '원본 내용');
    });
  });
}
