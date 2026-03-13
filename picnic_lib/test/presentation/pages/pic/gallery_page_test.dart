import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/pic/gallery_page.dart';

/// Tests for GalleryPage production code.
///
/// Widget rendering requires asyncGalleryListProvider and navigation provider.
/// We test importable production code: constructor.
void main() {
  group('GalleryPage widget', () {
    test('can be const-constructed', () {
      const page = GalleryPage();
      expect(page, isA<GalleryPage>());
    });

    test('with key can be constructed', () {
      const page = GalleryPage(key: ValueKey('gallery'));
      expect(page.key, equals(const ValueKey('gallery')));
    });
  });
}
