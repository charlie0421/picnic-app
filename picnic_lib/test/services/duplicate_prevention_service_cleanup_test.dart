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

  group('cleanupExpiredData - expired data removal', () {
    testWidgets('removes expired data after real delay', (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');
      service.registerAuthenticationStart('product-1', 'user-1');
      service.registerBackgroundPurchase('product-1', 'user-1');

      // Wait real time for all 300ms periods to expire
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 400));
      });

      service.cleanupExpiredData();

      // After cleanup + expiry, validate should pass (no cooldown in _purchaseAttempts)
      final result = await tester.runAsync(() async {
        return await service.validatePurchaseAttempt('product-1', 'user-1');
      });

      expect(result!.allowed, isTrue);
    });

    testWidgets('does not remove non-expired data', (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');

      // Don't wait - data should still be valid
      service.cleanupExpiredData();

      // The purchase attempt was just registered, cooldown should still block
      final result = await tester.runAsync(() async {
        return await service.validatePurchaseAttempt('product-1', 'user-1');
      });

      expect(result!.allowed, isFalse);
      expect(result.type, PurchaseDenyType.cooldown);
    });

    testWidgets('handles mixed expired and non-expired data', (tester) async {
      final service = await createService(tester);

      // Register for product-1 first
      service.registerPurchaseAttempt('product-1', 'user-1');
      service.registerAuthenticationStart('product-1', 'user-1');

      // Wait for expiration
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 400));
      });

      // Register for product-2 (fresh, not expired)
      service.registerPurchaseAttempt('product-2', 'user-1');

      service.cleanupExpiredData();

      // product-1 should be allowed (expired and cleaned up)
      final result1 = await tester.runAsync(() async {
        return await service.validatePurchaseAttempt('product-1', 'user-1');
      });
      expect(result1!.allowed, isTrue);

      // product-2 should still be blocked (not expired)
      final result2 = await tester.runAsync(() async {
        return await service.validatePurchaseAttempt('product-2', 'user-1');
      });
      expect(result2!.allowed, isFalse);
      expect(result2.type, PurchaseDenyType.cooldown);
      // reason 은 `PurchaseService.initiatePurchase` 의 결과 맵을 통해 그대로
      // 다이얼로그에 올라간다. 한국어 문장('너무 빠른 연속 클릭입니다.')이던
      // 동안 로케일과 무관하게 한국어 오류가 노출됐다.
      expect(result2.reason, PurchaseConstants.errInProgress,
          reason: 'reason 은 arb 로 매핑될 에러 코드여야 한다');
      expect(RegExp(r'[가-힣]').hasMatch(result2.reason!), isFalse);
    });
  });

  group('validatePurchaseAttempt - cooldown after expiration', () {
    testWidgets('allows purchase after cooldown period expires',
        (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');

      // Wait real time for cooldownPeriod (300ms) to expire
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 400));
      });

      final result = await tester.runAsync(() async {
        return await service.validatePurchaseAttempt('product-1', 'user-1');
      });
      expect(result!.allowed, isTrue);
    });
  });

  group('hasUserRequestedArtist - error handling', () {
    testWidgets('returns false when no matching data found', (tester) async {
      setupMockSupabase({
        'vote_item_request_users': <Map<String, dynamic>>[],
      });

      final service = await createService(tester);

      final result = await tester.runAsync(() async {
        return await service.hasUserRequestedArtist(
          voteId: 999,
          artistId: 999,
          userId: 'non-existent-user',
        );
      });

      expect(result, isFalse);
    });
  });

  group('completePurchase - success vs failure paths', () {
    testWidgets('success clears authentication and background state',
        (tester) async {
      final service = await createService(tester);

      await tester.runAsync(() async {
        service.registerPurchaseAttempt('product-1', 'user-1');
        service.registerAuthenticationStart('product-1', 'user-1');
        service.registerBackgroundPurchase('product-1', 'user-1');
        // Let fire-and-forget storage writes complete
        await Future.delayed(const Duration(milliseconds: 200));
      });

      // Verify data was saved
      final prefsBefore = await SharedPreferences.getInstance();
      expect(
        prefsBefore.getInt(
            '${PurchaseConstants.lastPurchaseAttemptKey}product-1_user-1'),
        isNotNull,
      );

      await tester.runAsync(() async {
        service.completePurchase('product-1', 'user-1', success: true);
        // Let fire-and-forget storage clear complete
        await Future.delayed(const Duration(milliseconds: 200));
      });

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(
            '${PurchaseConstants.lastPurchaseAttemptKey}product-1_user-1'),
        isNull,
      );
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
    });

    testWidgets('failure still clears storage', (tester) async {
      final service = await createService(tester);

      await tester.runAsync(() async {
        service.registerPurchaseAttempt('product-1', 'user-1');
        service.registerAuthenticationStart('product-1', 'user-1');
        await Future.delayed(const Duration(milliseconds: 200));
      });

      await tester.runAsync(() async {
        service.completePurchase('product-1', 'user-1', success: false);
        await Future.delayed(const Duration(milliseconds: 200));
      });

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(
            '${PurchaseConstants.lastPurchaseAttemptKey}product-1_user-1'),
        isNull,
      );
    });
  });

  group('handlePurchaseTimeout', () {
    testWidgets('clears processing and auth state, registers background',
        (tester) async {
      final service = await createService(tester);

      service.registerPurchaseAttempt('product-1', 'user-1');
      service.registerAuthenticationStart('product-1', 'user-1');

      service.handlePurchaseTimeout('product-1', 'user-1');
      await tester.pump(const Duration(milliseconds: 100));

      final prefs = await SharedPreferences.getInstance();
      final key =
          '${PurchaseConstants.backgroundPurchaseKey}product-1_user-1';
      expect(prefs.getInt(key), isNotNull);
    });

    testWidgets('timeout on unregistered purchase does not crash',
        (tester) async {
      final service = await createService(tester);

      // Should not throw
      service.handlePurchaseTimeout('never-registered', 'user-1');
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('cache operations', () {
    testWidgets('clearCache followed by hasUserRequestedVote re-fetches',
        (tester) async {
      setupMockSupabase({
        'vote_item_request_users': [
          {'id': 1, 'vote_id': 1, 'artist_id': 0, 'user_id': 'user-1'},
        ],
      });

      final service = await createService(tester);

      final result1 = await tester.runAsync(() async {
        return await service.hasUserRequestedVote(1, 'user-1');
      });
      expect(result1, isTrue);

      service.clearCache();

      final result2 = await tester.runAsync(() async {
        return await service.hasUserRequestedVote(1, 'user-1');
      });
      expect(result2, isTrue);
    });

    testWidgets('invalidateCache for non-existent key is safe',
        (tester) async {
      final service = await createService(tester);
      service.invalidateCache(999, 'non-existent');
    });
  });
}
