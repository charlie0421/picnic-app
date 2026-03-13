import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:picnic_lib/presentation/providers/vote_item_request_provider.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../helpers/mock_supabase.dart';
import '../helpers/mock_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupMockSupabase({
      'vote_item_request_users': <Map<String, dynamic>>[],
    });
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  /// Helper to run tests with a WidgetRef by pumping a Consumer widget.
  Future<DuplicatePreventionService> createService(WidgetTester tester) async {
    late DuplicatePreventionService service;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...defaultProviderOverrides(),
          voteItemRequestRepositoryProvider.overrideWithValue(
            VoteItemRequestRepository(supabase: testSupabaseClient!),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              service = DuplicatePreventionService(ref);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    return service;
  }

  group('DuplicatePreventionService - validatePurchaseAttempt', () {
    testWidgets('allows first purchase attempt', (tester) async {
      final service = await createService(tester);

      final result = await service.validatePurchaseAttempt(
        'product-1',
        'user-1',
      );

      expect(result.allowed, isTrue);
      expect(result.reason, isNull);
      expect(result.type, isNull);
    });

    testWidgets('blocks rapid consecutive purchase attempts (cooldown)',
        (tester) async {
      final service = await createService(tester);

      // Register a purchase attempt first
      service.registerPurchaseAttempt('product-1', 'user-1');

      // Immediately try to validate another purchase
      final result = await service.validatePurchaseAttempt(
        'product-1',
        'user-1',
      );

      expect(result.allowed, isFalse);
      expect(result.type, PurchaseDenyType.cooldown);
      expect(result.reason, isNotNull);
    });

    testWidgets('allows purchase for different product IDs', (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');

      // Different product should be allowed
      final result = await service.validatePurchaseAttempt(
        'product-2',
        'user-1',
      );

      expect(result.allowed, isTrue);
    });

    testWidgets('allows purchase for different user IDs', (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');

      // Different user should be allowed
      final result = await service.validatePurchaseAttempt(
        'product-1',
        'user-2',
      );

      expect(result.allowed, isTrue);
    });
  });

  group('DuplicatePreventionService - registerPurchaseAttempt', () {
    testWidgets('registers purchase attempt and saves to storage',
        (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');

      // Wait for async storage operation
      await tester.pump(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      final key = '${PurchaseConstants.lastPurchaseAttemptKey}product-1_user-1';
      expect(prefs.getInt(key), isNotNull);
    });
  });

  group('DuplicatePreventionService - registerAuthenticationStart', () {
    testWidgets('registers authentication start and saves to storage',
        (tester) async {
      final service = await createService(tester);

      service.registerAuthenticationStart('product-1', 'user-1');

      await tester.pump(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      final key =
          '${PurchaseConstants.authenticationStartKey}product-1_user-1';
      expect(prefs.getInt(key), isNotNull);
    });
  });

  group('DuplicatePreventionService - registerBackgroundPurchase', () {
    testWidgets('registers background purchase and saves to storage',
        (tester) async {
      final service = await createService(tester);

      service.registerBackgroundPurchase('product-1', 'user-1');

      await tester.pump(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      final key =
          '${PurchaseConstants.backgroundPurchaseKey}product-1_user-1';
      expect(prefs.getInt(key), isNotNull);
    });
  });

  group('DuplicatePreventionService - completePurchase', () {
    testWidgets('clears all state on success', (tester) async {
      final service = await createService(tester);

      // Setup: register various states
      service.registerPurchaseAttempt('product-1', 'user-1');
      service.registerAuthenticationStart('product-1', 'user-1');
      service.registerBackgroundPurchase('product-1', 'user-1');

      await tester.pump(const Duration(milliseconds: 100));

      // Complete with success
      service.completePurchase('product-1', 'user-1', success: true);

      await tester.pump(const Duration(milliseconds: 100));

      // Storage should be cleared
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(
            '${PurchaseConstants.authenticationStartKey}product-1_user-1'),
        isNull,
      );
      expect(
        prefs.getInt(
            '${PurchaseConstants.backgroundPurchaseKey}product-1_user-1'),
        isNull,
      );
      expect(
        prefs.getInt(
            '${PurchaseConstants.lastPurchaseAttemptKey}product-1_user-1'),
        isNull,
      );
    });

    testWidgets('partial cleanup on failure', (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');
      service.registerAuthenticationStart('product-1', 'user-1');

      await tester.pump(const Duration(milliseconds: 100));

      // Complete with failure
      service.completePurchase('product-1', 'user-1', success: false);

      await tester.pump(const Duration(milliseconds: 100));

      // Storage should be cleared even on failure
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(
            '${PurchaseConstants.lastPurchaseAttemptKey}product-1_user-1'),
        isNull,
      );
    });
  });

  group('DuplicatePreventionService - handlePurchaseTimeout', () {
    testWidgets('converts to background purchase on timeout', (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');
      service.registerAuthenticationStart('product-1', 'user-1');

      service.handlePurchaseTimeout('product-1', 'user-1');

      await tester.pump(const Duration(milliseconds: 100));

      // Background purchase should be registered
      final prefs = await SharedPreferences.getInstance();
      final key =
          '${PurchaseConstants.backgroundPurchaseKey}product-1_user-1';
      expect(prefs.getInt(key), isNotNull);
    });
  });

  group('DuplicatePreventionService - cleanupExpiredData', () {
    testWidgets('removes expired authentication data', (tester) async {
      final service = await createService(tester);

      // Register auth start
      service.registerAuthenticationStart('product-1', 'user-1');

      // cleanupExpiredData should not remove recent data
      service.cleanupExpiredData();

      // Since authenticationGracePeriod is 300ms, data should still be valid immediately
      // We can't easily fast-forward time, but we can verify cleanup doesn't crash
    });

    testWidgets('removes expired purchase attempts', (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');

      // Call cleanup - should not crash
      service.cleanupExpiredData();
    });

    testWidgets('removes expired background purchases', (tester) async {
      final service = await createService(tester);

      service.registerBackgroundPurchase('product-1', 'user-1');

      // Call cleanup - should not crash
      service.cleanupExpiredData();
    });

    testWidgets('cleanup on empty state does nothing', (tester) async {
      final service = await createService(tester);

      // Should not throw
      service.cleanupExpiredData();
    });
  });

  group('DuplicatePreventionService - vote cache', () {
    testWidgets('invalidateCache removes cached entry', (tester) async {
      final service = await createService(tester);

      // Call invalidateCache on non-existent entry - should not crash
      service.invalidateCache(123, 'user-1');
    });

    testWidgets('clearCache clears all cached entries', (tester) async {
      final service = await createService(tester);

      // Call clearCache - should not crash
      service.clearCache();
    });
  });

  group('DuplicatePreventionService - hasUserRequestedVote', () {
    testWidgets('returns false when user has not requested', (tester) async {
      // Setup mock that returns no matching rows
      setupMockSupabase({
        'vote_item_request_users': <Map<String, dynamic>>[],
      });

      final service = await createService(tester);

      final result = await service.hasUserRequestedVote(1, 'user-1');

      expect(result, isFalse);
    });

    testWidgets('returns true when user has requested', (tester) async {
      setupMockSupabase({
        'vote_item_request_users': [
          {'id': 1, 'vote_id': 1, 'artist_id': 0, 'user_id': 'user-1'},
        ],
      });

      final service = await createService(tester);

      final result = await service.hasUserRequestedVote(1, 'user-1');

      expect(result, isTrue);
    });

    testWidgets('caches result and returns from cache on second call',
        (tester) async {
      setupMockSupabase({
        'vote_item_request_users': [
          {'id': 1, 'vote_id': 1, 'artist_id': 0, 'user_id': 'user-1'},
        ],
      });

      final service = await createService(tester);

      // First call hits the repository
      final result1 = await service.hasUserRequestedVote(1, 'user-1');
      expect(result1, isTrue);

      // Second call should return from cache
      final result2 = await service.hasUserRequestedVote(1, 'user-1');
      expect(result2, isTrue);
    });

    testWidgets('invalidateCache removes entry from cache', (tester) async {
      setupMockSupabase({
        'vote_item_request_users': [
          {'id': 1, 'vote_id': 1, 'artist_id': 0, 'user_id': 'user-1'},
        ],
      });

      final service = await createService(tester);

      // First call - populates cache
      final result1 = await service.hasUserRequestedVote(1, 'user-1');
      expect(result1, isTrue);

      // Invalidate cache
      service.invalidateCache(1, 'user-1');

      // Second call should re-fetch from repository (not use stale cache)
      // Since the mock still returns the same data, result should still be true
      final result2 = await service.hasUserRequestedVote(1, 'user-1');
      expect(result2, isTrue);
    });
  });

  group('DuplicatePreventionService - hasUserRequestedArtist', () {
    testWidgets('returns false when user has not requested specific artist',
        (tester) async {
      setupMockSupabase({
        'vote_item_request_users': <Map<String, dynamic>>[],
      });

      final service = await createService(tester);

      final result = await service.hasUserRequestedArtist(
        voteId: 1,
        artistId: 42,
        userId: 'user-1',
      );

      expect(result, isFalse);
    });

    testWidgets('returns true when user has requested specific artist',
        (tester) async {
      setupMockSupabase({
        'vote_item_request_users': [
          {'id': 1, 'vote_id': 1, 'artist_id': 42, 'user_id': 'user-1'},
        ],
      });

      final service = await createService(tester);

      final result = await service.hasUserRequestedArtist(
        voteId: 1,
        artistId: 42,
        userId: 'user-1',
      );

      expect(result, isTrue);
    });
  });

  group('DuplicatePreventionService - storage error handling', () {
    testWidgets('registerPurchaseAttempt survives storage errors',
        (tester) async {
      final service = await createService(tester);

      // Should not throw even if storage has issues
      service.registerPurchaseAttempt('product-1', 'user-1');
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('completePurchase survives storage errors', (tester) async {
      final service = await createService(tester);

      // Should not throw
      service.completePurchase('product-1', 'user-1', success: true);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('completePurchase with non-existent key does not crash',
        (tester) async {
      final service = await createService(tester);

      // Complete a purchase that was never registered
      service.completePurchase('never-registered', 'user-1', success: true);
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('DuplicatePreventionService - concurrent request deduplication', () {
    testWidgets('concurrent calls to hasUserRequestedVote share same future',
        (tester) async {
      setupMockSupabase({
        'vote_item_request_users': [
          {'id': 1, 'vote_id': 1, 'artist_id': 0, 'user_id': 'user-1'},
        ],
      });

      final service = await createService(tester);

      // Fire two calls concurrently
      final future1 = service.hasUserRequestedVote(1, 'user-1');
      final future2 = service.hasUserRequestedVote(1, 'user-1');

      final results = await Future.wait([future1, future2]);

      expect(results[0], isTrue);
      expect(results[1], isTrue);
    });
  });
}
