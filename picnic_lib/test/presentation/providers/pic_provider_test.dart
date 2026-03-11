import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/pic_provider.dart';

void main() {
  group('IntNotifier', () {
    test('initial value is 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(parmePageIndexProvider), 0);
    });

    test('set updates value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(parmePageIndexProvider.notifier).set(5);
      expect(container.read(parmePageIndexProvider), 5);
    });

    test('picSelectedIndexProvider initial value is 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(picSelectedIndexProvider), 0);
    });

    test('picSelectedIndexProvider set works', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(picSelectedIndexProvider.notifier).set(3);
      expect(container.read(picSelectedIndexProvider), 3);
    });
  });

  group('NullableFileNotifier', () {
    test('initial value is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(userImageProvider), isNull);
    });

    test('set updates to file', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final file = File('/tmp/test.png');
      container.read(userImageProvider.notifier).set(file);
      expect(container.read(userImageProvider), file);
    });

    test('set to null clears value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(userImageProvider.notifier).set(File('/tmp/test.png'));
      container.read(userImageProvider.notifier).set(null);
      expect(container.read(userImageProvider), isNull);
    });

    test('convertedImageProvider initial value is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(convertedImageProvider), isNull);
    });
  });
}
