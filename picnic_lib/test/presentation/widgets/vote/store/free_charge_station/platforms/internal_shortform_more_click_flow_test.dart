import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_flow.dart';

/// The admin campaign report counts `more_clicks` from
/// `ad_impressions.more_completed_at`, which only the
/// `callback-ad-shortform-more` endpoint writes. The app never called it, so
/// the column stayed NULL across 2.2M production impressions.
///
/// The click is recorded on a best-effort basis: it is a statistics write that
/// happens while the user is already on their way to the advertiser, so it must
/// never throw into the ad flow or hold up the view reward.
void main() {
  const impressionId = '00000000-0000-4000-8000-000000000402';

  Map<String, dynamic> issueBody({Map<String, dynamic>? tokens}) => {
    'impression_id': impressionId,
    'ad': {'video_url': 'ads/video.mp4', 'cta_url': 'https://cta'},
    'tokens': tokens ?? {'view_token': 'view', 'more_token': 'more'},
  };

  Future<InternalShortformIssueResult> issue(Map<String, dynamic> body) =>
      InternalShortformIssueFlow(
        currentOwner: () => 'user-a',
        invokeIssue: () async => body,
        persist: (_, _) async {},
        rewriteVideoUrl: (_) => 'https://cdn/video.m3u8',
      ).issue();

  group('issue parsing', () {
    test('keeps the more token the CTA click callback needs', () async {
      final result = await issue(issueBody());
      expect(result.moreToken, 'more');
    });

    test('a missing more token is null, not a failure', () async {
      final result = await issue(
        issueBody(tokens: {'view_token': 'view'}),
      );
      // view_token is what makes the ad playable; the more token only feeds
      // click stats, so an issue response without it must still play.
      expect(result.moreToken, isNull);
      expect(result.viewToken, 'view');
    });

    test('a blank or non-string more token is null', () async {
      expect(
        (await issue(issueBody(tokens: {'view_token': 'v', 'more_token': ''})))
            .moreToken,
        isNull,
      );
      expect(
        (await issue(issueBody(tokens: {'view_token': 'v', 'more_token': 7})))
            .moreToken,
        isNull,
      );
    });
  });

  group('InternalShortformMoreClickFlow', () {
    test('posts the more token and reports success', () async {
      final bodies = <String>[];
      final reported = await InternalShortformMoreClickFlow(
        moreToken: 'more',
        issuedOwner: 'user-a',
        currentOwner: () => 'user-a',
        invokeCallback: (token) async {
          bodies.add(token);
          return {'ok': true, 'impression_id': impressionId, 'recorded': true};
        },
      ).report();

      expect(reported, isTrue);
      expect(bodies, ['more']);
    });

    test('does not call the server without a more token', () async {
      var calls = 0;
      final reported = await InternalShortformMoreClickFlow(
        moreToken: null,
        issuedOwner: 'user-a',
        currentOwner: () => 'user-a',
        invokeCallback: (_) async {
          calls++;
          return null;
        },
      ).report();

      expect(reported, isFalse);
      expect(calls, 0);
    });

    test('does not post a token that belongs to a signed-out owner', () async {
      var calls = 0;
      final reported = await InternalShortformMoreClickFlow(
        moreToken: 'more',
        issuedOwner: 'user-a',
        currentOwner: () => 'user-b',
        invokeCallback: (_) async {
          calls++;
          return null;
        },
      ).report();

      expect(reported, isFalse);
      expect(calls, 0);
    });

    test('swallows a server failure and hands it to onError', () async {
      Object? seen;
      final reported = await InternalShortformMoreClickFlow(
        moreToken: 'more',
        issuedOwner: 'user-a',
        currentOwner: () => 'user-a',
        invokeCallback: (_) async => throw StateError('edge down'),
        onError: (error, _) => seen = error,
      ).report();

      // A stats write must never surface as an error dialog or block the CTA.
      expect(reported, isFalse);
      expect(seen, isStateError);
    });

    test('a synchronous throw is caught too', () async {
      Object? seen;
      final reported = await InternalShortformMoreClickFlow(
        moreToken: 'more',
        issuedOwner: 'user-a',
        currentOwner: () => 'user-a',
        invokeCallback: (_) => throw StateError('disposed'),
        onError: (error, _) => seen = error,
      ).report();

      expect(reported, isFalse);
      expect(seen, isStateError);
    });
  });
}
