import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/article/article_list.dart';

/// Tests for ArticleList production code.
///
/// Widget rendering requires asyncArticleListProvider and infinite_scroll_pagination.
/// We test importable production code: constructor.
void main() {
  group('ArticleList widget', () {
    test('can be constructed with galleryId', () {
      const widget = ArticleList(42);
      expect(widget, isA<ArticleList>());
      expect(widget.galleryId, 42);
    });

    test('with key can be constructed', () {
      const widget = ArticleList(1, key: ValueKey('article_list'));
      expect(widget.key, equals(const ValueKey('article_list')));
    });

    test('different galleryIds', () {
      const w1 = ArticleList(1);
      const w2 = ArticleList(999);
      expect(w1.galleryId, isNot(w2.galleryId));
    });
  });
}
