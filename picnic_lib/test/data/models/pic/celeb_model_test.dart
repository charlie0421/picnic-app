import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';

void main() {
  group('CelebModel', () {
    test('필수 파라미터로 생성', () {
      const celeb = CelebModel(
        id: 1,
        nameKo: '방탄소년단',
        nameEn: 'BTS',
      );
      expect(celeb.id, equals(1));
      expect(celeb.nameKo, equals('방탄소년단'));
      expect(celeb.nameEn, equals('BTS'));
      expect(celeb.thumbnail, isNull);
      expect(celeb.users, isNull);
    });

    test('썸네일 포함 생성', () {
      const celeb = CelebModel(
        id: 2,
        nameKo: '에스파',
        nameEn: 'aespa',
        thumbnail: 'https://example.com/aespa.jpg',
      );
      expect(celeb.thumbnail, equals('https://example.com/aespa.jpg'));
    });
  });
}
