import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';

class InternalShortformRewardSession {
  AdRewardReference? reference;
  String? ownerUserId;

  Future<void> bindIssued({
    required String owner,
    required AdRewardReference issuedReference,
    required Future<void> Function(String, AdRewardReference) persist,
  }) async {
    await persist(owner, issuedReference);
    reference = issuedReference;
    ownerUserId = owner;
  }

  void validateCallback({
    required String? currentOwner,
    required InternalShortformViewResponse response,
  }) {
    final issued =
        reference ??
        (throw StateError('No issued impression for view callback'));
    final owner =
        ownerUserId ?? (throw StateError('No owner for issued impression'));
    if (currentOwner != owner) {
      throw StateError('Ad reward owner changed before view callback');
    }
    if (response.impressionId != issued.id) {
      throw const FormatException(
        'callback impression_id does not match issued impression',
      );
    }
  }
}
