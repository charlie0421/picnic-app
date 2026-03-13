import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_full_screen_image_viewer.dart';

void main() {

  group('QnaFullScreenImageViewer widget', () {
    test('can be constructed with required parameters', () {
      const viewer = QnaFullScreenImageViewer(
        imageUrls: ['https://example.com/img1.png', 'https://example.com/img2.png'],
      );
      expect(viewer, isA<QnaFullScreenImageViewer>());
      expect(viewer.imageUrls.length, 2);
      expect(viewer.initialIndex, 0);
    });

    test('initialIndex defaults to 0', () {
      const viewer = QnaFullScreenImageViewer(
        imageUrls: ['https://example.com/img.png'],
      );
      expect(viewer.initialIndex, 0);
    });

    test('initialIndex can be set', () {
      const viewer = QnaFullScreenImageViewer(
        imageUrls: ['https://example.com/1.png', 'https://example.com/2.png', 'https://example.com/3.png'],
        initialIndex: 2,
      );
      expect(viewer.initialIndex, 2);
    });

    test('with key can be constructed', () {
      const viewer = QnaFullScreenImageViewer(
        key: ValueKey('qna_viewer'),
        imageUrls: ['https://example.com/img.png'],
      );
      expect(viewer.key, equals(const ValueKey('qna_viewer')));
    });

    test('empty imageUrls list', () {
      const viewer = QnaFullScreenImageViewer(
        imageUrls: [],
      );
      expect(viewer.imageUrls, isEmpty);
    });

    test('single image URL in list', () {
      const viewer = QnaFullScreenImageViewer(
        imageUrls: ['https://example.com/only.png'],
      );
      expect(viewer.imageUrls.length, 1);
      expect(viewer.imageUrls.first, 'https://example.com/only.png');
    });
  });
}
