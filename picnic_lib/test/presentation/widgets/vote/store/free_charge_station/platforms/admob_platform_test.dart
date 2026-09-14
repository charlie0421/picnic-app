import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';

void main() {
  const reference = AdRewardReference(
    type: AdRewardReferenceType.admobClaim,
    id: 'claim-admob-a',
  );

  AdmobClaimModel makeClaim({String token = 'opaque-signed-token'}) =>
      AdmobClaimModel(
        reference: reference,
        platform: 'android',
        signedToken: token,
        expiresAt: DateTime.utc(2030),
      );

  test(
    'preflight returns the signed token and the claim reference issued for the authenticated AdMob view',
    () async {
      final requested = <String>[];
      final result =
          await AdmobClaimPreflight(
            createClaim:
                ({
                  required platform,
                  required placementId,
                  required clientRequestId,
                }) async {
                  requested.add('$platform:$placementId:$clientRequestId');
                  return makeClaim();
                },
            persist: (_, _) async {},
          ).execute(
            ownerUserId: 'user-a',
            platform: 'android',
            placementId: 'ca-app-pub-1/2',
            clientRequestId: 'request-a',
          );

      expect(requested, ['android:ca-app-pub-1/2:request-a']);
      expect(result.signedToken, 'opaque-signed-token');
      expect(result.reference, reference);
    },
  );

  test(
    'preflight persists the claim reference for the owner before the ad can be shown',
    () async {
      // Pangle 과 같은 계약: 서버가 보상을 확정하는 사이 앱이 죽어도 ack 톰스톤과
      // 복구 경로가 같은 참조를 찾을 수 있어야 한다.
      final persisted = <String>[];
      await AdmobClaimPreflight(
        createClaim:
            ({
              required platform,
              required placementId,
              required clientRequestId,
            }) async => makeClaim(),
        persist: (owner, value) async {
          persisted.add('$owner:${value.type.wireValue}:${value.id}');
        },
      ).execute(
        ownerUserId: 'user-a',
        platform: 'ios',
        placementId: 'ca-app-pub-1/2',
        clientRequestId: 'request-a',
      );

      expect(persisted, ['user-a:ADMOB_CLAIM:claim-admob-a']);
    },
  );

  test(
    'preflight propagates a persist failure so the ad is not shown',
    () async {
      final preflight = AdmobClaimPreflight(
        createClaim:
            ({
              required platform,
              required placementId,
              required clientRequestId,
            }) async => makeClaim(),
        persist: (_, _) =>
            Future<void>.error(StateError('storage unavailable')),
      );

      await expectLater(
        preflight.execute(
          ownerUserId: 'user-a',
          platform: 'ios',
          placementId: 'ca-app-pub-1/2',
          clientRequestId: 'request-a',
        ),
        throwsStateError,
      );
    },
  );

  test(
    'preflight rejects an unavailable claim before an ad can be shown',
    () async {
      final preflight = AdmobClaimPreflight(
        createClaim:
            ({
              required platform,
              required placementId,
              required clientRequestId,
            }) =>
                Future<AdmobClaimModel>.error(StateError('claim unavailable')),
        persist: (_, _) async {},
      );

      await expectLater(
        preflight.execute(
          ownerUserId: 'user-a',
          platform: 'ios',
          placementId: 'ca-app-pub-1/2',
          clientRequestId: 'request-b',
        ),
        throwsStateError,
      );
    },
  );

  test('preflight rejects a claim without a signed token', () async {
    final persisted = <AdRewardReference>[];
    final preflight = AdmobClaimPreflight(
      createClaim:
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) async => makeClaim(token: ''),
      persist: (_, value) async => persisted.add(value),
    );

    await expectLater(
      preflight.execute(
        ownerUserId: 'user-a',
        platform: 'ios',
        placementId: 'ca-app-pub-1/2',
        clientRequestId: 'request-c',
      ),
      throwsFormatException,
    );
    // 토큰 없는 클레임은 SSV 가 붙을 수 없어 절대 GRANTED 가 되지 않는다 —
    // 폴링·복구 대상으로 남기지 않는다.
    expect(persisted, isEmpty);
  });

  group('AdmobAdSourceSummary', () {
    test('describes a missing response as unknown', () {
      final summary = AdmobAdSourceSummary.fromResponseInfo(null);
      expect(summary.isMediated, isNull);
      expect(summary.describe(), 'ad_source=unknown');
    });

    test('flags third-party mediation adapters', () {
      // Google 은 AdMob 네트워크가 채운 광고에만 SSV 를 보낸다는 가설을 다음
      // 테스트플라이트에서 가리기 위한 진단 값이다.
      final summary = AdmobAdSourceSummary(
        adSourceName: 'Meta Audience Network',
        adSourceId: '10568273599589928883',
        adapterClassName: 'com.google.ads.mediation.facebook.FacebookAdapter',
        mediationAdapterClassName:
            'com.google.ads.mediation.facebook.FacebookAdapter',
        responseId: 'resp-1',
      );
      expect(summary.isMediated, isTrue);
      expect(
        summary.describe(),
        'ad_source=Meta Audience Network(10568273599589928883) '
        'adapter=com.google.ads.mediation.facebook.FacebookAdapter '
        'mediated=true response=resp-1',
      );
    });

    test('recognises the AdMob network as first party', () {
      final summary = AdmobAdSourceSummary(
        adSourceName: 'AdMob Network',
        adSourceId: '5450213213286189855',
        adapterClassName: 'com.google.ads.mediation.admob.AdMobAdapter',
        mediationAdapterClassName:
            'com.google.ads.mediation.admob.AdMobAdapter',
        responseId: null,
      );
      expect(summary.isMediated, isFalse);
      expect(summary.describe(), contains('mediated=false'));
    });
  });
}
