import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';

void main() {
  group('AdLoadingStateNotifier', () {
    late ProviderContainer container;
    late AdLoadingStateNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(adLoadingStateProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty map', () {
      final state = container.read(adLoadingStateProvider);
      expect(state, isEmpty);
    });

    test('setLoading sets ad to loading', () {
      notifier.setLoading('admob', true);
      final state = container.read(adLoadingStateProvider);
      expect(state['admob'], isTrue);
    });

    test('setLoading sets ad to not loading', () {
      notifier.setLoading('admob', true);
      notifier.setLoading('admob', false);
      final state = container.read(adLoadingStateProvider);
      expect(state['admob'], isFalse);
    });

    test('multiple ads can have independent loading states', () {
      notifier.setLoading('admob', true);
      notifier.setLoading('pangle', false);
      notifier.setLoading('tapjoy', true);

      final state = container.read(adLoadingStateProvider);
      expect(state['admob'], isTrue);
      expect(state['pangle'], isFalse);
      expect(state['tapjoy'], isTrue);
    });

    test('isAdLoading returns false for unknown ad', () {
      expect(notifier.isAdLoading('unknown'), isFalse);
    });

    test('isAdLoading returns current state for known ad', () {
      notifier.setLoading('admob', true);
      expect(notifier.isAdLoading('admob'), isTrue);

      notifier.setLoading('admob', false);
      expect(notifier.isAdLoading('admob'), isFalse);
    });

    test('setLoading preserves other ad states', () {
      notifier.setLoading('admob', true);
      notifier.setLoading('pangle', true);
      notifier.setLoading('admob', false);

      final state = container.read(adLoadingStateProvider);
      expect(state['admob'], isFalse);
      expect(state['pangle'], isTrue);
    });

    test('setLoading with same value is idempotent', () {
      notifier.setLoading('admob', true);
      notifier.setLoading('admob', true);
      final state = container.read(adLoadingStateProvider);
      expect(state['admob'], isTrue);
    });
  });
}
