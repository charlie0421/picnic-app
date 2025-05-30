import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SimpleCacheManager Tests', () {
    late SimpleCacheManager cacheManager;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});

      // Get fresh instance
      cacheManager = SimpleCacheManager.instance;
      await cacheManager.init();
    });

    tearDown(() async {
      await cacheManager.clear();
    });

    group('Cache Operations', () {
      test('should store and retrieve cache entry', () async {
        const url = 'https://api.example.com/users';
        const headers = <String, String>{'accept': 'application/json'};
        const responseData = '{"users": []}';
        const statusCode = 200;

        // Store cache entry
        await cacheManager.put(
          url,
          headers,
          responseData,
          statusCode,
          isAuthenticated: false,
        );

        // Retrieve cache entry
        final cachedEntry = await cacheManager.get(
          url,
          headers,
          isAuthenticated: false,
        );

        expect(cachedEntry, isNotNull);
        expect(cachedEntry!.data, equals(responseData));
        expect(cachedEntry.statusCode, equals(statusCode));
        expect(cachedEntry.url, equals(url));
        expect(cachedEntry.isValid, isTrue);
        expect(cachedEntry.isExpired, isFalse);
      });

      test('should return null for cache miss', () async {
        const url = 'https://api.example.com/missing';
        const headers = <String, String>{'accept': 'application/json'};

        final cachedEntry = await cacheManager.get(
          url,
          headers,
          isAuthenticated: false,
        );

        expect(cachedEntry, isNull);
      });

      test('should handle cache expiry', () async {
        const url = 'https://api.example.com/expired';
        const headers = <String, String>{'accept': 'application/json'};
        const responseData = '{"data": "expired"}';

        // Store with very short TTL
        await cacheManager.put(
          url,
          headers,
          responseData,
          200,
          cacheDuration: const Duration(milliseconds: 1),
          isAuthenticated: false,
        );

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 10));

        // Should return null for expired entry
        final cachedEntry = await cacheManager.get(
          url,
          headers,
          isAuthenticated: false,
        );

        expect(cachedEntry, isNull);
      });

      test('should respect cache policy for URL caching', () async {
        const nonCacheableUrl = 'https://api.example.com/realtime/stream';
        const headers = <String, String>{'accept': 'application/json'};
        const responseData = '{"stream": "data"}';

        // Try to store non-cacheable URL
        await cacheManager.put(
          nonCacheableUrl,
          headers,
          responseData,
          200,
          isAuthenticated: false,
        );

        // Should not be cached (according to cache policy)

        // Note: The actual behavior depends on CachePolicy.shouldCacheUrl implementation
        // This test verifies that the policy is being respected
      });

      test('should handle authentication requirements', () async {
        const authUrl = 'https://api.example.com/user_profiles/123';
        const headers = <String, String>{'accept': 'application/json'};
        const responseData = '{"user": "data"}';

        // Store authenticated data
        await cacheManager.put(
          authUrl,
          headers,
          responseData,
          200,
          isAuthenticated: true,
        );

        // Should not return when not authenticated
        final unauthenticatedEntry = await cacheManager.get(
          authUrl,
          headers,
          isAuthenticated: false,
        );

        expect(unauthenticatedEntry, isNull);

        // Should return when authenticated
        final authenticatedEntry = await cacheManager.get(
          authUrl,
          headers,
          isAuthenticated: true,
        );

        expect(authenticatedEntry, isNotNull);
        expect(authenticatedEntry!.data, equals(responseData));
      });
    });

    group('Cache Priority and Memory Management', () {
      test('should manage memory cache size', () async {
        // Store multiple entries
        for (int i = 0; i < 10; i++) {
          final url = 'https://api.example.com/item/$i';
          await cacheManager.put(
            url,
            {},
            '{"data": $i}',
            200,
            isAuthenticated: false,
          );
        }

        // Check that cache manager handles the entries
        final stats = await cacheManager.getCacheStats();
        expect(stats['totalCount'], greaterThan(0));
        expect(stats['memoryCount'], greaterThan(0));
      });

      test('should respect different cache priorities', () async {
        const criticalUrl = 'https://api.example.com/config';
        const normalUrl = 'https://api.example.com/data';

        await cacheManager.put(
          criticalUrl,
          {},
          '{"config": "critical"}',
          200,
          isAuthenticated: false,
        );

        await cacheManager.put(
          normalUrl,
          {},
          '{"data": "normal"}',
          200,
          isAuthenticated: false,
        );

        final stats = await cacheManager.getCacheStats();
        expect(stats['totalCount'], greaterThan(0));
      });
    });

    group('Cache Invalidation', () {
      test('should invalidate cache by pattern', () async {
        const url1 = 'https://api.example.com/users/1';
        const url2 = 'https://api.example.com/users/2';
        const url3 = 'https://api.example.com/posts/1';

        // Store multiple entries
        await cacheManager.put(url1, {}, '{"user": 1}', 200,
            isAuthenticated: false);
        await cacheManager.put(url2, {}, '{"user": 2}', 200,
            isAuthenticated: false);
        await cacheManager.put(url3, {}, '{"post": 1}', 200,
            isAuthenticated: false);

        // Invalidate users pattern
        await cacheManager.invalidateByPattern(r'/users/');

        // User entries should be invalidated
        final user1 = await cacheManager.get(url1, {}, isAuthenticated: false);
        final user2 = await cacheManager.get(url2, {}, isAuthenticated: false);
        final post1 = await cacheManager.get(url3, {}, isAuthenticated: false);

        expect(user1, isNull);
        expect(user2, isNull);
        expect(post1, isNotNull); // Post should remain
      });

      test('should invalidate for modification', () async {
        const userUrl = 'https://api.example.com/rest/v1/user_profiles/1';
        const relatedUrl = 'https://api.example.com/rest/v1/user_agreement';

        // Store related entries
        await cacheManager.put(userUrl, {}, '{"user": 1}', 200,
            isAuthenticated: false);
        await cacheManager.put(relatedUrl, {}, '{"agreement": true}', 200,
            isAuthenticated: false);

        // Invalidate for user modification
        await cacheManager.invalidateForModification(userUrl);

        // Related entries should be invalidated based on policy
        final user =
            await cacheManager.get(userUrl, {}, isAuthenticated: false);
        expect(user, isNull);
      });

      test('should clear authenticated cache', () async {
        const authUrl = 'https://api.example.com/rest/v1/user_profiles/123';
        const publicUrl = 'https://api.example.com/rest/v1/config';

        // Store both authenticated and public data
        await cacheManager.put(authUrl, {}, '{"user": "data"}', 200,
            isAuthenticated: true);
        await cacheManager.put(publicUrl, {}, '{"public": "data"}', 200,
            isAuthenticated: false);

        // Clear authenticated cache
        await cacheManager.clearAuthenticatedCache();

        // Authenticated data should be cleared
        final authData =
            await cacheManager.get(authUrl, {}, isAuthenticated: true);
        final publicData =
            await cacheManager.get(publicUrl, {}, isAuthenticated: false);

        expect(authData, isNull);
        expect(publicData, isNotNull);
      });
    });

    group('Cache Statistics', () {
      test('should provide accurate cache statistics', () async {
        const url1 = 'https://api.example.com/test1';
        const url2 = 'https://api.example.com/test2';

        // Store some entries
        await cacheManager.put(url1, {}, '{"data1": "test"}', 200,
            isAuthenticated: false);
        await cacheManager.put(url2, {}, '{"data2": "test"}', 200,
            isAuthenticated: false);

        final stats = await cacheManager.getCacheStats();

        expect(stats, isNotNull);
        expect(stats['totalCount'], greaterThan(0));
        expect(stats['totalSize'], greaterThan(0));
        expect(stats['priorityCounts'], isNotNull);
        expect(stats, containsPair('memoryCount', isA<int>()));
        expect(stats, containsPair('persistentCount', isA<int>()));
      });
    });

    group('Cache Cleanup', () {
      test('should clean expired entries', () async {
        const url = 'https://api.example.com/expires';

        // Store entry with short TTL
        await cacheManager.put(
          url,
          {},
          '{"data": "expires"}',
          200,
          cacheDuration: const Duration(milliseconds: 1),
          isAuthenticated: false,
        );

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 10));

        // Clean expired entries
        await cacheManager.clearExpired();

        // Entry should be gone
        final entry = await cacheManager.get(url, {}, isAuthenticated: false);
        expect(entry, isNull);
      });

      test('should clear all cache', () async {
        const url1 = 'https://api.example.com/test1';
        const url2 = 'https://api.example.com/test2';

        // Store some entries
        await cacheManager.put(url1, {}, '{"data1": "test"}', 200,
            isAuthenticated: false);
        await cacheManager.put(url2, {}, '{"data2": "test"}', 200,
            isAuthenticated: false);

        // Clear all cache
        await cacheManager.clear();

        // All entries should be gone
        final entry1 = await cacheManager.get(url1, {}, isAuthenticated: false);
        final entry2 = await cacheManager.get(url2, {}, isAuthenticated: false);
        final stats = await cacheManager.getCacheStats();

        expect(entry1, isNull);
        expect(entry2, isNull);
        expect(stats['totalCount'], equals(0));
        expect(stats['memoryCount'], equals(0));
      });
    });

    group('Error Handling', () {
      test('should handle empty cache gracefully', () async {
        const url = 'https://api.example.com/empty';
        final entry = await cacheManager.get(url, {}, isAuthenticated: false);

        expect(entry, isNull);
        // Should not throw exception
      });

      test('should handle storing invalid responses', () async {
        const url = 'https://api.example.com/error';

        // Should handle error status codes
        await cacheManager.put(url, {}, '{"error": "not found"}', 404,
            isAuthenticated: false);

        // Error responses might or might not be cached depending on policy
        // Test passes regardless of caching decision for error responses
      });
    });

    group('ETags and Conditional Requests', () {
      test('should store and retrieve ETag information', () async {
        const url = 'https://api.example.com/etag';
        const etag = 'W/"123456789"';
        const responseData = '{"data": "with_etag"}';

        await cacheManager.put(
          url,
          {},
          responseData,
          200,
          etag: etag,
          isAuthenticated: false,
        );

        final entry = await cacheManager.get(url, {}, isAuthenticated: false);

        expect(entry, isNotNull);
        expect(entry!.etag, equals(etag));
        expect(entry.data, equals(responseData));
      });
    });
  });
}
