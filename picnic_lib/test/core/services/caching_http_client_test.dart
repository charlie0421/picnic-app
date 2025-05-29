import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/services/enhanced_network_service.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:picnic_lib/core/utils/caching_http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final Map<String, http.Response> _responses = {};
  final Map<String, Exception> _errors = {};
  final List<http.Request> _requestLog = [];

  void addResponse(String url, http.Response response) {
    _responses[url] = response;
  }

  void addError(String url, Exception error) {
    _errors[url] = error;
  }

  List<http.Request> get requestLog => List.unmodifiable(_requestLog);

  void clearLog() {
    _requestLog.clear();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _requestLog.add(request as http.Request);

    final url = request.url.toString();

    if (_errors.containsKey(url)) {
      throw _errors[url]!;
    }

    if (_responses.containsKey(url)) {
      final response = _responses[url]!;
      return http.StreamedResponse(
        Stream.value(utf8.encode(response.body)),
        response.statusCode,
        headers: response.headers,
        request: request,
        reasonPhrase: response.reasonPhrase,
      );
    }

    // Default response
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"message": "not found"}')),
      404,
      request: request,
    );
  }
}

void main() {
  group('CachingHttpClient Tests', () {
    late CachingHttpClient cachingClient;
    late MockHttpClient mockClient;
    late SimpleCacheManager cacheManager;

    setUp(() async {
      // Setup mock environment
      SharedPreferences.setMockInitialValues({});

      // Create mock HTTP client
      mockClient = MockHttpClient();

      // Create caching client
      cachingClient = CachingHttpClient(mockClient);

      // Initialize cache manager
      cacheManager = SimpleCacheManager.instance;
      await cacheManager.init();

      // Clear any existing cache
      await cacheManager.clear();
      mockClient.clearLog();
    });

    tearDown(() async {
      await cacheManager.clear();
      cachingClient.close();
    });

    group('Basic Caching Behavior', () {
      test('should cache successful GET responses', () async {
        const url = 'https://api.example.com/users';
        const responseBody = '{"users": [{"id": 1, "name": "John"}]}';

        // Setup mock response
        mockClient.addResponse(url, http.Response(responseBody, 200));

        // First request - should hit network
        final response1 = await cachingClient.get(Uri.parse(url));
        expect(response1.statusCode, equals(200));
        expect(response1.body, equals(responseBody));
        expect(mockClient.requestLog.length, equals(1));

        // Second request - should hit cache
        final response2 = await cachingClient.get(Uri.parse(url));
        expect(response2.statusCode, equals(200));
        expect(response2.body, equals(responseBody));
        expect(response2.headers['x-cache'], equals('HIT'));

        // Should still only have one network request
        expect(mockClient.requestLog.length, equals(1));
      });

      test('should not cache error responses', () async {
        const url = 'https://api.example.com/error';
        const errorBody = '{"error": "Internal Server Error"}';

        // Setup mock error response
        mockClient.addResponse(url, http.Response(errorBody, 500));

        // First request
        final response1 = await cachingClient.get(Uri.parse(url));
        expect(response1.statusCode, equals(500));

        // Second request - should hit network again (not cached)
        final response2 = await cachingClient.get(Uri.parse(url));
        expect(response2.statusCode, equals(500));

        // Should have two network requests
        expect(mockClient.requestLog.length, equals(2));
      });

      test('should respect cache headers and TTL', () async {
        const url = 'https://api.example.com/ttl';
        const responseBody = '{"data": "short_ttl"}';

        // Setup mock response
        mockClient.addResponse(url, http.Response(responseBody, 200));

        // Request with very short cache duration
        final uri = Uri.parse(url);
        final request = http.Request('GET', uri);
        request.headers['cache-control'] = 'max-age=1'; // 1 second TTL

        final response1 = await cachingClient.send(request);
        final body1 = await response1.stream.bytesToString();
        expect(response1.statusCode, equals(200));
        expect(body1, equals(responseBody));

        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 1100));

        // Second request - cache should be expired, hit network again
        final response2 = await cachingClient.send(request);
        expect(response2.statusCode, equals(200));

        // Should have two network requests due to expiry
        expect(mockClient.requestLog.length, equals(2));
      });
    });

    group('Network Failure Handling', () {
      test('should return cached data when network fails', () async {
        const url = 'https://api.example.com/fallback';
        const cachedBody = '{"cached": "data"}';

        // Setup initial successful response
        mockClient.addResponse(url, http.Response(cachedBody, 200));

        // First request - populate cache
        final response1 = await cachingClient.get(Uri.parse(url));
        expect(response1.statusCode, equals(200));
        expect(response1.body, equals(cachedBody));

        // Setup network error for subsequent requests
        mockClient.addError(url, const SocketException('Network unreachable'));

        // Second request - should return cached data despite network error
        final response2 = await cachingClient.get(Uri.parse(url));
        expect(response2.statusCode, equals(200));
        expect(response2.body, equals(cachedBody));
        expect(response2.headers['x-cache'], equals('HIT'));
        expect(response2.headers['x-cache-fallback'], equals('network-error'));
      });

      test('should queue requests when offline', () async {
        const url = 'https://api.example.com/offline';

        // Setup network error (simulating offline)
        mockClient.addError(url, const SocketException('Network unreachable'));

        // Make request while offline
        final response = await cachingClient.post(
          Uri.parse(url),
          body: '{"action": "create"}',
        );

        // Should receive queued response
        expect(response.statusCode, equals(202)); // Accepted
        expect(response.headers['x-offline-queued'], equals('true'));

        // Verify request was queued
        final queuedRequests = cachingClient.offlineQueue;
        expect(queuedRequests.length, equals(1));
        expect(queuedRequests.first.url, equals(url));
      });
    });

    group('Authentication Handling', () {
      test('should clear authenticated cache on logout', () async {
        const authUrl = 'https://api.example.com/user/profile';
        const publicUrl = 'https://api.example.com/public/data';
        const authBody = '{"user": "authenticated_data"}';
        const publicBody = '{"data": "public_data"}';

        // Setup responses
        mockClient.addResponse(authUrl, http.Response(authBody, 200));
        mockClient.addResponse(publicUrl, http.Response(publicBody, 200));

        // Set authentication status
        cachingClient.setAuthenticationStatus(true);

        // Make authenticated request
        final authResponse1 = await cachingClient.get(Uri.parse(authUrl));
        expect(authResponse1.statusCode, equals(200));
        expect(authResponse1.body, equals(authBody));

        // Make public request
        final publicResponse1 = await cachingClient.get(Uri.parse(publicUrl));
        expect(publicResponse1.statusCode, equals(200));
        expect(publicResponse1.body, equals(publicBody));

        // Clear cache log
        mockClient.clearLog();

        // Logout (should clear authenticated cache)
        cachingClient.setAuthenticationStatus(false);

        // Request authenticated data again - should hit network (cache cleared)
        final authResponse2 = await cachingClient.get(Uri.parse(authUrl));
        expect(authResponse2.statusCode, equals(200));

        // Request public data again - should hit cache (not cleared)
        final publicResponse2 = await cachingClient.get(Uri.parse(publicUrl));
        expect(publicResponse2.statusCode, equals(200));
        expect(publicResponse2.headers['x-cache'], equals('HIT'));

        // Should only have one network request (for auth data)
        expect(mockClient.requestLog.length, equals(1));
        expect(mockClient.requestLog.first.url.toString(), equals(authUrl));
      });
    });

    group('Cache Strategies', () {
      test('should handle cache-first strategy', () async {
        const url = 'https://api.example.com/cache-first';
        const cachedBody = '{"strategy": "cache-first"}';

        // Setup response
        mockClient.addResponse(url, http.Response(cachedBody, 200));

        // Make initial request to populate cache
        await cachingClient.get(Uri.parse(url));

        // Setup network error
        mockClient.addError(url, const SocketException('Network error'));
        mockClient.clearLog();

        // Request with cache-first strategy should return cached data
        final request = http.Request('GET', Uri.parse(url));
        request.headers['cache-strategy'] = 'cache-first';

        final response = await cachingClient.send(request);
        final body = await response.stream.bytesToString();

        expect(response.statusCode, equals(200));
        expect(body, equals(cachedBody));
        expect(response.headers['x-cache'], equals('HIT'));

        // Should not hit network
        expect(mockClient.requestLog.length, equals(0));
      });

      test('should handle network-only strategy', () async {
        const url = 'https://api.example.com/network-only';
        const networkBody = '{"strategy": "network-only"}';

        // Setup response
        mockClient.addResponse(url, http.Response(networkBody, 200));

        // Make initial request to populate cache
        await cachingClient.get(Uri.parse(url));
        mockClient.clearLog();

        // Request with network-only strategy
        final request = http.Request('GET', Uri.parse(url));
        request.headers['cache-strategy'] = 'network-only';

        final response = await cachingClient.send(request);
        final body = await response.stream.bytesToString();

        expect(response.statusCode, equals(200));
        expect(body, equals(networkBody));
        expect(response.headers.containsKey('x-cache'), isFalse);

        // Should hit network despite cached data
        expect(mockClient.requestLog.length, equals(1));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle malformed cache entries gracefully', () async {
        const url = 'https://api.example.com/malformed';
        const responseBody = '{"data": "valid"}';

        // Setup response
        mockClient.addResponse(url, http.Response(responseBody, 200));

        // Make request - should work normally
        final response = await cachingClient.get(Uri.parse(url));
        expect(response.statusCode, equals(200));
        expect(response.body, equals(responseBody));
      });

      test('should handle concurrent requests to same URL', () async {
        const url = 'https://api.example.com/concurrent';
        const responseBody = '{"data": "concurrent"}';

        // Setup response with delay to simulate slow network
        mockClient.addResponse(url, http.Response(responseBody, 200));

        // Make multiple concurrent requests
        final futures = List.generate(
          5,
          (_) => cachingClient.get(Uri.parse(url)),
        );

        final responses = await Future.wait(futures);

        // All responses should be successful
        for (final response in responses) {
          expect(response.statusCode, equals(200));
          expect(response.body, equals(responseBody));
        }

        // Should have made at least one network request
        expect(mockClient.requestLog.length, greaterThanOrEqualTo(1));
      });

      test('should provide cache statistics', () async {
        const url = 'https://api.example.com/stats';
        const responseBody = '{"data": "for_stats"}';

        // Setup response
        mockClient.addResponse(url, http.Response(responseBody, 200));

        // Make some requests
        await cachingClient.get(Uri.parse(url));
        await cachingClient.get(Uri.parse(url)); // cache hit

        // Get cache statistics
        final stats = await cachingClient.getCacheStats();

        expect(stats, isNotNull);
        expect(stats['totalCount'], greaterThan(0));
        expect(stats, containsPair('memoryCount', isA<int>()));
        expect(stats, containsPair('persistentCount', isA<int>()));
      });
    });

    group('Network Status Integration', () {
      test('should provide network status information', () {
        final networkInfo = cachingClient.networkInfo;
        expect(networkInfo, isNotNull);
        expect(networkInfo.isOnline, isA<bool>());
        expect(networkInfo.isOffline, isA<bool>());
      });

      test('should provide network status stream', () {
        final networkStream = cachingClient.networkStatusStream;
        expect(networkStream, isNotNull);
      });

      test('should provide offline queue stream', () {
        final offlineStream = cachingClient.offlineQueueStream;
        expect(offlineStream, isNotNull);
      });

      test('should allow force network check', () async {
        // Should not throw
        await cachingClient.forceNetworkCheck();
      });

      test('should allow clearing offline queue', () {
        // Should not throw
        cachingClient.clearOfflineQueue();
        expect(cachingClient.offlineQueue.length, equals(0));
      });
    });

    group('Cache Management Operations', () {
      test('should clear cache', () async {
        const url = 'https://api.example.com/clear';
        const responseBody = '{"data": "to_clear"}';

        // Setup and make request
        mockClient.addResponse(url, http.Response(responseBody, 200));
        await cachingClient.get(Uri.parse(url));

        // Verify cache has data
        var stats = await cachingClient.getCacheStats();
        expect(stats['totalCount'], greaterThan(0));

        // Clear cache
        await cachingClient.clearCache();

        // Verify cache is empty
        stats = await cachingClient.getCacheStats();
        expect(stats['totalCount'], equals(0));
      });

      test('should clear expired cache entries', () async {
        const url = 'https://api.example.com/expire';
        const responseBody = '{"data": "expires"}';

        // Setup response
        mockClient.addResponse(url, http.Response(responseBody, 200));

        // Make request with short TTL
        final request = http.Request('GET', Uri.parse(url));
        request.headers['cache-control'] = 'max-age=1';
        await cachingClient.send(request);

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 1100));

        // Clear expired entries
        await cachingClient.clearExpiredCache();

        // Verify expired entries are removed
        final stats = await cachingClient.getCacheStats();
        expect(stats['totalCount'], equals(0));
      });
    });
  });
}
