import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 향상된 네트워크 상태 관리자
/// 더 정확한 네트워크 상태 감지와 오프라인 모드 관리를 제공합니다.
class NetworkStateManager {
  static const Duration _connectivityCheckInterval = Duration(seconds: 15);
  static const Duration _qualityCheckInterval = Duration(minutes: 1);
  static const Duration _pingTimeout = Duration(seconds: 5);
  static const int _maxPingAttempts = 3;

  static NetworkStateManager? _instance;
  static NetworkStateManager get instance => _instance ??= NetworkStateManager._();
  NetworkStateManager._();

  final EnhancedNetworkService _networkService = EnhancedNetworkService();

  Timer? _connectivityTimer;
  Timer? _qualityTimer;
  bool _isInitialized = false;

  // 네트워크 상태 스트림
  final _detailedNetworkController = StreamController<DetailedNetworkState>.broadcast();
  Stream<DetailedNetworkState> get detailedNetworkStream => _detailedNetworkController.stream;

  // 오프라인 모드 상태
  bool _isOfflineModeEnabled = false;
  bool get isOfflineModeEnabled => _isOfflineModeEnabled;

  /// 네트워크 상태 관리자 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      logger.i('Initializing NetworkStateManager...');

      // 기존 네트워크 서비스 초기화
      await _networkService.initialize();

      // 상세 네트워크 모니터링 시작
      _startDetailedNetworkMonitoring();

      // 오프라인 모드 설정 로드
      await _loadOfflineModeSettings();

