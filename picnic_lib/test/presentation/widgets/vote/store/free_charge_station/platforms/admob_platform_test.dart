import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';

void main() {
  test(
    'preflight returns only the signed claim token issued for the authenticated AdMob view',
    () async {
      final requested = <String>[];
      final token =
          await AdmobClaimPreflight(
            createClaim:
                ({
                  required platform,
                  required placementId,
                  required clientRequestId,
                }) async {
                  requested.add('$platform:$placementId:$clientRequestId');
                  return AdmobClaimModel(
                    reference: const AdRewardReference(
                      type: AdRewardReferenceType.admobClaim,
                      id: 'claim-admob-a',
                    ),
                    platform: 'android',
                    signedToken: 'opaque-signed-token',
                    expiresAt: DateTime.utc(2030),
                  );
                },
          ).execute(
            ownerUserId: 'user-a',
            platform: 'android',
            placementId: 'ca-app-pub-1/2',
            clientRequestId: 'request-a',
          );

      expect(requested, ['android:ca-app-pub-1/2:request-a']);
      expect(token, 'opaque-signed-token');
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
}
