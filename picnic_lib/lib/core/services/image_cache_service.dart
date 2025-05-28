import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:universal_platform/universal_platform.dart';

/// 이미지 캐시 관리를 위한 서비스 클래스
/// 메모리 효율적인 이미지 로딩과 캐싱을 제공합니다.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  // 캐시 매니저 인스턴스
  late final CacheManager _cacheManager;

  // 메모리 사용량 모니터링
  Timer? _memoryMonitorTimer;

  // 캐시 설정
  late final ImageCacheConfig _config;

  // 로드된 이미지 추적 (URL -> 메타데이터)
  final Map<String, ImageCacheMetadata> _loadedImages = {};

  // 메모리 압박 상태
  bool _isMemoryPressure = false;

  // 동시 요청 제한을 위한 큐 시스템
  final Queue<_ImageRequest> _requestQueue = Queue<_ImageRequest>();
  final Set<String> _activeRequests = {};
  Timer? _queueProcessorTimer;

  // 최대 동시 요청 수 제한 (기본값: 6)
  static const int _maxConcurrentRequests = 6;

  // 요청 간 최소 지연 시간 (밀리초)
  static const int _minRequestDelayMs = 50;

  // 재시도 카운터
  final Map<String, int> _retryCount = {};
  static const int _maxRetries = 3;

  /// 초기화
  void initialize({ImageCacheConfig? config}) {
    _config = config ?? ImageCacheConfig.defaultConfig();

    // 커스텀 캐시 매니저 설정 - 네트워크 최적화
    _cacheManager = CacheManager(
      Config(
        'picnic_image_cache',
        stalePeriod: _config.stalePeriod,
        maxNrOfCacheObjects: _config.maxCacheObjects,
        repo: JsonCacheInfoRepository(databaseName: 'picnic_image_cache'),
        fileService: HttpFileService(),
      ),
    );

    // Flutter 이미지 캐시 설정
    _configureFlutterImageCache();

    // 메모리 모니터링 시작
    _startMemoryMonitoring();

    // 요청 큐 프로세서 시작
    _startQueueProcessor();

    logger.i('ImageCacheService 초기화 완료 (최적화된 네트워크 설정)');
  }

  /// 요청 큐 프로세서 시작
  void _startQueueProcessor() {
    _queueProcessorTimer = Timer.periodic(
      Duration(milliseconds: _minRequestDelayMs),
      (timer) => _processRequestQueue(),
    );
  }

  /// 요청 큐 처리
  void _processRequestQueue() {
    // 현재 활성 요청이 최대 제한에 도달했다면 대기
    if (_activeRequests.length >= _maxConcurrentRequests) {
      return;
    }

    // 큐에서 다음 요청 처리
    if (_requestQueue.isNotEmpty) {
      final request = _requestQueue.removeFirst();
      _processImageRequest(request);
    }
  }

  /// 개별 이미지 요청 처리
  void _processImageRequest(_ImageRequest request) async {
    _activeRequests.add(request.url);

    try {
      final result = await _loadImageDirect(
        request.url,
        headers: request.headers,
        maxAge: request.maxAge,
      );

      request.completer.complete(result);
      _retryCount.remove(request.url); // 성공시 재시도 카운터 리셋
    } catch (e) {
      // 재시도 로직
      final retries = _retryCount[request.url] ?? 0;
      if (retries < _maxRetries) {
        _retryCount[request.url] = retries + 1;

        // 지수 백오프로 재시도 (1초, 2초, 4초)
        final delay = Duration(seconds: 1 << retries);
        Timer(delay, () {
          _requestQueue.add(request); // 큐에 다시 추가
        });

        logger.w('이미지 로드 재시도 (${retries + 1}/$_maxRetries): ${request.url}');
      } else {
        request.completer.completeError(e);
        _retryCount.remove(request.url);
        logger.e('이미지 로드 최종 실패: ${request.url}', error: e);
      }
    } finally {
      _activeRequests.remove(request.url);
    }
  }

  /// Flutter 이미지 캐시 설정
  void _configureFlutterImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;

    // 디바이스별 캐시 크기 설정
    if (UniversalPlatform.isWeb) {
      imageCache.maximumSize = _config.webMaxCacheSize;
      imageCache.maximumSizeBytes = _config.webMaxCacheSizeBytes;
    } else if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      imageCache.maximumSize = _config.mobileMaxCacheSize;
      imageCache.maximumSizeBytes = _config.mobileMaxCacheSizeBytes;
    }

    logger.i(
        'Flutter 이미지 캐시 설정: 최대 ${imageCache.maximumSize}개, ${imageCache.maximumSizeBytes ~/ (1024 * 1024)}MB');
  }

  /// 메모리 모니터링 시작
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(_config.memoryCheckInterval, (timer) {
      _checkMemoryPressure();
      _cleanupIfNeeded();
    });
  }

  /// 메모리 압박 상태 확인
  void _checkMemoryPressure() {
    final imageCache = PaintingBinding.instance.imageCache;
    final currentSizeBytes = imageCache.currentSizeBytes;
    final maxSizeBytes = imageCache.maximumSizeBytes;

    // 메모리 사용률이 80% 이상이면 압박 상태로 판단
    final memoryUsageRatio = currentSizeBytes / maxSizeBytes;
    final wasMemoryPressure = _isMemoryPressure;
    _isMemoryPressure = memoryUsageRatio > 0.8;

    if (_isMemoryPressure && !wasMemoryPressure) {
      logger.w(
          '메모리 압박 상태 감지: ${(memoryUsageRatio * 100).toStringAsFixed(1)}% 사용 중');
      MemoryProfiler.instance.takeSnapshot(
        'memory_pressure_detected',
        level: MemoryProfiler.snapshotLevelHigh,
        metadata: {
          'memory_usage_ratio': memoryUsageRatio,
          'current_size_mb': currentSizeBytes ~/ (1024 * 1024),
          'max_size_mb': maxSizeBytes ~/ (1024 * 1024),
        },
      );
    } else if (!_isMemoryPressure && wasMemoryPressure) {
      logger.i(
          '메모리 압박 상태 해제: ${(memoryUsageRatio * 100).toStringAsFixed(1)}% 사용 중');
    }
  }

  /// 필요시 캐시 정리
  void _cleanupIfNeeded() {
    // 메모리 압박 상태이거나 로드된 이미지가 너무 많은 경우 정리
    if (_isMemoryPressure || _loadedImages.length > _config.maxTrackedImages) {
      _performCleanup();
    }
  }

  /// 캐시 정리 수행
  void _performCleanup() {
    final beforeCleanup = PaintingBinding.instance.imageCache.currentSizeBytes;

    // LRU 방식으로 오래된 이미지 제거
    final sortedImages = _loadedImages.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

    final removeCount = _isMemoryPressure
        ? (_loadedImages.length * 0.3).round() // 메모리 압박시 30% 제거
        : (_loadedImages.length * 0.1).round(); // 일반적으로 10% 제거

    for (int i = 0; i < removeCount && i < sortedImages.length; i++) {
      final entry = sortedImages[i];
      _loadedImages.remove(entry.key);

      // Flutter 이미지 캐시에서도 제거
      final imageProvider = NetworkImage(entry.key);
      imageProvider.evict();
    }

    // 메모리 압박 상태에서는 Flutter 이미지 캐시도 부분적으로 정리
    if (_isMemoryPressure) {
      PaintingBinding.instance.imageCache.clearLiveImages();
    }

    final afterCleanup = PaintingBinding.instance.imageCache.currentSizeBytes;
    final freedBytes = beforeCleanup - afterCleanup;

    logger.i(
        '캐시 정리 완료: $removeCount개 이미지 제거, ${freedBytes ~/ (1024 * 1024)}MB 메모리 확보');
  }

  /// 이미지 로드 및 캐시 (큐 시스템 사용)
  Future<Uint8List?> loadImage(
    String url, {
    Map<String, String>? headers,
    Duration? maxAge,
  }) async {
    // 이미지 메타데이터 업데이트
    _updateImageMetadata(url);

    // 요청을 큐에 추가하고 Completer로 결과 기다림
    final completer = Completer<Uint8List?>();
    final request = _ImageRequest(
      url: url,
      headers: headers ?? _getDefaultHeaders(),
      maxAge: maxAge,
      completer: completer,
    );

    _requestQueue.add(request);

    try {
      return await completer.future;
    } catch (e) {
      logger.e('이미지 로드 실패: $url', error: e);
      return null;
    }
  }

  /// 직접 이미지 로드 (내부 사용)
  Future<Uint8List> _loadImageDirect(
    String url, {
    Map<String, String>? headers,
    Duration? maxAge,
  }) async {
    // 캐시에서 이미지 로드 시도
    final file = await _cacheManager.getSingleFile(
      url,
      headers: headers ?? _getDefaultHeaders(),
    );

    final bytes = await file.readAsBytes();

    // 성공적으로 로드된 경우 메타데이터 업데이트
    _loadedImages[url] = ImageCacheMetadata(
      url: url,
      loadTime: DateTime.now(),
      lastAccessed: DateTime.now(),
      sizeBytes: bytes.length,
      loadCount: (_loadedImages[url]?.loadCount ?? 0) + 1,
    );

    return bytes;
  }

  /// 이미지 메타데이터 업데이트
  void _updateImageMetadata(String url) {
    final existing = _loadedImages[url];
    if (existing != null) {
      _loadedImages[url] = existing.copyWith(
        lastAccessed: DateTime.now(),
        accessCount: existing.accessCount + 1,
      );
    }
  }

  /// 기본 HTTP 헤더 반환
  Map<String, String> _getDefaultHeaders() {
    return {
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Cache-Control': 'max-age=${_config.defaultMaxAge.inSeconds}',
      'Connection': 'keep-alive',
    };
  }

  /// 특정 이미지 캐시에서 제거
  Future<void> evictImage(String url) async {
    await _cacheManager.removeFile(url);
    _loadedImages.remove(url);

    // Flutter 이미지 캐시에서도 제거
    final imageProvider = NetworkImage(url);
    imageProvider.evict();

    logger.d('이미지 캐시에서 제거: $url');
  }

  /// 전체 캐시 정리
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
    _loadedImages.clear();
    PaintingBinding.instance.imageCache.clear();

    logger.i('전체 이미지 캐시 정리 완료');
  }

  /// 캐시 통계 정보 반환
  ImageCacheStats getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;

    return ImageCacheStats(
      liveImages: imageCache.liveImageCount,
      sizeBytes: imageCache.currentSizeBytes,
      maxSizeBytes: imageCache.maximumSizeBytes,
      trackedImages: _loadedImages.length,
      isMemoryPressure: _isMemoryPressure,
    );
  }

  /// 리소스 정리
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    _queueProcessorTimer?.cancel();
    _queueProcessorTimer = null;
    logger.i('ImageCacheService 리소스 정리 완료');
  }
}

