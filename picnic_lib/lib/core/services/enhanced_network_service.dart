import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';

enum NetworkStatus {
  online,
  offline,
  limited, // 연결은 있지만 인터넷 접근 불가
  slow, // 연결이 매우 느림
}

enum NetworkQuality {
  excellent, // < 100ms
  good, // 100-300ms
  fair, // 300-1000ms
  poor, // > 1000ms
  none, // 연결 없음
}

class NetworkInfo {
  final NetworkStatus status;
  final NetworkQuality quality;
  final List<ConnectivityResult> connectionTypes;
  final int? latency; // milliseconds
  final DateTime timestamp;

  const NetworkInfo({
    required this.status,
    required this.quality,
    required this.connectionTypes,
    this.latency,
    required this.timestamp,
  });

  bool get isOnline => status == NetworkStatus.online;
  bool get isOffline => status == NetworkStatus.offline;
  bool get hasLimitedConnectivity => status == NetworkStatus.limited;
  bool get isSlow => status == NetworkStatus.slow;
}

class EnhancedNetworkService {
  static final EnhancedNetworkService _instance =
      EnhancedNetworkService._internal();
  factory EnhancedNetworkService() => _instance;
  EnhancedNetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final SimpleCacheManager _cacheManager = SimpleCacheManager.instance;

  // Network state
  NetworkInfo _currentNetworkInfo = NetworkInfo(
    status: NetworkStatus.offline,
    quality: NetworkQuality.none,
    connectionTypes: [ConnectivityResult.none],
    timestamp: DateTime.now(),
  );

  // Stream controllers
  final _networkStatusController = StreamController<NetworkInfo>.broadcast();
  final _offlineQueueController = StreamController<OfflineRequest>.broadcast();

  // Offline request queue
  final List<OfflineRequest> _offlineQueue = [];
  Timer? _networkCheckTimer;
  Timer? _offlineRetryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Configuration
  static const Duration _networkCheckInterval = Duration(seconds: 30);
  static const Duration _offlineRetryInterval = Duration(minutes: 2);
  static const Duration _networkTestTimeout = Duration(seconds: 10);
  static const int _maxOfflineQueueSize = 100;

  // Getters
  NetworkInfo get currentNetworkInfo => _currentNetworkInfo;
  Stream<NetworkInfo> get networkStatusStream =>
      _networkStatusController.stream;
  Stream<OfflineRequest> get offlineQueueStream =>
      _offlineQueueController.stream;
  bool get isOnline => _currentNetworkInfo.isOnline;
  bool get isOffline => _currentNetworkInfo.isOffline;
  List<OfflineRequest> get offlineQueue => List.unmodifiable(_offlineQueue);

  Future<void> initialize() async {
    try {
      logger.i('Initializing EnhancedNetworkService...');

      // Initial network check
      await _updateNetworkStatus();

      // Start monitoring connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          logger.e('Connectivity monitoring error', error: error);
        },
      );

      // Start periodic network quality checks
      _startPeriodicNetworkCheck();

      // Start offline request retry mechanism
      _startOfflineRetryMechanism();

