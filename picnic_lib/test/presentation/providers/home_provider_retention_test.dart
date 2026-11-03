import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  setUp(() {
    setupMockSupabase({
      'media': [
        {
          'id': 1,
          'video_id': 'video',
          'video_url': '',
          'title': {'ko': '미디어'},
        },
      ],
    });
  });
  tearDown(tearDownMockSupabase);

  int mediaRequests() => capturedMockRequests
      .where((uri) => uri.path.contains('/rest/v1/media'))
      .length;

  int rewardRequests() => capturedMockRequests
      .where((uri) => uri.path.contains('/rest/v1/reward'))
      .length;

  int voteRequests() => capturedMockRequests
      .where((uri) => uri.path.endsWith('/rest/v1/vote'))
      .length;

  test(
    'successful latest media survives tab return and expires after two minutes',
    () {
      fakeAsync((async) {
        final container = ProviderContainer();
        final first = container.listen(asyncLatestMediaProvider, (_, _) {});
        async.flushMicrotasks();
        expect(mediaRequests(), 1);
        first.close();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 119));
        final returned = container.listen(asyncLatestMediaProvider, (_, _) {});
        async.flushMicrotasks();
        expect(mediaRequests(), 1);
        returned.close();
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();
        final expired = container.listen(asyncLatestMediaProvider, (_, _) {});
        async.flushMicrotasks();
        expect(mediaRequests(), 2);
        expired.close();
        container.dispose();
      });
    },
  );

  test('manual invalidation refetches immediately', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      final subscription = container.listen(
        asyncLatestMediaProvider,
        (_, _) {},
      );
      async.flushMicrotasks();
      expect(mediaRequests(), 1);

      container.refresh(asyncLatestMediaProvider.future);
      async.flushMicrotasks();
      async.elapse(Duration.zero);
      async.flushMicrotasks();
      expect(mediaRequests(), 2);
      subscription.close();
      container.dispose();
    });
  });

  test('successful rewards use the same two minute home retention', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      final first = container.listen(asyncRewardListProvider, (_, _) {});
      async.flushMicrotasks();
      expect(rewardRequests(), 1);
      first.close();
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 119));
      final returned = container.listen(asyncRewardListProvider, (_, _) {});
      async.flushMicrotasks();
      expect(rewardRequests(), 1);
      returned.close();
      async.flushMicrotasks();

      async.elapse(const Duration(minutes: 2));
      async.flushMicrotasks();
      final expired = container.listen(asyncRewardListProvider, (_, _) {});
      async.flushMicrotasks();
      expect(rewardRequests(), 2);
      expired.close();
      container.dispose();
    });
  });

  test('failed provider result is disposed instead of retained', () async {
    tearDownMockSupabase();
    setupMockSupabase({'media': <dynamic>[]}, tableStatusCodes: {'media': 500});
    final container = ProviderContainer(retry: (_, _) => null);
    addTearDown(container.dispose);

    final first = container.listen(asyncLatestMediaProvider, (_, _) {});
    await expectLater(
      container.read(asyncLatestMediaProvider.future),
      throwsA(anything),
    );
    first.close();
    await Future<void>.delayed(Duration.zero);

    final retried = container.listen(asyncLatestMediaProvider, (_, _) {});
    await expectLater(
      container.read(asyncLatestMediaProvider.future),
      throwsA(anything),
    );
    expect(mediaRequests(), 2);
    retried.close();
  });

  test('active vote expiry invalidates a retained successful result', () async {
    tearDownMockSupabase();
    final stopAt = DateTime.now().add(const Duration(milliseconds: 150));
    setupMockSupabase({
      'vote': [
        {
          'id': 7,
          'title': {'ko': '투표'},
          'vote_category': 'birthday',
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'vote_item': <dynamic>[],
          'created_at': DateTime.now().toIso8601String(),
          'visible_at': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'start_at': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'stop_at': stopAt.toIso8601String(),
          'is_partnership': false,
          'partner': null,
          'area': null,
          'reward': <dynamic>[],
        },
      ],
      'vote_item': <dynamic>[],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      asyncActiveFeaturedVotesProvider,
      (_, _) {},
    );
    await container.read(asyncActiveFeaturedVotesProvider.future);
    expect(voteRequests(), 1);

    await Future<void>.delayed(const Duration(milliseconds: 250));
    await container.read(asyncActiveFeaturedVotesProvider.future);
    expect(voteRequests(), 2);
    subscription.close();
  });
}
