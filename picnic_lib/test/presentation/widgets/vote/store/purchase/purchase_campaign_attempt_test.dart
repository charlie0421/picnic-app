import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_campaign_attempt.dart';

void main() {
  PurchaseCampaignAttempt attempt(String id, String product) =>
      PurchaseCampaignAttempt(
        attemptId: id,
        productId: product,
        displayedCampaign: null,
      );

  test('same product is locked while different product proceeds', () {
    final registry = PurchaseCampaignAttemptRegistry();
    expect(registry.begin(attempt('a', 'STAR100')), isTrue);
    expect(registry.begin(attempt('b', 'STAR100')), isFalse);
    expect(registry.begin(attempt('c', 'STAR500')), isTrue);
  });

  test('stale terminal callback cannot clear a newer identity', () {
    final registry = PurchaseCampaignAttemptRegistry();
    registry.begin(attempt('old', 'STAR100'));
    expect(registry.removeIfMatches('STAR100', 'old'), isTrue);
    registry.begin(attempt('new', 'STAR100'));
    expect(registry.removeIfMatches('STAR100', 'old'), isFalse);
    expect(registry['STAR100']!.attemptId, 'new');
  });

  test(
    'non-terminal path retains identity until matching terminal removal',
    () {
      final registry = PurchaseCampaignAttemptRegistry();
      registry.begin(attempt('pending', 'STAR100'));
      expect(registry['STAR100']!.attemptId, 'pending');
      expect(registry.removeIfMatches('STAR100', 'other'), isFalse);
      expect(registry.contains('STAR100'), isTrue);
      expect(registry.removeIfMatches('STAR100', 'pending'), isTrue);
    },
  );

  test('launch result removes cancel/failure but retains launched attempt', () {
    final registry = PurchaseCampaignAttemptRegistry();
    registry.begin(attempt('cancel', 'STAR100'));
    expect(
      registry.applyLaunchResult('STAR100', 'cancel', {
        'success': false,
        'wasCancelled': true,
      }),
      isTrue,
    );
    registry.begin(attempt('failure', 'STAR100'));
    expect(
      registry.applyLaunchResult('STAR100', 'failure', {
        'success': false,
        'wasCancelled': false,
      }),
      isTrue,
    );
    registry.begin(attempt('launched', 'STAR100'));
    expect(
      registry.applyLaunchResult('STAR100', 'launched', {
        'success': true,
        'wasCancelled': false,
      }),
      isFalse,
    );
    expect(registry['STAR100']!.attemptId, 'launched');
  });
}
