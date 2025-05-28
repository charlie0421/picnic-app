import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 네트워크 연결 관리 서비스
/// HTTP 연결 풀링과 throttling을 통해 이미지 로딩 성능을 최적화합니다.
class NetworkConnectionManager {
  static final NetworkConnectionManager _instance =
      NetworkConnectionManager._internal();
  factory NetworkConnectionManager() => _instance;
  NetworkConnectionManager._internal();

  // 연결 상태 모니터링
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // HTTP 클라이언트 풀
  HttpClient? _httpClient;
  bool _isInitialized = false;
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];

  // 연결 상태 스트림
  final _connectionStatusController =
      StreamController<List<ConnectivityResult>>.broadcast();
  Stream<List<ConnectivityResult>> get connectionStatusStream =>
      _connectionStatusController.stream;

  // 현재 연결 상태
  List<ConnectivityResult> get currentConnectionStatus => _connectionStatus;
  bool get isConnected =>
      !_connectionStatus.contains(ConnectivityResult.none) &&
      _connectionStatus.isNotEmpty;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 초기 연결 상태 확인
      _connectionStatus = await _connectivity.checkConnectivity();

      // 연결 상태 변화 모니터링
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          logger.e('연결 상태 모니터링 오류', error: error);
        },
      );

      // HTTP 클라이언트 초기화
      _initializeHttpClient();

      _isInitialized = true;
      logger.i('NetworkConnectionManager 초기화 완료 - 현재 연결: $_connectionStatus');
    } catch (e) {
      logger.e('NetworkConnectionManager 초기화 실패', error: e);
      rethrow;
    }
  }

  /// HTTP 클라이언트 초기화
  void _initializeHttpClient() {
    _httpClient?.close(force: true);

    _httpClient = HttpClient()
      // 연결 수 제한으로 동시 요청 문제 해결
      ..maxConnectionsPerHost = 6
      // 타임아웃 설정
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 30)
      // Keep-Alive 설정
      ..autoUncompress = true
      // User-Agent 설정
      ..userAgent = 'PicnicApp/1.0 (Flutter; ${Platform.operatingSystem})';

    logger.d('HTTP 클라이언트 초기화: 최대 연결 수 6개, 타임아웃 15초');
  }

  /// 연결 상태 변화 처리
  void _onConnectivityChanged(List<ConnectivityResult> result) {
    final previousStatus = _connectionStatus;
    _connectionStatus = result;

    logger.i('네트워크 연결 상태 변경: $previousStatus -> $result');

    // 연결 상태가 변경되면 HTTP 클라이언트 재초기화
    if (previousStatus != result) {
      _initializeHttpClient();
      _connectionStatusController.add(result);
    }
  }

  /// 최적화된 HTTP 클라이언트 반환
  HttpClient get httpClient {
    if (_httpClient == null) {
      _initializeHttpClient();
    }
    return _httpClient!;
  }

  /// 네트워크 품질 확인
  Future<NetworkQuality> checkNetworkQuality() async {
    if (!isConnected) {
      return NetworkQuality.none;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // 간단한 네트워크 속도 테스트
      final request = await httpClient
          .getUrl(Uri.parse('https://www.google.com/favicon.ico'));
      final response = await request.close();

      stopwatch.stop();

      if (response.statusCode == 200) {
        final responseTime = stopwatch.elapsedMilliseconds;

        if (responseTime < 500) {
          return NetworkQuality.excellent;
        } else if (responseTime < 1000) {
          return NetworkQuality.good;
        } else if (responseTime < 2000) {
          return NetworkQuality.fair;
        } else {
          return NetworkQuality.poor;
        }
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      logger.e('네트워크 품질 확인 실패', error: e);
      return NetworkQuality.poor;
    }
  }

  /// 연결 타입별 권장 설정 반환
  ImageLoadingConfig getRecommendedConfig() {
    // 연결 상태가 비어있거나 none만 있는 경우 기본 설정 반환
    if (_connectionStatus.isEmpty ||
        _connectionStatus
            .every((status) => status == ConnectivityResult.none)) {
      return const ImageLoadingConfig(
        maxConcurrentRequests: 1,
        requestDelay: Duration(milliseconds: 500),
        timeoutDuration: Duration(seconds: 30),
        retryCount: 1,
      );
    }

    // 가장 좋은 연결 타입을 우선순위로 선택
    if (_connectionStatus.contains(ConnectivityResult.wifi)) {
      return const ImageLoadingConfig(
        maxConcurrentRequests: 6,
        requestDelay: Duration(milliseconds: 50),
        timeoutDuration: Duration(seconds: 15),
        retryCount: 3,
      );
    } else if (_connectionStatus.contains(ConnectivityResult.ethernet)) {
      return const ImageLoadingConfig(
        maxConcurrentRequests: 8,
        requestDelay: Duration(milliseconds: 25),
        timeoutDuration: Duration(seconds: 10),
        retryCount: 3,
      );
    } else if (_connectionStatus.contains(ConnectivityResult.mobile)) {
      return const ImageLoadingConfig(
        maxConcurrentRequests: 3,
        requestDelay: Duration(milliseconds: 200),
        timeoutDuration: Duration(seconds: 20),
        retryCount: 2,
      );
    } else {
      return const ImageLoadingConfig(
        maxConcurrentRequests: 1,
        requestDelay: Duration(milliseconds: 500),
        timeoutDuration: Duration(seconds: 30),
        retryCount: 1,
      );
    }
  }

  /// 리소스 정리
  void dispose() {
    _connectivitySubscription.cancel();
    _connectionStatusController.close();
    _httpClient?.close(force: true);
    _httpClient = null;
    _isInitialized = false;
    logger.i('NetworkConnectionManager 리소스 정리 완료');
  }
}

/// 네트워크 품질 등급
enum NetworkQuality {
  none,
  poor,
  fair,
  good,
  excellent,
}

/// 이미지 로딩 설정
class ImageLoadingConfig {
  final int maxConcurrentRequests;
  final Duration requestDelay;
  final Duration timeoutDuration;
  final int retryCount;

  const ImageLoadingConfig({
    required this.maxConcurrentRequests,
    required this.requestDelay,
    required this.timeoutDuration,
    required this.retryCount,
  });
}
