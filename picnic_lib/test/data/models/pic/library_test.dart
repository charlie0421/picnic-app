import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/pic/library.dart';

void main() {
  group('LibraryModel', () {
    test('creates from constructor', () {
      const model = LibraryModel(
        id: 1,
        title: 'Test Library',
        images: null,
      );
      expect(model.id, 1);
      expect(model.title, 'Test Library');
      expect(model.images, isNull);
    });

    test('creates from JSON', () {
      final json = {
        'id': 5,
        'title': 'Photo Collection',
        'images': null,
      };
      final model = LibraryModel.fromJson(json);
      expect(model.id, 5);
      expect(model.title, 'Photo Collection');
      expect(model.images, isNull);
    });

    test('toJson serializes correctly', () {
      const model = LibraryModel(
        id: 1,
        title: 'Gallery',
        images: null,
      );
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['title'], 'Gallery');
    });

    test('copyWith updates fields', () {
      const model = LibraryModel(
        id: 1,
        title: 'Original',
        images: null,
      );
      final updated = model.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, 1);
    });

    test('equality works', () {
      const a = LibraryModel(id: 1, title: 'Lib', images: null);
      const b = LibraryModel(id: 1, title: 'Lib', images: null);
      expect(a, equals(b));
    });
  });
}
