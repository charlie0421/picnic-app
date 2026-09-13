import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/branch_link_service.dart';

void main() {
  test('buffers distinct links until handler and Portal are ready', () async {
    final sessions = StreamController<Map<dynamic, dynamic>>.broadcast();
    final opened = <String>[];
    final service = BranchLinkService(sessionEvents: () => sessions.stream);
    await service.start();
    sessions
      ..add({'+clicked_branch_link': true, r'$desktop_url': 'https://x/vote/1'})
      ..add({
        '+clicked_branch_link': true,
        r'$desktop_url': 'https://x/vote/2',
      });
    await Future<void>.delayed(Duration.zero);

    final owner = service.attachHandler((url) async => opened.add(url));
    expect(opened, isEmpty);
    service.setHandlerReady(owner, true);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(opened, ['https://x/vote/1', 'https://x/vote/2']);
    await service.dispose();
    await sessions.close();
  });

  test('deduplicates queued and in-flight identical callbacks', () async {
    final sessions = StreamController<Map<dynamic, dynamic>>.broadcast();
    final release = Completer<void>();
    var opens = 0;
    final service = BranchLinkService(sessionEvents: () => sessions.stream);
    final owner = service.attachHandler((_) async {
      opens++;
      await release.future;
    });
    service.setHandlerReady(owner, true);
    await service.start();
    final event = {
      '+clicked_branch_link': true,
      r'$desktop_url': 'https://x/vote/1',
    };
    sessions
      ..add(event)
      ..add(event)
      ..add(event);
    await Future<void>.delayed(Duration.zero);
    expect(opens, 1);
    release.complete();
    await Future<void>.delayed(Duration.zero);
    await service.dispose();
    await sessions.close();
  });

  test('detach drops past links and invalidates an active handler', () async {
    final sessions = StreamController<Map<dynamic, dynamic>>.broadcast();
    final opened = <String>[];
    final service = BranchLinkService(sessionEvents: () => sessions.stream);
    final owner = service.attachHandler((url) async => opened.add(url));
    await service.start();
    sessions.add({
      '+clicked_branch_link': true,
      r'$desktop_url': 'https://x/vote/old',
    });
    await Future<void>.delayed(Duration.zero);
    service.detachHandler(owner);
    final replacement = service.attachHandler((url) async => opened.add(url));
    service.setHandlerReady(replacement, true);
    await Future<void>.delayed(Duration.zero);
    expect(opened, isEmpty);
    await service.dispose();
    await sessions.close();
  });

  test('listener start can retry after SDK readiness catches up', () async {
    final sessions = StreamController<Map<dynamic, dynamic>>.broadcast();
    var sdkReady = false;
    final service = BranchLinkService(
      sessionEvents: () {
        if (!sdkReady) throw StateError('SDK is not initialized');
        return sessions.stream;
      },
    );

    await expectLater(service.start(), throwsStateError);
    sdkReady = true;
    await service.start();
    final opened = <String>[];
    final owner = service.attachHandler((url) async => opened.add(url));
    service.setHandlerReady(owner, true);
    sessions.add({
      '+clicked_branch_link': true,
      r'$desktop_url': 'https://x/vote/ready',
    });
    await Future<void>.delayed(Duration.zero);
    expect(opened, ['https://x/vote/ready']);
    await service.dispose();
    await sessions.close();
  });

  test('reattach drains new links after a stale handler completes', () async {
    final sessions = StreamController<Map<dynamic, dynamic>>.broadcast();
    final releaseOld = Completer<void>();
    final opened = <String>[];
    final service = BranchLinkService(sessionEvents: () => sessions.stream);
    final oldOwner = service.attachHandler((url) async {
      opened.add('old:$url');
      await releaseOld.future;
    });
    service.setHandlerReady(oldOwner, true);
    await service.start();
    sessions.add({
      '+clicked_branch_link': true,
      r'$desktop_url': 'https://x/vote/old',
    });
    await Future<void>.delayed(Duration.zero);

    service.detachHandler(oldOwner);
    final newOwner = service.attachHandler(
      (url) async => opened.add('new:$url'),
    );
    service.setHandlerReady(newOwner, true);
    sessions.add({
      '+clicked_branch_link': true,
      r'$desktop_url': 'https://x/vote/new',
    });
    await Future<void>.delayed(Duration.zero);
    expect(opened, ['old:https://x/vote/old']);

    releaseOld.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(opened, ['old:https://x/vote/old', 'new:https://x/vote/new']);
    await service.dispose();
    await sessions.close();
  });

  test(
    'stale remount owner cannot detach or change readiness of new owner',
    () async {
      final sessions = StreamController<Map<dynamic, dynamic>>.broadcast();
      final opened = <String>[];
      final service = BranchLinkService(sessionEvents: () => sessions.stream);
      await service.start();
      final oldOwner = service.attachHandler(
        (url) async => opened.add('old:$url'),
      );
      service.setHandlerReady(oldOwner, true);

      // Phoenix inflates the replacement App before disposing the old one.
      final newOwner = service.attachHandler(
        (url) async => opened.add('new:$url'),
      );
      service.setHandlerReady(newOwner, true);
      service.detachHandler(oldOwner);
      service.setHandlerReady(oldOwner, false);

      sessions.add({
        '+clicked_branch_link': true,
        r'$desktop_url': 'https://x/vote/remounted',
      });
      await Future<void>.delayed(Duration.zero);
      expect(service.isHandlerReady, isTrue);
      expect(opened, ['new:https://x/vote/remounted']);
      await service.dispose();
      await sessions.close();
    },
  );
}
