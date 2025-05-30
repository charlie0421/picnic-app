import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/services/cache_policy.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/retry_http_client.dart';

class CachingHttpClient extends http.BaseClient {
  final RetryHttpClient _retryClient;
  final SimpleCacheManager _cacheManager;
  final EnhancedNetworkService _networkService;
  bool _isAuthenticated = false;

  CachingHttpClient(http.Client inner)
      : _retryClient = RetryHttpClient(inner),
        _cacheManager = SimpleCacheManager.instance,
        _networkService = EnhancedNetworkService();

  void setAuthenticationStatus(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
    if (!isAuthenticated) {
      // Clear authenticated cache when user logs out
      _cacheManager.clearAuthenticatedCache();
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    final headers = Map<String, String>.from(request.headers);

    // Handle non-GET requests (POST, PUT, DELETE)
    if (request.method != 'GET') {
      return _handleNonGetRequest(request, url, headers);
    }

    // Get cache strategy for this URL
    final strategy = CachePolicy.getStrategyForUrl(url);
    final networkInfo = _networkService.currentNetworkInfo;

    switch (strategy) {
      case CacheStrategy.cacheFirst:
        return _handleCacheFirst(request, url, headers, networkInfo);
      case CacheStrategy.networkFirst:
        return _handleNetworkFirst(request, url, headers, networkInfo);
      case CacheStrategy.cacheOnly:
        return _handleCacheOnly(request, url, headers);
      case CacheStrategy.networkOnly:
        return _handleNetworkOnly(request, networkInfo);
      case CacheStrategy.staleWhileRevalidate:
        return _handleStaleWhileRevalidate(request, url, headers, networkInfo);
    }
  }

  Future<http.StreamedResponse> _handleNonGetRequest(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
  ) async {
    final networkInfo = _networkService.currentNetworkInfo;

    // If offline, queue the request for later
    if (networkInfo.isOffline) {
      await _queueOfflineRequest(request, url, headers);
      return _createOfflineQueuedResponse(request);
    }

    try {
      final response = await _retryClient.send(request);

      // Invalidate related cache entries after successful modification
      if (request.method == 'POST' ||
          request.method == 'PUT' ||
          request.method == 'DELETE') {
        await _cacheManager.invalidateForModification(url);
      }

      return response;
    } catch (e) {
      // If network request fails, queue for retry
      if (_shouldQueueOnFailure(e)) {
        await _queueOfflineRequest(request, url, headers);
        return _createOfflineQueuedResponse(request);
      }
      rethrow;
    }
  }

  Future<void> _queueOfflineRequest(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
  ) async {
    try {
      String? body;
      if (request is http.Request) {
        body = request.body;
      } else if (request is http.MultipartRequest) {
        // For multipart requests, we'd need to serialize the form data
        // This is a simplified implementation
        body = 'multipart_request_data';
      }

      final offlineRequest = OfflineRequest(
        id: _generateRequestId(request),
        method: request.method,
        url: url,
        headers: headers,
        body: body,
        createdAt: DateTime.now(),
      );

      _networkService.addOfflineRequest(offlineRequest);
      logger.i('Queued offline request: ${request.method} $url');
    } catch (e, s) {
      logger.e('Failed to queue offline request', error: e, stackTrace: s);
    }
  }

  String _generateRequestId(http.BaseRequest request) {
    final data =
        '${request.method}_${request.url}_${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  bool _shouldQueueOnFailure(dynamic error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException) {
      return true;
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }

  Future<http.StreamedResponse> _handleCacheFirst(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
    NetworkInfo networkInfo,
  ) async {
    // Try cache first
    final cachedEntry = await _cacheManager.get(url, headers,
        isAuthenticated: _isAuthenticated);

    if (cachedEntry != null && cachedEntry.isValid) {
      logger.d('Cache-first: serving valid cached response for $url');
      return _createStreamedResponseFromCache(cachedEntry);
    }

    // If offline and have stale cache, use it
    if (networkInfo.isOffline && cachedEntry != null) {
      logger.d('Cache-first: offline, serving stale cached response for $url');
      return _createStreamedResponseFromCache(cachedEntry);
    }

    // If offline and no cache, return error
    if (networkInfo.isOffline) {
      logger.w('Cache-first: offline, no cached response available for $url');
      return _createOfflineErrorResponse(request);
    }

    // Fallback to network
    return _makeNetworkRequestAndCache(request, url, headers, networkInfo);
  }

  Future<http.StreamedResponse> _handleNetworkFirst(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
    NetworkInfo networkInfo,
  ) async {
    if (networkInfo.isOnline) {
      try {
        // Try network first
        return await _makeNetworkRequestAndCache(
            request, url, headers, networkInfo);
      } catch (e) {
        logger.w('Network-first: network failed, trying cache for $url');
        // Fallback to cache on network error
        final cachedEntry = await _cacheManager.get(url, headers,
            isAuthenticated: _isAuthenticated);
        if (cachedEntry != null) {
          logger.d(
              'Network-first: serving cached response after network failure for $url');
          return _createStreamedResponseFromCache(cachedEntry);
        }
        rethrow;
      }
    } else {
      // If offline, try cache
      final cachedEntry = await _cacheManager.get(url, headers,
          isAuthenticated: _isAuthenticated);
      if (cachedEntry != null) {
        logger.d('Network-first: offline, serving cached response for $url');
        return _createStreamedResponseFromCache(cachedEntry);
      }

      logger.w('Network-first: offline, no cached response available for $url');
      return _createOfflineErrorResponse(request);
    }
  }

  Future<http.StreamedResponse> _handleCacheOnly(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
  ) async {
    final cachedEntry = await _cacheManager.get(url, headers,
        isAuthenticated: _isAuthenticated);

    if (cachedEntry != null) {
      logger.d('Cache-only: serving cached response for $url');
      return _createStreamedResponseFromCache(cachedEntry);
    }

    logger.w('Cache-only: no cached response available for $url');
    return _createCacheOnlyErrorResponse(request);
  }

  Future<http.StreamedResponse> _handleNetworkOnly(
    http.BaseRequest request,
    NetworkInfo networkInfo,
  ) async {
    if (networkInfo.isOffline) {
      logger.w('Network-only: offline, cannot make request for ${request.url}');
      return _createOfflineErrorResponse(request);
    }

    logger.d('Network-only: making network request for ${request.url}');
    return _retryClient.send(request);
  }

  Future<http.StreamedResponse> _handleStaleWhileRevalidate(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
    NetworkInfo networkInfo,
  ) async {
    final cachedEntry = await _cacheManager.get(url, headers,
        isAuthenticated: _isAuthenticated);

    // If we have cache (even stale), return it immediately
    if (cachedEntry != null) {
      logger.d('Stale-while-revalidate: serving cached response for $url');

      // If cache is stale and we're online, update in background
      if (!cachedEntry.isValid && networkInfo.isOnline) {
        logger.d(
            'Stale-while-revalidate: updating stale cache in background for $url');
        _updateCacheInBackground(request, url, headers, networkInfo);
      }

      return _createStreamedResponseFromCache(cachedEntry);
    }

    // No cache available, make network request if online
    if (networkInfo.isOnline) {
      return _makeNetworkRequestAndCache(request, url, headers, networkInfo);
    } else {
      logger.w(
          'Stale-while-revalidate: offline, no cached response available for $url');
      return _createOfflineErrorResponse(request);
    }
  }

  Future<http.StreamedResponse> _makeNetworkRequestAndCache(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
    NetworkInfo networkInfo,
  ) async {
    try {
      // Adjust timeout based on network quality
      final timeout = _getTimeoutForNetworkQuality(networkInfo.quality);

      final response = await _retryClient.send(request).timeout(timeout);
      final responseBody = await response.stream.bytesToString();

      // Cache the response if it should be cached
      if (CachePolicy.shouldCacheUrl(url) &&
          _shouldCacheResponse(response.statusCode)) {
        final ttl = CachePolicy.getTtlForUrl(url);
        await _cacheManager.put(
          url,
          headers,
          responseBody,
          response.statusCode,
          cacheDuration: ttl,
          responseHeaders: response.headers,
          etag: response.headers['etag'],
          isAuthenticated: _isAuthenticated,
        );
      }

      return http.StreamedResponse(
        Stream.value(utf8.encode(responseBody)),
        response.statusCode,
        headers: _addNetworkHeaders(response.headers, networkInfo),
        request: request,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e, s) {
      logger.e('Network request failed for $url', error: e, stackTrace: s);
      rethrow;
    }
  }

  Duration _getTimeoutForNetworkQuality(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return const Duration(seconds: 10);
      case NetworkQuality.good:
        return const Duration(seconds: 15);
      case NetworkQuality.fair:
        return const Duration(seconds: 20);
      case NetworkQuality.poor:
        return const Duration(seconds: 30);
      case NetworkQuality.none:
        return const Duration(seconds: 5);
    }
  }

  Map<String, String> _addNetworkHeaders(
    Map<String, String> originalHeaders,
    NetworkInfo networkInfo,
  ) {
    final headers = Map<String, String>.from(originalHeaders);
    headers['x-network-status'] = networkInfo.status.name;
    headers['x-network-quality'] = networkInfo.quality.name;
    if (networkInfo.latency != null) {
      headers['x-network-latency'] = '${networkInfo.latency}ms';
    }
    return headers;
  }

  void _updateCacheInBackground(
    http.BaseRequest request,
    String url,
    Map<String, String> headers,
    NetworkInfo networkInfo,
  ) {
    // Don't await this - it runs in background
    unawaited(_makeNetworkRequestAndCache(request, url, headers, networkInfo)
        .catchError((e) {
      logger.w('Background cache update failed for $url: $e');
    }));
  }

  http.StreamedResponse _createStreamedResponseFromCache(
      CacheEntry cachedEntry) {
    final headers = Map<String, String>.from(cachedEntry.headers);

    // Add cache headers
    headers['x-cache'] = 'HIT';
    headers['x-cache-date'] = cachedEntry.createdAt.toIso8601String();
    headers['x-cache-expires'] = cachedEntry.expiresAt.toIso8601String();
    headers['x-cache-priority'] = cachedEntry.priority.name;

    return http.StreamedResponse(
      Stream.value(utf8.encode(cachedEntry.data)),
      cachedEntry.statusCode,
      headers: headers,
    );
  }

  http.StreamedResponse _createOfflineErrorResponse(http.BaseRequest request) {
    const errorMessage =
        '{"error": "No internet connection and no cached data available"}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(errorMessage)),
      503, // Service Unavailable
      headers: {
        'content-type': 'application/json',
        'x-cache': 'MISS',
        'x-offline': 'true',
        'x-network-status': 'offline',
      },
      request: request,
      reasonPhrase: 'Service Unavailable - Offline',
    );
  }

