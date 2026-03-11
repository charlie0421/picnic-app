import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmark_state_provider.dart';

void main() {
  group('BookmarkState', () {
    test('initial state is empty map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(bookmarkStateProvider);
      expect(state, isEmpty);
    });

    test('updateBookmarkState adds entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, true);
      final state = container.read(bookmarkStateProvider);
      expect(state[1], isTrue);
    });

    test('updateBookmarkState updates existing entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, true);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, false);
      final state = container.read(bookmarkStateProvider);
      expect(state[1], isFalse);
    });

    test('updateBookmarkState adds multiple entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, true);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(2, false);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(3, true);
      final state = container.read(bookmarkStateProvider);
      expect(state.length, 3);
      expect(state[1], isTrue);
      expect(state[2], isFalse);
      expect(state[3], isTrue);
    });

    test('getBookmarkState returns correct value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(42, true);
      final result =
          container.read(bookmarkStateProvider.notifier).getBookmarkState(42);
      expect(result, isTrue);
    });

    test('getBookmarkState returns null for unknown id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result =
          container.read(bookmarkStateProvider.notifier).getBookmarkState(999);
      expect(result, isNull);
    });

    test('clearOverrides resets to empty map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, true);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(2, false);
      container.read(bookmarkStateProvider.notifier).clearOverrides();
      final state = container.read(bookmarkStateProvider);
      expect(state, isEmpty);
    });

    test('removeOverride removes specific entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, true);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(2, false);
      container.read(bookmarkStateProvider.notifier).removeOverride(1);
      final state = container.read(bookmarkStateProvider);
      expect(state.containsKey(1), isFalse);
      expect(state[2], isFalse);
    });

    test('removeOverride does nothing for non-existent key', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, true);
      container.read(bookmarkStateProvider.notifier).removeOverride(999);
      final state = container.read(bookmarkStateProvider);
      expect(state.length, 1);
      expect(state[1], isTrue);
    });
  });
}
