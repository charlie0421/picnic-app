import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/popup.dart';

void main() {
  group('Popup', () {
    test('필수 파라미터로 생성', () {
      const popup = Popup(
        id: 1,
        title: {'ko': '팝업 제목', 'en': 'Popup Title'},
        content: {'ko': '팝업 내용', 'en': 'Popup Content'},
      );
      expect(popup.id, equals(1));
      expect(popup.title['ko'], equals('팝업 제목'));
      expect(popup.content['en'], equals('Popup Content'));
      expect(popup.image, isNull);
      expect(popup.createdAt, isNull);
      expect(popup.startAt, isNull);
      expect(popup.stopAt, isNull);
    });

    test('전체 파라미터로 생성', () {
      final now = DateTime.now();
      final popup = Popup(
        id: 2,
        title: const {'ko': '제목'},
        content: const {'ko': '내용'},
        image: const {'ko': 'https://example.com/popup.jpg'},
        createdAt: now,
        updatedAt: now,
        startAt: now,
        stopAt: now.add(const Duration(days: 7)),
      );
      expect(popup.image, isNotNull);
      expect(popup.createdAt, equals(now));
      expect(popup.startAt, equals(now));
    });
  });
}