  http.StreamedResponse _createOfflineQueuedResponse(http.BaseRequest request) {
    const message =
        '{"message": "Request queued for when connection is restored", "queued": true}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(message)),
      202, // Accepted
      headers: {
        'content-type': 'application/json',
        'x-offline-queued': 'true',
        'x-network-status': 'offline',
      },
      request: request,
      reasonPhrase: 'Accepted - Queued for Retry',
    );
  }

  http.StreamedResponse _createCacheOnlyErrorResponse(
      http.BaseRequest request) {
    const errorMessage =
        '{"error": "Cache-only strategy: no cached data available"}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(errorMessage)),
      404, // Not Found
      headers: {
        'content-type': 'application/json',
        'x-cache': 'MISS',
        'x-cache-only': 'true',
      },
      request: request,
      reasonPhrase: 'Not Found - Cache Only',
    );
  }

  bool _shouldCacheResponse(int statusCode) {
    // Only cache successful responses
    return statusCode >= 200 && statusCode < 400;
  }

  // Public API methods
  Future<Map<String, dynamic>> getCacheStats() async {
    return _cacheManager.getCacheStats();
  }

  Future<void> clearCache() async {
    await _cacheManager.clear();
  }

  Future<void> clearExpiredCache() async {
    await _cacheManager.clearExpired();
  }

  NetworkInfo get networkInfo => _networkService.currentNetworkInfo;

  Stream<NetworkInfo> get networkStatusStream =>
      _networkService.networkStatusStream;

  Stream<OfflineRequest> get offlineQueueStream =>
      _networkService.offlineQueueStream;

  List<OfflineRequest> get offlineQueue => _networkService.offlineQueue;

  void clearOfflineQueue() {
    _networkService.clearOfflineQueue();
  }

  Future<void> forceNetworkCheck() async {
    await _networkService.forceNetworkCheck();
  }

  @override
  void close() {
    _retryClient.close();
    super.close();
  }
}