/// 이미지 캐시 설정
class ImageCacheConfig {
  final Duration stalePeriod;
  final int maxCacheObjects;
  final Duration defaultMaxAge;
  final Duration memoryCheckInterval;
  final int maxTrackedImages;

  // 플랫폼별 캐시 크기 설정
  final int webMaxCacheSize;
  final int webMaxCacheSizeBytes;
  final int mobileMaxCacheSize;
  final int mobileMaxCacheSizeBytes;

  const ImageCacheConfig({
    required this.stalePeriod,
    required this.maxCacheObjects,
    required this.defaultMaxAge,
    required this.memoryCheckInterval,
    required this.maxTrackedImages,
    required this.webMaxCacheSize,
    required this.webMaxCacheSizeBytes,
    required this.mobileMaxCacheSize,
    required this.mobileMaxCacheSizeBytes,
  });

  factory ImageCacheConfig.defaultConfig() {
    return const ImageCacheConfig(
      stalePeriod: Duration(days: 7),
      maxCacheObjects: 500,
      defaultMaxAge: Duration(days: 30),
      memoryCheckInterval: Duration(seconds: 30),
      maxTrackedImages: 200,
      webMaxCacheSize: 200,
      webMaxCacheSizeBytes: 200 * 1024 * 1024, // 200MB
      mobileMaxCacheSize: 100,
      mobileMaxCacheSizeBytes: 100 * 1024 * 1024, // 100MB
    );
  }
}

