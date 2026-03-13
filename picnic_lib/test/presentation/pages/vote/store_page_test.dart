import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';

void main() {
  group('StorePage widget', () {
    test('can be const-constructed', () {
      const page = StorePage();
      expect(page, isA<StorePage>());
    });

    test('with key can be constructed', () {
      const page = StorePage(key: ValueKey('store'));
      expect(page.key, equals(const ValueKey('store')));
    });
  });
}
