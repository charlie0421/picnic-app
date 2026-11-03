import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';

void main() {
  test(
    'badge and products start without waiting for human permission',
    () async {
      final permission = Completer<void>();
      final events = <String>[];

      final running = AppInitializer.runIndependentBackgroundTasks(
        isActive: () => true,
        preloadProducts: () async {
          events.add('products');
        },
        syncBadge: () {
          events.add('badge');
        },
        initializePush: () async {
          events.add('push');
          await permission.future;
        },
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, ['products', 'badge', 'push']);
      var completed = false;
      running.then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      permission.complete();
      await running;
    },
  );

  test(
    'an independent failure does not prevent the other operations',
    () async {
      final events = <String>[];
      await AppInitializer.runIndependentBackgroundTasks(
        isActive: () => true,
        preloadProducts: () async {
          events.add('products');
          throw StateError('product failure');
        },
        syncBadge: () => events.add('badge'),
        initializePush: () async => events.add('push'),
      );
      expect(events, ['products', 'badge', 'push']);
    },
  );
}
