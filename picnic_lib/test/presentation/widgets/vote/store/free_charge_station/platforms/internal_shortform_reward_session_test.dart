import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/internal_shortform_reward_session.dart';

void main() {
  const reference = AdRewardReference(
    type: AdRewardReferenceType.internalImpression,
    id: '00000000-0000-4000-8000-000000000402',
  );
  const response = InternalShortformViewResponse(
    ok: true,
    rewardAdded: 3,
    impressionId: '00000000-0000-4000-8000-000000000402',
    newBonus: null,
  );

  test(
    'does not expose issued reference until durable persist completes',
    () async {
      final session = InternalShortformRewardSession();
      final gate = Completer<void>();
      final binding = session.bindIssued(
        owner: 'user-a',
        issuedReference: reference,
        persist: (_, _) => gate.future,
      );
      expect(session.reference, isNull);
      gate.complete();
      await binding;
      expect(session.reference, reference);
    },
  );

  test(
    'callback loss retains reference and owner/reference mismatch fails',
    () async {
      final session = InternalShortformRewardSession();
      await session.bindIssued(
        owner: 'user-a',
        issuedReference: reference,
        persist: (_, _) async {},
      );
      expect(
        () => session.validateCallback(
          currentOwner: 'user-b',
          response: response,
        ),
        throwsStateError,
      );
      expect(session.reference, reference);
      expect(
        () => session.validateCallback(
          currentOwner: 'user-a',
          response: response.copyWith(
            impressionId: '00000000-0000-4000-8000-000000000403',
          ),
        ),
        throwsFormatException,
      );
      session.validateCallback(currentOwner: 'user-a', response: response);
    },
  );
}