      _isInitialized = true;
      logger.i('NetworkStateManager initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize NetworkStateManager', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 상세 네트워크 모니터링 시작
  void _startDetailedNetworkMonitoring() {
    // 연결성 체크 타이머
    _connectivityTimer = Timer.periodic(_connectivityCheckInterval, (_) {
      _performConnectivityCheck();
    });

    // 네트워크 품질 체크 타이머
    _qualityTimer = Timer.periodic(_qualityCheckInterval, (_) {
      _performQualityCheck();
    });

    // 기존 네트워크 서비스 상태 변화 감지
    _networkService.networkStatusStream.listen(_onNetworkStatusChanged);
  }

  /// 연결성 체크 수행
  Future<void> _performConnectivityCheck() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isConnected = !connectivity.every((result) => result == ConnectivityResult.none);

      if (isConnected) {
        // 실제 인터넷 연결 확인
        final hasInternet = await _checkInternetConnectivity();
        final latency = await _measureLatency();

        final detailedState = DetailedNetworkState(
          isConnected: isConnected,
          hasInternet: hasInternet,
          connectionTypes: connectivity,
          latency: latency,
          quality: _determineQuality(latency),
          timestamp: DateTime.now(),
          isOfflineModeForced: _isOfflineModeEnabled,
        );

        _detailedNetworkController.add(detailedState);
      } else {
        final detailedState = DetailedNetworkState(
          isConnected: false,
          hasInternet: false,
          connectionTypes: connectivity,
          latency: null,
          quality: NetworkQuality.none,
          timestamp: DateTime.now(),
          isOfflineModeForced: _isOfflineModeEnabled,
        );

        _detailedNetworkController.add(detailedState);
      }
    } catch (e) {
      logger.e('Error performing connectivity check', error: e);
    }
  }

  /// 네트워크 품질 체크 수행
  Future<void> _performQualityCheck() async {
    if (!_networkService.isOnline) return;

    try {
      final latency = await _measureLatency();
      final quality = _determineQuality(latency);

      logger.d('Network quality check: ${quality.name} (${latency}ms)');

      // 품질이 매우 낮으면 오프라인 모드 제안
      if (quality == NetworkQuality.poor) {
        logger.w('Poor network quality detected, consider enabling offline mode');
      }
    } catch (e) {
      logger.e('Error performing quality check', error: e);
    }
  }

  /// 실제 인터넷 연결 확인
  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(_pingTimeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      logger.d('Internet connectivity check failed', error: e);
      return false;
    }
  }

  /// 네트워크 지연시간 측정
  Future<int?> _measureLatency() async {
    int totalLatency = 0;
    int successfulPings = 0;

    for (int i = 0; i < _maxPingAttempts; i++) {
      try {
        final stopwatch = Stopwatch()..start();
        
        final socket = await Socket.connect('8.8.8.8', 53)
            .timeout(_pingTimeout);
        
        stopwatch.stop();
        socket.destroy();

        totalLatency += stopwatch.elapsedMilliseconds;
        successfulPings++;
      } catch (e) {
        logger.d('Ping attempt ${i + 1} failed', error: e);
      }
    }

    if (successfulPings > 0) {
      return totalLatency ~/ successfulPings;
    }

    return null;
  }

  /// 지연시간을 기반으로 네트워크 품질 결정
  NetworkQuality _determineQuality(int? latency) {
    if (latency == null) return NetworkQuality.none;

    if (latency < 100) return NetworkQuality.excellent;
    if (latency < 300) return NetworkQuality.good;
    if (latency < 1000) return NetworkQuality.fair;
    return NetworkQuality.poor;
  }

  /// 네트워크 상태 변화 처리
  void _onNetworkStatusChanged(NetworkInfo networkInfo) {
    logger.d('Network status changed: ${networkInfo.status.name}');

    // 오프라인에서 온라인으로 변경시 동기화 트리거
    if (networkInfo.isOnline && !_isOfflineModeEnabled) {
      _triggerDataSync();
    }
  }

  /// 데이터 동기화 트리거
  Future<void> _triggerDataSync() async {
    try {
      logger.i('Triggering data synchronization...');
      // 여기서 OfflineSyncService를 호출할 수 있습니다
      // await OfflineSyncService.instance.forceSync();
    } catch (e) {
      logger.e('Error triggering data sync', error: e);
    }
  }

  /// 오프라인 모드 설정 로드
  Future<void> _loadOfflineModeSettings() async {
    try {
      // SharedPreferences나 로컬 데이터베이스에서 설정 로드
      // 현재는 기본값으로 설정
      _isOfflineModeEnabled = false;
    } catch (e) {
      logger.e('Error loading offline mode settings', error: e);
    }
  }

  /// 오프라인 모드 강제 활성화/비활성화
  Future<void> setOfflineMode(bool enabled) async {
    try {
      _isOfflineModeEnabled = enabled;
      
      // 설정을 로컬에 저장
      // await SharedPreferences.getInstance().setBool('offline_mode_enabled', enabled);
      
      logger.i('Offline mode ${enabled ? 'enabled' : 'disabled'}');

      // 현재 상태를 다시 브로드캐스트
      await _performConnectivityCheck();
    } catch (e) {
      logger.e('Error setting offline mode', error: e);
    }
  }

  /// 네트워크 상태 강제 새로고침
  Future<void> refreshNetworkState() async {
    await _performConnectivityCheck();
    await _performQualityCheck();
  }

  /// 네트워크 진단 정보 수집
  Future<NetworkDiagnostics> getDiagnostics() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = await _checkInternetConnectivity();
      final latency = await _measureLatency();
      final currentState = _networkService.currentNetworkInfo;

      return NetworkDiagnostics(
        connectionTypes: connectivity,
        hasInternet: hasInternet,
        latency: latency,
        quality: _determineQuality(latency),
        currentStatus: currentState.status,
        isOfflineModeEnabled: _isOfflineModeEnabled,
        timestamp: DateTime.now(),
      );
    } catch (e, s) {
      logger.e('Error collecting network diagnostics', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 서비스 정리
  Future<void> dispose() async {
    _connectivityTimer?.cancel();
    _qualityTimer?.cancel();
    await _detailedNetworkController.close();
    _networkService.dispose();
    _isInitialized = false;
    logger.i('NetworkStateManager disposed');
  }
}

/// 상세 네트워크 상태
class DetailedNetworkState {
  final bool isConnected;
  final bool hasInternet;
  final List<ConnectivityResult> connectionTypes;
  final int? latency;
  final NetworkQuality quality;
  final DateTime timestamp;
  final bool isOfflineModeForced;

  DetailedNetworkState({
    required this.isConnected,
    required this.hasInternet,
    required this.connectionTypes,
    this.latency,
    required this.quality,
    required this.timestamp,
    required this.isOfflineModeForced,
  });

  bool get isEffectivelyOnline => isConnected && hasInternet && !isOfflineModeForced;
  bool get isEffectivelyOffline => !isConnected || !hasInternet || isOfflineModeForced;

  String get statusDescription {
    if (isOfflineModeForced) return 'Offline Mode (Forced)';
    if (!isConnected) return 'No Connection';
    if (!hasInternet) return 'Limited Connectivity';
    return 'Online (${quality.name})';
  }
}

/// 네트워크 진단 정보
class NetworkDiagnostics {
  final List<ConnectivityResult> connectionTypes;
  final bool hasInternet;
  final int? latency;
  final NetworkQuality quality;
  final NetworkStatus currentStatus;
  final bool isOfflineModeEnabled;
  final DateTime timestamp;

  NetworkDiagnostics({
    required this.connectionTypes,
    required this.hasInternet,
    this.latency,
    required this.quality,
    required this.currentStatus,
    required this.isOfflineModeEnabled,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'connectionTypes': connectionTypes.map((e) => e.name).toList(),
      'hasInternet': hasInternet,
      'latency': latency,
      'quality': quality.name,
      'currentStatus': currentStatus.name,
      'isOfflineModeEnabled': isOfflineModeEnabled,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 