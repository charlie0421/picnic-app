import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmark_state_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('BookmarkState build()', () {
    test('initial state is an empty map', () {
      final state = container.read(bookmarkStateProvider);
      expect(state, isA<Map<int, bool>>());
      expect(state, isEmpty);
    });
  });

  group('updateBookmarkState()', () {
    test('adds a bookmarked artist', () {
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, true);

      final state = container.read(bookmarkStateProvider);
      expect(state[1], isTrue);
    });

    test('adds an un-bookmarked artist', () {
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(1, false);

      final state = container.read(bookmarkStateProvider);
      expect(state[1], isFalse);
    });

    test('updates an existing entry from true to false', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(10, true);
      notifier.updateBookmarkState(10, false);

      expect(container.read(bookmarkStateProvider)[10], isFalse);
    });

    test('updates an existing entry from false to true', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(10, false);
      notifier.updateBookmarkState(10, true);

      expect(container.read(bookmarkStateProvider)[10], isTrue);
    });

    test('handles multiple distinct artist IDs', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);
      notifier.updateBookmarkState(2, false);
      notifier.updateBookmarkState(3, true);

      final state = container.read(bookmarkStateProvider);
      expect(state.length, 3);
      expect(state[1], isTrue);
      expect(state[2], isFalse);
      expect(state[3], isTrue);
    });

    test('preserves other entries when updating one', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);
      notifier.updateBookmarkState(2, true);
      notifier.updateBookmarkState(1, false);

      final state = container.read(bookmarkStateProvider);
      expect(state[1], isFalse);
      expect(state[2], isTrue);
    });
  });

  group('getBookmarkState()', () {
    test('returns true for a bookmarked artist', () {
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(42, true);

      final result =
          container.read(bookmarkStateProvider.notifier).getBookmarkState(42);
      expect(result, isTrue);
    });

    test('returns false for an un-bookmarked artist', () {
      container
          .read(bookmarkStateProvider.notifier)
          .updateBookmarkState(42, false);

      final result =
          container.read(bookmarkStateProvider.notifier).getBookmarkState(42);
      expect(result, isFalse);
    });

    test('returns null for an unknown artist ID', () {
      final result =
          container.read(bookmarkStateProvider.notifier).getBookmarkState(999);
      expect(result, isNull);
    });

    test('returns null after the entry has been removed', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(5, true);
      notifier.removeOverride(5);

      expect(notifier.getBookmarkState(5), isNull);
    });
  });

  group('clearOverrides()', () {
    test('resets state to empty map', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);
      notifier.updateBookmarkState(2, false);
      notifier.updateBookmarkState(3, true);

      notifier.clearOverrides();

      final state = container.read(bookmarkStateProvider);
      expect(state, isEmpty);
    });

    test('is safe to call on already empty state', () {
      container.read(bookmarkStateProvider.notifier).clearOverrides();
      expect(container.read(bookmarkStateProvider), isEmpty);
    });

    test('allows adding entries again after clearing', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);
      notifier.clearOverrides();
      notifier.updateBookmarkState(2, false);

      final state = container.read(bookmarkStateProvider);
      expect(state.length, 1);
      expect(state.containsKey(1), isFalse);
      expect(state[2], isFalse);
    });
  });

  group('removeOverride()', () {
    test('removes a specific entry', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);
      notifier.updateBookmarkState(2, false);

      notifier.removeOverride(1);

      final state = container.read(bookmarkStateProvider);
      expect(state.containsKey(1), isFalse);
      expect(state[2], isFalse);
    });

    test('does nothing when removing a non-existent key', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);

      notifier.removeOverride(999);

      final state = container.read(bookmarkStateProvider);
      expect(state.length, 1);
      expect(state[1], isTrue);
    });

    test('is safe to call on empty state', () {
      container.read(bookmarkStateProvider.notifier).removeOverride(1);
      expect(container.read(bookmarkStateProvider), isEmpty);
    });

    test('removes the last entry resulting in empty state', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);
      notifier.removeOverride(1);

      expect(container.read(bookmarkStateProvider), isEmpty);
    });
  });

  group('state immutability', () {
    test('each update produces a new map instance', () {
      final notifier = container.read(bookmarkStateProvider.notifier);

      final state1 = container.read(bookmarkStateProvider);
      notifier.updateBookmarkState(1, true);
      final state2 = container.read(bookmarkStateProvider);

      expect(identical(state1, state2), isFalse);
    });

    test('removeOverride produces a new map instance', () {
      final notifier = container.read(bookmarkStateProvider.notifier);
      notifier.updateBookmarkState(1, true);

      final stateBefore = container.read(bookmarkStateProvider);
      notifier.removeOverride(1);
      final stateAfter = container.read(bookmarkStateProvider);

      expect(identical(stateBefore, stateAfter), isFalse);
    });
  });
}
