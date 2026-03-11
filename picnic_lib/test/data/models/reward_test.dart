import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/reward.dart';

void main() {
  group('RewardModel', () {
    test('필수 필드만으로 생성', () {
      const reward = RewardModel(id: 1);
      expect(reward.id, equals(1));
      expect(reward.title, isNull);
      expect(reward.thumbnail, isNull);
      expect(reward.overviewImages, isNull);
      expect(reward.location, isNull);
      expect(reward.sizeGuide, isNull);
      expect(reward.sizeGuideImages, isNull);
    });

    test('모든 필드 포함 생성', () {
      const reward = RewardModel(
        id: 10,
        title: {'ko': '포토카드', 'en': 'Photocard'},
        thumbnail: 'https://example.com/thumb.jpg',
        overviewImages: [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
        location: {'ko': '서울', 'en': 'Seoul'},
        sizeGuide: {'width': '5cm', 'height': '8cm'},
        sizeGuideImages: ['https://example.com/size.jpg'],
      );
      expect(reward.id, equals(10));
      expect(reward.title!['ko'], equals('포토카드'));
      expect(reward.overviewImages!.length, equals(2));
      expect(reward.location!['en'], equals('Seoul'));
    });
  });
}
