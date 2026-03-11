import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';

void main() {
  group('GlobalMediaQuery', () {
    test('initial state is default MediaQueryData', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final data = container.read(globalMediaQueryProvider);
      expect(data.size, Size.zero);
    });

    test('updateMediaQueryData changes state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const newData = MediaQueryData(
        size: Size(375, 812),
        devicePixelRatio: 3.0,
      );
      container
          .read(globalMediaQueryProvider.notifier)
          .updateMediaQueryData(newData);
      final data = container.read(globalMediaQueryProvider);
      expect(data.size, const Size(375, 812));
      expect(data.devicePixelRatio, 3.0);
    });

    test('updateMediaQueryData replaces previous data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(globalMediaQueryProvider.notifier).updateMediaQueryData(
            const MediaQueryData(size: Size(320, 568)),
          );
      container.read(globalMediaQueryProvider.notifier).updateMediaQueryData(
            const MediaQueryData(size: Size(414, 896)),
          );
      final data = container.read(globalMediaQueryProvider);
      expect(data.size, const Size(414, 896));
    });
  });
}
