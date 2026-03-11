import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';

void main() {
  group('AdLoadingStateNotifier', () {
    test('initial state is empty map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(adLoadingStateProvider), isEmpty);
    });

    test('setLoading adds entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(adLoadingStateProvider.notifier)
          .setLoading('ad-1', true);
      expect(container.read(adLoadingStateProvider)['ad-1'], isTrue);
    });

    test('setLoading updates existing entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(adLoadingStateProvider.notifier)
          .setLoading('ad-1', true);
      container
          .read(adLoadingStateProvider.notifier)
          .setLoading('ad-1', false);
      expect(container.read(adLoadingStateProvider)['ad-1'], isFalse);
    });

    test('isAdLoading returns true for loading ad', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(adLoadingStateProvider.notifier)
          .setLoading('ad-1', true);
      expect(
        container.read(adLoadingStateProvider.notifier).isAdLoading('ad-1'),
        isTrue,
      );
    });

    test('isAdLoading returns false for unknown ad', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(adLoadingStateProvider.notifier).isAdLoading('unknown'),
        isFalse,
      );
    });

    test('multiple ads tracked independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(adLoadingStateProvider.notifier)
          .setLoading('ad-1', true);
      container
          .read(adLoadingStateProvider.notifier)
          .setLoading('ad-2', false);
      expect(
        container.read(adLoadingStateProvider.notifier).isAdLoading('ad-1'),
        isTrue,
      );
      expect(
        container.read(adLoadingStateProvider.notifier).isAdLoading('ad-2'),
        isFalse,
      );
    });
  });
}
