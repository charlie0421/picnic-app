import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_flow.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_session.dart';

void main() {
  const impressionId = '00000000-0000-4000-8000-000000000402';
  Map<String, dynamic> validIssue() => {
    'impression_id': impressionId,
    'ad': {'video_url': 'ads/video.mp4', 'cta_url': 'https://cta'},
    'tokens': {'view_token': 'view', 'more_token': 'more'},
  };

  test(
    'issues once and persists server UUID before returning playable result',
    () async {
      final events = <String>[];
      var invokes = 0;
      final flow = InternalShortformIssueFlow(
        currentOwner: () => 'user-a',
        invokeIssue: () async {
          invokes++;
          events.add('invoke');
          return validIssue();
        },
        persist: (owner, reference) async {
          events.add('persist:$owner:${reference.id}');
        },
        rewriteVideoUrl: (_) => 'https://cdn/video.m3u8',
      );
      final result = await flow.issue();
      events.add('result');
      expect(invokes, 1);
      expect(result.reference.id, impressionId);
      expect(result.ownerUserId, 'user-a');
      expect(result.videoUrl, 'https://cdn/video.m3u8');
      expect(events, ['invoke', 'persist:user-a:$impressionId', 'result']);
    },
  );

  test(
    'missing/malformed issue fails closed with one invoke and no result',
    () async {
      for (final body in <Object?>[
        null,
        {'ad': {}, 'tokens': {}},
        {...validIssue(), 'impression_id': 'client-generated'},
        {
          ...validIssue(),
          'tokens': {'view_token': '', 'more_token': 'more'},
        },
      ]) {
        var invokes = 0;
        var persists = 0;
        final flow = InternalShortformIssueFlow(
          currentOwner: () => 'user-a',
          invokeIssue: () async {
            invokes++;
            return body;
          },
          persist: (_, _) async {
            persists++;
          },
          rewriteVideoUrl: (value) => value ?? '',
        );
        await expectLater(flow.issue(), throwsFormatException);
        expect(invokes, 1);
        expect(persists, 0);
      }
    },
  );

  test('unauthenticated issue fails before network or playback', () async {
    var invokes = 0;
    final flow = InternalShortformIssueFlow(
      currentOwner: () => null,
      invokeIssue: () async {
        invokes++;
        return validIssue();
      },
      persist: (_, _) async {},
      rewriteVideoUrl: (value) => value ?? '',
    );
    await expectLater(flow.issue(), throwsStateError);
    expect(invokes, 0);
  });

  test(
    'view callback invokes once, never reissues, and validates same owner/reference',
    () async {
      final session = InternalShortformRewardSession();
      await session.bindIssued(
        owner: 'user-a',
        issuedReference: const AdRewardReference(
          type: AdRewardReferenceType.internalImpression,
          id: impressionId,
        ),
        persist: (_, _) async {},
      );
      var callbacks = 0;
      final flow = InternalShortformViewFlow(
        session: session,
        currentOwner: () => 'user-a',
        invokeCallback: () async {
          callbacks++;
          return {
            'ok': true,
            'reward_added': 1,
            'impression_id': impressionId,
            'new_bonus': 7,
          };
        },
        parse: InternalShortformViewResponse.fromJson,
      );
      expect((await flow.report()).impressionId, impressionId);
      expect(callbacks, 1);

      final mismatch = InternalShortformViewFlow(
        session: session,
        currentOwner: () => 'user-a',
        invokeCallback: () async {
          callbacks++;
          return {
            'ok': true,
            'reward_added': 1,
            'impression_id': '00000000-0000-4000-8000-000000000403',
            'new_bonus': 7,
          };
        },
        parse: InternalShortformViewResponse.fromJson,
      );
      await expectLater(mismatch.report(), throwsFormatException);
      expect(session.reference!.id, impressionId);
      expect(callbacks, 2);
    },
  );

  test(
    'expired view token invokes callback once and retains issued reference',
    () async {
      final session = InternalShortformRewardSession();
      await session.bindIssued(
        owner: 'user-a',
        issuedReference: const AdRewardReference(
          type: AdRewardReferenceType.internalImpression,
          id: impressionId,
        ),
        persist: (_, _) async {},
      );
      var callbacks = 0;
      final flow = InternalShortformViewFlow(
        session: session,
        currentOwner: () => 'user-a',
        invokeCallback: () async {
          callbacks++;
          throw StateError('view token expired');
        },
        parse: InternalShortformViewResponse.fromJson,
      );
      await expectLater(flow.report(), throwsStateError);
      expect(callbacks, 1);
      expect(session.reference!.id, impressionId);
    },
  );

  for (final scenario in <(String, String?)>[
    ('owner mismatch', 'user-b'),
    ('null owner', null),
  ]) {
    test(
      '${scenario.$1} rejects before callback and retains issued reference',
      () async {
        final session = InternalShortformRewardSession();
        await session.bindIssued(
          owner: 'user-a',
          issuedReference: const AdRewardReference(
            type: AdRewardReferenceType.internalImpression,
            id: impressionId,
          ),
          persist: (_, _) async {},
        );
        var callbacks = 0;
        final flow = InternalShortformViewFlow(
          session: session,
          currentOwner: () => scenario.$2,
          invokeCallback: () async {
            callbacks++;
            return {
              'ok': true,
              'reward_added': 1,
              'impression_id': impressionId,
              'new_bonus': 7,
            };
          },
          parse: InternalShortformViewResponse.fromJson,
        );

        await expectLater(flow.report(), throwsStateError);
        expect(callbacks, 0);
        expect(session.reference!.id, impressionId);
        expect(session.ownerUserId, 'user-a');
      },
    );
  }
}
