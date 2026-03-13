import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/celeb_search_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncCelebSearch', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'celeb': [
          {'id': 1, 'name_ko': '지민', 'name_en': 'Jimin'},
          {'id': 2, 'name_ko': '뷔', 'name_en': 'V'},
        ],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('initial state is empty list', () async {
      final result = await container.read(asyncCelebSearchProvider.future);
      expect(result, isEmpty);
    });

    test('reset sets state to empty list', () async {
      await container.read(asyncCelebSearchProvider.future);
      await container.read(asyncCelebSearchProvider.notifier).reset();
      final state = container.read(asyncCelebSearchProvider);
      expect(state.value, isEmpty);
    });

    test('searchCeleb updates state with results', () async {
      await container.read(asyncCelebSearchProvider.future);
      final notifier = container.read(asyncCelebSearchProvider.notifier);

      await notifier.searchCeleb('지민');

      final state = container.read(asyncCelebSearchProvider);
      expect(state.value, isNotNull);
      // Mock returns all celeb data regardless of query filter
      expect(state.value!.length, 2);
      expect(state.value![0].id, 1);
      expect(state.value![0].nameKo, '지민');
      expect(state.value![1].nameEn, 'V');
    });

    test('searchCeleb with English query returns results', () async {
      await container.read(asyncCelebSearchProvider.future);
      final notifier = container.read(asyncCelebSearchProvider.notifier);

      await notifier.searchCeleb('Jimin');

      final state = container.read(asyncCelebSearchProvider);
      expect(state.value, isNotNull);
      expect(state.value!.isNotEmpty, isTrue);
    });

    test('repeatSearch does nothing when no previous query', () async {
      await container.read(asyncCelebSearchProvider.future);
      final notifier = container.read(asyncCelebSearchProvider.notifier);

      // repeatSearch with no prior searchCeleb call
      await notifier.repeatSearch();

      final state = container.read(asyncCelebSearchProvider);
      // State should still be the initial empty list
      expect(state.value, isEmpty);
    });

    test('reset after search clears results', () async {
      await container.read(asyncCelebSearchProvider.future);
      final notifier = container.read(asyncCelebSearchProvider.notifier);

      await notifier.searchCeleb('지민');
      expect(container.read(asyncCelebSearchProvider).value!.isNotEmpty, isTrue);

      await notifier.reset();
      expect(container.read(asyncCelebSearchProvider).value, isEmpty);
    });

    test('multiple searches update state each time', () async {
      await container.read(asyncCelebSearchProvider.future);
      final notifier = container.read(asyncCelebSearchProvider.notifier);

      await notifier.searchCeleb('지민');
      final firstResult = container.read(asyncCelebSearchProvider).value;
      expect(firstResult, isNotNull);

      await notifier.searchCeleb('뷔');
      final secondResult = container.read(asyncCelebSearchProvider).value;
      expect(secondResult, isNotNull);
    });
  });

  group('AsyncCelebSearch - empty results', () {
    late ProviderContainer container;

    setUp(() {
      setupMockSupabase({
        'celeb': <Map<String, dynamic>>[],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('searchCeleb returns empty list when no matches', () async {
      await container.read(asyncCelebSearchProvider.future);
      final notifier = container.read(asyncCelebSearchProvider.notifier);

      await notifier.searchCeleb('nonexistent');

      final state = container.read(asyncCelebSearchProvider);
      expect(state.value, isEmpty);
    });
  });
}
