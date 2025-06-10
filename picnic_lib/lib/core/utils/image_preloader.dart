import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/optimized_cache_manager.dart';

/// 이미지 사전 로딩 유틸리티
///
/// 뷰포트에 들어갈 가능성이 높은 이미지들을 미리 로딩하여
/// 사용자 경험을 향상시킵니다.
class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  factory ImagePreloader() => _instance;
  ImagePreloader._internal();

  final Map<String, Completer<ui.Image>> _preloadingImages = {};
  final Map<String, ui.Image> _preloadedImages = {};
  final Set<String> _failedUrls = {};

  static const int _maxPreloadedImages = 50;
  static const Duration _preloadTimeout = Duration(seconds: 10);

  /// 이미지를 사전 로딩합니다
  Future<void> preloadImage(String imageUrl, {int? priority}) async {
    if (_preloadedImages.containsKey(imageUrl) ||
        _failedUrls.contains(imageUrl) ||
        _preloadingImages.containsKey(imageUrl)) {
      return;
    }

    // 메모리 관리: 최대 개수 초과 시 오래된 이미지 제거
    if (_preloadedImages.length >= _maxPreloadedImages) {
      _cleanupOldImages();
    }

    try {
      final completer = Completer<ui.Image>();
      _preloadingImages[imageUrl] = completer;

      // OptimizedCacheManager를 통해 이미지 다운로드
      final fileInfo =
          await OptimizedCacheManager.instance.getFileFromCache(imageUrl);

      if (fileInfo != null) {
        // 캐시에서 이미지 로드
        final bytes = await fileInfo.file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        _preloadedImages[imageUrl] = frame.image;
        completer.complete(frame.image);
        logger.d('이미지 사전 로딩 완료 (캐시): $imageUrl');
      } else {
        // 네트워크에서 이미지 다운로드 및 캐시
        final fileStream = OptimizedCacheManager.instance
            .getFileStream(imageUrl, withProgress: false);

        await for (final result in fileStream) {
          if (result is FileInfo) {
            final bytes = await result.file.readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();

            _preloadedImages[imageUrl] = frame.image;
            completer.complete(frame.image);
            logger.d('이미지 사전 로딩 완료 (네트워크): $imageUrl');
            break;
          }
        }
      }
    } catch (e) {
      logger.w('이미지 사전 로딩 실패: $imageUrl - $e');
      _failedUrls.add(imageUrl);
      _preloadingImages[imageUrl]?.completeError(e);
    } finally {
      _preloadingImages.remove(imageUrl);
    }
  }

  /// 여러 이미지를 배치로 사전 로딩합니다
  Future<void> preloadImages(
    List<String> imageUrls, {
    int? concurrency,
  }) async {
    final concurrentLimit = concurrency ?? 3;
    final futures = <Future<void>>[];

    for (int i = 0; i < imageUrls.length; i += concurrentLimit) {
      final batch = imageUrls
          .skip(i)
          .take(concurrentLimit)
          .map((url) => preloadImage(url))
          .toList();

      futures.addAll(batch);

      // 배치가 완료될 때까지 대기
      await Future.wait(batch, eagerError: false);
    }

    await Future.wait(futures, eagerError: false);
  }

  /// 우선순위 기반 이미지 사전 로딩
  Future<void> preloadImagesWithPriority(
    Map<String, int> imageUrlsWithPriority,
  ) async {
    // 우선순위 순으로 정렬 (높은 우선순위 먼저)
    final sortedUrls = imageUrlsWithPriority.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedUrls) {
      await preloadImage(entry.key, priority: entry.value);
    }
  }

  /// 사전 로딩된 이미지를 가져옵니다
  ui.Image? getPreloadedImage(String imageUrl) {
    return _preloadedImages[imageUrl];
  }

  /// 이미지가 사전 로딩되었는지 확인합니다
  bool isPreloaded(String imageUrl) {
    return _preloadedImages.containsKey(imageUrl);
  }

  /// 오래된 이미지들을 정리합니다
  void _cleanupOldImages() {
    if (_preloadedImages.length <= _maxPreloadedImages * 0.8) {
      return;
    }

    try {
      // 절반 정도의 이미지를 제거 (단순한 LRU 구현)
      final removeCount = (_preloadedImages.length * 0.5).round();
      final keysToRemove = _preloadedImages.keys.take(removeCount).toList();

      for (final key in keysToRemove) {
        final image = _preloadedImages.remove(key);
        image?.dispose();
      }

      logger.d('사전 로딩된 이미지 정리: ${keysToRemove.length}개 제거');
    } catch (e) {
      logger.e('이미지 정리 중 오류: $e');
    }
  }

  /// 특정 이미지를 캐시에서 제거합니다
  void removePreloadedImage(String imageUrl) {
    final image = _preloadedImages.remove(imageUrl);
    image?.dispose();
    _failedUrls.remove(imageUrl);
  }

  /// 모든 사전 로딩된 이미지를 정리합니다
  void clearAll() {
    try {
      for (final image in _preloadedImages.values) {
        image.dispose();
      }
      _preloadedImages.clear();
      _failedUrls.clear();
      _preloadingImages.clear();

      logger.d('모든 사전 로딩된 이미지 정리 완료');
    } catch (e) {
      logger.e('이미지 전체 정리 중 오류: $e');
    }
  }

  /// 메모리 사용량 정보를 반환합니다
  Map<String, dynamic> getMemoryInfo() {
    final totalImages = _preloadedImages.length;
    var estimatedMemory = 0;

    for (final image in _preloadedImages.values) {
      // 이미지 메모리 사용량 추정 (width * height * 4 bytes per pixel)
      estimatedMemory += image.width * image.height * 4;
    }

    return {
      'totalImages': totalImages,
      'estimatedMemoryBytes': estimatedMemory,
      'estimatedMemoryMB': estimatedMemory / (1024 * 1024),
      'failedUrls': _failedUrls.length,
      'currentlyPreloading': _preloadingImages.length,
    };
  }
}
