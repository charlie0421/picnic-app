import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';

ScreenInfo _createScreenInfo(PortalType type) {
  return ScreenInfo(
    type: type,
    color: Colors.blue,
    pages: const [],
  );
}

void main() {
  group('ScreenInfosNotifier', () {
    test('initial state is empty map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(screenInfosProvider), isEmpty);
    });

    test('update replaces entire map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final infos = {
        'vote': _createScreenInfo(PortalType.vote),
        'pic': _createScreenInfo(PortalType.pic),
      };
      container.read(screenInfosProvider.notifier).update(infos);
      final state = container.read(screenInfosProvider);
      expect(state.length, 2);
      expect(state['vote']?.type, PortalType.vote);
    });

    test('add inserts single entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(screenInfosProvider.notifier)
          .add('vote', _createScreenInfo(PortalType.vote));
      final state = container.read(screenInfosProvider);
      expect(state.length, 1);
      expect(state['vote']?.type, PortalType.vote);
    });

    test('add multiple entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(screenInfosProvider.notifier)
          .add('vote', _createScreenInfo(PortalType.vote));
      container
          .read(screenInfosProvider.notifier)
          .add('pic', _createScreenInfo(PortalType.pic));
      final state = container.read(screenInfosProvider);
      expect(state.length, 2);
    });

    test('remove removes specific entry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(screenInfosProvider.notifier)
          .add('vote', _createScreenInfo(PortalType.vote));
      container
          .read(screenInfosProvider.notifier)
          .add('pic', _createScreenInfo(PortalType.pic));
      container.read(screenInfosProvider.notifier).remove('vote');
      final state = container.read(screenInfosProvider);
      expect(state.length, 1);
      expect(state.containsKey('vote'), isFalse);
      expect(state.containsKey('pic'), isTrue);
    });

    test('remove non-existent key does nothing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(screenInfosProvider.notifier)
          .add('vote', _createScreenInfo(PortalType.vote));
      container.read(screenInfosProvider.notifier).remove('nonexistent');
      final state = container.read(screenInfosProvider);
      expect(state.length, 1);
    });
  });
}
