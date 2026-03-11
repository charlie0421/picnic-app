import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';

void main() {
  group('ArtistGroupModel', () {
    test('필수 파라미터로 생성', () {
      const group = ArtistGroupModel(
        id: 1,
        name: {'ko': '방탄소년단', 'en': 'BTS'},
        image: null,
      );
      expect(group.id, equals(1));
      expect(group.name['ko'], equals('방탄소년단'));
      expect(group.image, isNull);
    });

    test('이미지 포함 생성', () {
      const group = ArtistGroupModel(
        id: 2,
        name: {'ko': '에스파'},
        image: 'https://example.com/aespa.jpg',
      );
      expect(group.image, equals('https://example.com/aespa.jpg'));
    });

    test('빈 name 맵으로 생성', () {
      const group = ArtistGroupModel(
        id: 3,
        name: {},
        image: null,
      );
      expect(group.name, isEmpty);
    });
  });
}
