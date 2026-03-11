import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/bottom_navigation_provider.dart';

void main() {
  group('BottomNavigationBarCount', () {
    test('initial value is 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(bottomNavigationBarIndexStateProvider), 0);
    });

    test('setIndex updates value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bottomNavigationBarIndexStateProvider.notifier)
          .setIndex(2);
      expect(container.read(bottomNavigationBarIndexStateProvider), 2);
    });

    test('setIndex updates to different values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bottomNavigationBarIndexStateProvider.notifier)
          .setIndex(1);
      expect(container.read(bottomNavigationBarIndexStateProvider), 1);
      container
          .read(bottomNavigationBarIndexStateProvider.notifier)
          .setIndex(4);
      expect(container.read(bottomNavigationBarIndexStateProvider), 4);
    });
  });
}
