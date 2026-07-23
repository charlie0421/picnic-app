import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart';

void main() {
  test(
    'preflight creates, persists, subscribes, then loads signed media extra',
    () async {
      final calls = <String>[];
      final signals = StreamController<void>.broadcast();
      final reference = AdRewardReference(
        type: AdRewardReferenceType.pangleClaim,
        id: 'claim-a',
      );
      final claim = PangleClaimModel(
        reference: reference,
        platform: 'android',
        signedToken: 'signed-token',
        expiresAt: DateTime.utc(2030),
      );
      final result =
          await PangleClaimPreflight(
            createClaim:
                ({
                  required platform,
                  required placementId,
                  required clientRequestId,
                }) async {
                  calls.add('create:$platform:$placementId:$clientRequestId');
                  return claim;
                },
            persist: (owner, value) async =>
                calls.add('persist:$owner:${value.id}'),
            pollingSignals: signals.stream,
            poll: (owner, value) async => calls.add('poll:$owner:${value.id}'),
            load: (placement, mediaExtra) async {
              calls.add('load:$placement:$mediaExtra');
              return true;
            },
          ).execute(
            ownerUserId: 'user-a',
            platform: 'android',
            placementId: 'rewarded-placement',
            clientRequestId: 'request-a',
          );
      expect(calls, [
        'create:android:rewarded-placement:request-a',
        'persist:user-a:claim-a',
        'load:rewarded-placement:user-a,android,v2.signed-token',
      ]);
      signals.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(calls.last, 'poll:user-a:claim-a');
      await result.subscription.cancel();
      await signals.close();
    },
  );
}
