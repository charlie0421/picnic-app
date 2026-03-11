import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';

void main() {
  group('CelebModel', () {
    test('creates from constructor', () {
      const model = CelebModel(
        id: 1,
        nameKo: '아이유',
        nameEn: 'IU',
      );
      expect(model.id, 1);
      expect(model.nameKo, '아이유');
      expect(model.nameEn, 'IU');
      expect(model.thumbnail, isNull);
      expect(model.users, isNull);
    });

    test('creates with optional thumbnail', () {
      const model = CelebModel(
        id: 2,
        nameKo: 'BTS',
        nameEn: 'BTS',
        thumbnail: 'https://example.com/bts.jpg',
      );
      expect(model.thumbnail, 'https://example.com/bts.jpg');
    });

    test('creates from JSON', () {
      final json = {
        'id': 1,
        'name_ko': '아이유',
        'name_en': 'IU',
        'thumbnail': null,
        'users': null,
      };
      final model = CelebModel.fromJson(json);
      expect(model.id, 1);
      expect(model.nameKo, '아이유');
      expect(model.nameEn, 'IU');
    });

    test('toJson serializes correctly', () {
      const model = CelebModel(
        id: 1,
        nameKo: '아이유',
        nameEn: 'IU',
      );
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['name_ko'], '아이유');
      expect(json['name_en'], 'IU');
    });

    test('copyWith updates fields', () {
      const model = CelebModel(
        id: 1,
        nameKo: '원래이름',
        nameEn: 'Original',
      );
      final updated = model.copyWith(nameKo: '새이름', nameEn: 'Updated');
      expect(updated.nameKo, '새이름');
      expect(updated.nameEn, 'Updated');
      expect(updated.id, 1);
    });

    test('equality works', () {
      const a = CelebModel(id: 1, nameKo: '아이유', nameEn: 'IU');
      const b = CelebModel(id: 1, nameKo: '아이유', nameEn: 'IU');
      expect(a, equals(b));
    });
  });
}
