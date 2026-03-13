import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';

void main() {
  group('SearchState', () {
    test('default values', () {
      const state = SearchState();
      expect(state.query, '');
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates fields', () {
      const state = SearchState();
      final updated = state.copyWith(
        query: 'test',
        isLoading: true,
        hasError: true,
        errorMessage: 'Error occurred',
      );
      expect(updated.query, 'test');
      expect(updated.isLoading, isTrue);
      expect(updated.hasError, isTrue);
      expect(updated.errorMessage, 'Error occurred');
    });

    test('copyWith preserves unchanged fields', () {
      const state = SearchState(query: 'hello', isLoading: true);
      final updated = state.copyWith(hasError: true);
      expect(updated.query, 'hello');
      expect(updated.isLoading, isTrue);
      expect(updated.hasError, isTrue);
    });

    test('equality works correctly', () {
      const state1 = SearchState(query: 'test', isLoading: true);
      const state2 = SearchState(query: 'test', isLoading: true);
      const state3 = SearchState(query: 'other', isLoading: true);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('hashCode is consistent with equality', () {
      const state1 = SearchState(query: 'test', isLoading: true);
      const state2 = SearchState(query: 'test', isLoading: true);

      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('identical check returns true for same instance', () {
      const state = SearchState(query: 'test');
      expect(state == state, isTrue);
    });

    test('not equal to non-SearchState object', () {
      const state = SearchState(query: 'test');
      // ignore: unrelated_type_equality_checks
      expect(state == 'not a search state', isFalse);
    });
  });
}