      logger.i('EnhancedNetworkService initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize EnhancedNetworkService',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> _updateNetworkStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final networkInfo = await _analyzeNetworkQuality(connectivityResults);

      final previousStatus = _currentNetworkInfo.status;
      _currentNetworkInfo = networkInfo;

      // Notify listeners
      _networkStatusController.add(networkInfo);

      // Handle status changes
      if (previousStatus != networkInfo.status) {
        await _handleNetworkStatusChange(previousStatus, networkInfo.status);
      }

      logger.d(
          'Network status updated: ${networkInfo.status.name} (${networkInfo.quality.name})');
    } catch (e, s) {
      logger.e('Error updating network status', error: e, stackTrace: s);
    }
  }

  Future<NetworkInfo> _analyzeNetworkQuality(
      List<ConnectivityResult> connectivityResults) async {
    // Check basic connectivity
    if (connectivityResults.isEmpty ||
        connectivityResults
            .every((result) => result == ConnectivityResult.none)) {
      return NetworkInfo(
        status: NetworkStatus.offline,
        quality: NetworkQuality.none,
        connectionTypes: connectivityResults,
        timestamp: DateTime.now(),
      );
    }

    // Test actual internet connectivity and measure latency
    final latencyResult = await _measureNetworkLatency();

    if (latencyResult == null) {
      return NetworkInfo(
        status: NetworkStatus.limited,
        quality: NetworkQuality.none,
        connectionTypes: connectivityResults,
        timestamp: DateTime.now(),
      );
    }

    // Determine quality based on latency
    NetworkQuality quality;
    NetworkStatus status;

    if (latencyResult < 100) {
      quality = NetworkQuality.excellent;
      status = NetworkStatus.online;
    } else if (latencyResult < 300) {
      quality = NetworkQuality.good;
      status = NetworkStatus.online;
    } else if (latencyResult < 1000) {
      quality = NetworkQuality.fair;
      status = NetworkStatus.online;
    } else if (latencyResult < 3000) {
      quality = NetworkQuality.poor;
      status = NetworkStatus.slow;
    } else {
      quality = NetworkQuality.poor;
      status = NetworkStatus.limited;
    }

    return NetworkInfo(
      status: status,
      quality: quality,
      connectionTypes: connectivityResults,
      latency: latencyResult,
      timestamp: DateTime.now(),
    );
  }

  Future<int?> _measureNetworkLatency() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Test multiple endpoints for reliability
      final testEndpoints = [
        'google.com',
        'cloudflare.com',
        '8.8.8.8',
      ];

      for (final endpoint in testEndpoints) {
        try {
          final result = await InternetAddress.lookup(endpoint)
              .timeout(_networkTestTimeout);

          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            stopwatch.stop();
            return stopwatch.elapsedMilliseconds;
          }
        } catch (e) {
          // Try next endpoint
          continue;
        }
      }

      return null; // No successful connection
    } catch (e) {
      logger.d('Network latency test failed: $e');
      return null;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    logger.d('Connectivity changed: $results');
    _updateNetworkStatus();
  }

  Future<void> _handleNetworkStatusChange(
      NetworkStatus previous, NetworkStatus current) async {
    logger.i('Network status changed: ${previous.name} -> ${current.name}');

    if (previous == NetworkStatus.offline && current != NetworkStatus.offline) {
      // Coming back online
      await _handleComingOnline();
    } else if (previous != NetworkStatus.offline &&
        current == NetworkStatus.offline) {
      // Going offline
      await _handleGoingOffline();
    }
  }

  Future<void> _handleComingOnline() async {
    logger.i('Device came back online - processing offline queue');

    // Process offline queue
    await _processOfflineQueue();

    // Sync cache with server if needed
    await _syncCacheWithServer();
  }

  Future<void> _handleGoingOffline() async {
    logger.i('Device went offline - enabling offline mode');

    // Prepare for offline mode
    await _prepareOfflineMode();
  }

  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;

    logger.i('Processing ${_offlineQueue.length} offline requests');

    final requestsToProcess = List<OfflineRequest>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final request in requestsToProcess) {
      try {
        await _retryOfflineRequest(request);
        _offlineQueueController
            .add(request.copyWith(status: OfflineRequestStatus.completed));
      } catch (e) {
        logger.w('Failed to process offline request: ${request.id}', error: e);

        if (request.retryCount < request.maxRetries) {
          // Re-queue with incremented retry count
          final updatedRequest = request.copyWith(
            retryCount: request.retryCount + 1,
            lastAttempt: DateTime.now(),
          );
          _offlineQueue.add(updatedRequest);
          _offlineQueueController.add(updatedRequest);
        } else {
          // Max retries exceeded
          _offlineQueueController
              .add(request.copyWith(status: OfflineRequestStatus.failed));
        }
      }
    }
  }

  Future<void> _retryOfflineRequest(OfflineRequest request) async {
    // This would be implemented based on the specific request type
    // For now, we'll just simulate the retry
    logger.d('Retrying offline request: ${request.id}');

    // Simulate network request
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real implementation, you would:
    // 1. Reconstruct the HTTP request from stored data
    // 2. Execute the request
    // 3. Handle the response
    // 4. Update local state if needed
  }

  Future<void> _syncCacheWithServer() async {
    try {
      logger.d('Syncing cache with server...');

      // Get cache statistics
      final stats = await _cacheManager.getCacheStats();
      logger.d('Cache stats: $stats');

      // Clear expired cache entries
      await _cacheManager.clearExpired();

      // In a real implementation, you might:
      // 1. Check for server-side data updates
      // 2. Invalidate stale cache entries
      // 3. Pre-fetch important data

      logger.i('Cache sync completed');
    } catch (e, s) {
      logger.e('Cache sync failed', error: e, stackTrace: s);
    }
  }

  Future<void> _prepareOfflineMode() async {
    try {
      logger.d('Preparing offline mode...');

      // Ensure critical data is cached
      // This could include user profile, app configuration, etc.

      logger.i('Offline mode preparation completed');
    } catch (e, s) {
      logger.e('Offline mode preparation failed', error: e, stackTrace: s);
    }
  }

  void _startPeriodicNetworkCheck() {
    _networkCheckTimer?.cancel();
    _networkCheckTimer = Timer.periodic(_networkCheckInterval, (_) {
      _updateNetworkStatus();
    });
  }

  void _startOfflineRetryMechanism() {
    _offlineRetryTimer?.cancel();
    _offlineRetryTimer = Timer.periodic(_offlineRetryInterval, (_) {
      if (isOnline && _offlineQueue.isNotEmpty) {
        _processOfflineQueue();
      }
    });
  }

  // Public API methods
  Future<bool> checkOnlineStatus() async {
    await _updateNetworkStatus();
    return isOnline;
  }

  void addOfflineRequest(OfflineRequest request) {
    if (_offlineQueue.length >= _maxOfflineQueueSize) {
      // Remove oldest request
      final removed = _offlineQueue.removeAt(0);
      logger.w('Offline queue full, removed request: ${removed.id}');
    }

    _offlineQueue.add(request);
    _offlineQueueController.add(request);
    logger.d('Added offline request: ${request.id}');
  }

  void removeOfflineRequest(String requestId) {
    _offlineQueue.removeWhere((request) => request.id == requestId);
    logger.d('Removed offline request: $requestId');
  }

  void clearOfflineQueue() {
    _offlineQueue.clear();
    logger.i('Cleared offline queue');
  }

  Future<void> forceNetworkCheck() async {
    logger.d('Forcing network check...');
    await _updateNetworkStatus();
  }

  void dispose() {
    _networkCheckTimer?.cancel();
    _offlineRetryTimer?.cancel();
    _connectivitySubscription?.cancel();
    _networkStatusController.close();
    _offlineQueueController.close();
    logger.i('EnhancedNetworkService disposed');
  }
}

// Offline request management
enum OfflineRequestStatus {
  pending,
  processing,
  completed,
  failed,
}

class OfflineRequest {
  final String id;
  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;
  final DateTime createdAt;
  final DateTime? lastAttempt;
  final int retryCount;
  final int maxRetries;
  final OfflineRequestStatus status;

  const OfflineRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    required this.createdAt,
    this.lastAttempt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.status = OfflineRequestStatus.pending,
  });

  OfflineRequest copyWith({
    String? id,
    String? method,
    String? url,
    Map<String, String>? headers,
    String? body,
    DateTime? createdAt,
    DateTime? lastAttempt,
    int? retryCount,
    int? maxRetries,
    OfflineRequestStatus? status,
  }) {
    return OfflineRequest(
      id: id ?? this.id,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'lastAttempt': lastAttempt?.toIso8601String(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'status': status.name,
    };
  }

  factory OfflineRequest.fromJson(Map<String, dynamic> json) {
    return OfflineRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      headers: Map<String, String>.from(json['headers'] as Map),
      body: json['body'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'] as String)
          : null,
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
      status: OfflineRequestStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OfflineRequestStatus.pending,
      ),
    );
  }
}