/// 이미지 캐시 메타데이터
class ImageCacheMetadata {
  final String url;
  final DateTime loadTime;
  final DateTime lastAccessed;
  final int sizeBytes;
  final int loadCount;
  final int accessCount;

  const ImageCacheMetadata({
    required this.url,
    required this.loadTime,
    required this.lastAccessed,
    required this.sizeBytes,
    required this.loadCount,
    this.accessCount = 1,
  });

  ImageCacheMetadata copyWith({
    String? url,
    DateTime? loadTime,
    DateTime? lastAccessed,
    int? sizeBytes,
    int? loadCount,
    int? accessCount,
  }) {
    return ImageCacheMetadata(
      url: url ?? this.url,
      loadTime: loadTime ?? this.loadTime,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      loadCount: loadCount ?? this.loadCount,
      accessCount: accessCount ?? this.accessCount,
    );
  }
}

/// 이미지 캐시 통계
class ImageCacheStats {
  final int liveImages;
  final int sizeBytes;
  final int maxSizeBytes;
  final int trackedImages;
  final bool isMemoryPressure;

  const ImageCacheStats({
    required this.liveImages,
    required this.sizeBytes,
    required this.maxSizeBytes,
    required this.trackedImages,
    required this.isMemoryPressure,
  });

  double get memoryUsageRatio => sizeBytes / maxSizeBytes;
  int get sizeMB => sizeBytes ~/ (1024 * 1024);
  int get maxSizeMB => maxSizeBytes ~/ (1024 * 1024);
}

/// 이미지 요청 클래스 (내부 사용)
class _ImageRequest {
  final String url;
  final Map<String, String>? headers;
  final Duration? maxAge;
  final Completer<Uint8List?> completer;

  const _ImageRequest({
    required this.url,
    this.headers,
    this.maxAge,
    required this.completer,
  });
}
