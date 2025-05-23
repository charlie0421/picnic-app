import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';

/// 이미지 처리 파이프라인에 메모리 프로파일링 훅을 제공하는 유틸리티 클래스
class MemoryProfilingHook {
  /// 이미지 로딩 작업을 프로파일링합니다.
  static Future<T> profileImageLoading<T>({
    required String imageUrl,
    required Future<T> Function() loadFunction,
    int? expectedSizeBytes,
    WidgetRef? ref,
  }) async {
    final profiler = ref?.read(memoryProfilerProvider.notifier) ?? null;

    // 프로파일러가 비활성화된 경우 직접 함수 실행
    if (profiler == null || !profiler.state.isEnabled) {
      return loadFunction();
    }

    T result;
    try {
      // 이미지 로딩 프로파일링 전 별도로 결과 저장
      result = await loadFunction();

      // 이미지 로딩 프로파일링
      final diff = await profiler.profileImageOperation(
        imageUrl,
        () async {
          // 이미 수행한 작업이므로 빈 함수 반환
          return;
        },
        imageSize: expectedSizeBytes,
      );

      // 결과 로깅 (diff가 null이면 프로파일링이 비활성화되었거나 실패)
      if (diff != null) {
        final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
        if (heapDiffMB > 5) {
          // 5MB 이상 메모리 사용시 경고 로그
          logger.w('이미지 로딩에 많은 메모리 사용: $imageUrl - ${heapDiffMB}MB');
        }
      }

      return result;
    } catch (e, stackTrace) {
      logger.e('이미지 로딩 중 오류 발생: $imageUrl', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 이미지 처리(크기 조정, 변환, 필터 등) 작업을 프로파일링합니다.
  static Future<Uint8List> profileImageProcessing({
    required String operationName,
    required Uint8List inputImage,
    required Future<Uint8List> Function() processFunction,
    WidgetRef? ref,
  }) async {
    final profiler = ref?.read(memoryProfilerProvider.notifier) ?? null;

    // 프로파일러가 비활성화된 경우 직접 함수 실행
    if (profiler == null || !profiler.state.isEnabled) {
      return processFunction();
    }

    final metadata = {
      'type': 'image_processing',
      'operation': operationName,
      'inputSizeBytes': inputImage.length,
    };

    try {
      // 작업 전후 메모리 상태 비교
      final beforeLabel = 'image_process_${operationName}_before';
      final afterLabel = 'image_process_${operationName}_after';

      profiler.takeSnapshot(beforeLabel, metadata: metadata);
      final result = await processFunction();

      // 출력 이미지 크기 추가
      metadata['outputSizeBytes'] = result.length;
      profiler.takeSnapshot(afterLabel, metadata: metadata);

      // 차이 계산 및 로깅
      final diff = profiler.calculateDiff(beforeLabel, afterLabel);
      if (diff != null) {
        final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
        if (heapDiffMB > 10) {
          // 10MB 이상 메모리 사용시 경고 로그
          logger.w('이미지 처리 ($operationName)에 많은 메모리 사용: ${heapDiffMB}MB');
        }
      }

      return result;
    } catch (e, stackTrace) {
      logger.e('이미지 처리 중 오류 발생: $operationName',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 이미지 캐시에 이미지가 추가될 때 호출됩니다.
  static void onImageCached({
    required String imageUrl,
    required int sizeByte,
    WidgetRef? ref,
  }) {
    final profiler = ref?.read(memoryProfilerProvider.notifier) ?? null;

    // 프로파일러가 비활성화된 경우 아무 작업 안함
    if (profiler == null || !profiler.state.isEnabled) {
      return;
    }

    final metadata = {
      'type': 'image_cache',
      'action': 'add',
      'imageUrl': imageUrl,
      'sizeBytes': sizeByte,
    };

    profiler.takeSnapshot(
        'image_cached_${DateTime.now().millisecondsSinceEpoch}',
        metadata: metadata);

    // 크기가 1MB 이상인 큰 이미지는 로그로 기록
    if (sizeByte > 1024 * 1024) {
      logger.i('큰 이미지 캐싱: $imageUrl - ${sizeByte ~/ 1024}KB');
    }
  }

  /// 전체 이미지 캐시가 지워질 때 호출됩니다.
  static void onImageCacheCleared({
    int? previousSizeBytes,
    int? previousImageCount,
    WidgetRef? ref,
  }) {
    final profiler = ref?.read(memoryProfilerProvider.notifier) ?? null;

    // 프로파일러가 비활성화된 경우 아무 작업 안함
    if (profiler == null || !profiler.state.isEnabled) {
      return;
    }

    final metadata = {
      'type': 'image_cache',
      'action': 'clear',
      'previousSizeBytes': previousSizeBytes,
      'previousImageCount': previousImageCount,
    };

    profiler.takeSnapshot('image_cache_cleared', metadata: metadata);
    logger.i(
        '이미지 캐시 초기화: ${previousSizeBytes != null ? '${previousSizeBytes ~/ 1024}KB' : '알 수 없음'}, ${previousImageCount ?? 0}개 이미지');
  }

  /// 이미지 크롭 작업을 프로파일링합니다.
  static Future<T> profileImageCropping<T>({
    required String sourcePath,
    required Future<T> Function() cropFunction,
    WidgetRef? ref,
    CropAspectRatio? aspectRatio,
  }) async {
    final profiler = ref?.read(memoryProfilerProvider.notifier) ?? null;

    // 프로파일러가 비활성화된 경우 직접 함수 실행
    if (profiler == null || !profiler.state.isEnabled) {
      return cropFunction();
    }

    final metadata = {
      'type': 'image_cropping',
      'sourcePath': sourcePath,
      'aspectRatio': aspectRatio != null
          ? '${aspectRatio.ratioX}:${aspectRatio.ratioY}'
          : 'free',
    };

    try {
      // 크롭 작업 전후 메모리 상태 비교
      final beforeLabel =
          'image_crop_before_${DateTime.now().millisecondsSinceEpoch}';
      final afterLabel =
          'image_crop_after_${DateTime.now().millisecondsSinceEpoch}';

      profiler.takeSnapshot(beforeLabel,
          level: MemoryProfiler.snapshotLevelHigh, metadata: metadata);
      final result = await cropFunction();

      // 결과에 따라 메타데이터 업데이트
      final successMetadata = {...metadata};
      successMetadata['success'] = result != null ? 'true' : 'false';
      profiler.takeSnapshot(afterLabel,
          level: MemoryProfiler.snapshotLevelHigh, metadata: successMetadata);

      // 차이 계산 및 로깅
      final diff = profiler.calculateDiff(beforeLabel, afterLabel);
      if (diff != null) {
        final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
        if (heapDiffMB > 15) {
          // 크롭 작업은 메모리를 많이 사용하므로 임계값을 높게 설정
          logger.w('이미지 크롭에 많은 메모리 사용: ${sourcePath} - ${heapDiffMB}MB');
        }
      }

      return result;
    } catch (e, stackTrace) {
      logger.e('이미지 크롭 중 오류 발생: $sourcePath', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 이미지 압축 작업을 프로파일링합니다.
  static Future<Uint8List> profileImageCompression({
    required Uint8List inputImage,
    required Future<Uint8List> Function() compressFunction,
    required String reason,
    WidgetRef? ref,
  }) async {
    final profiler = ref?.read(memoryProfilerProvider.notifier) ?? null;

    // 프로파일러가 비활성화된 경우 직접 함수 실행
    if (profiler == null || !profiler.state.isEnabled) {
      return compressFunction();
    }

    final metadata = {
      'type': 'image_compression',
      'reason': reason,
      'inputSizeBytes': inputImage.length,
    };

    try {
      // 압축 작업 전후 메모리 상태 비교
      final beforeLabel =
          'image_compress_before_${DateTime.now().millisecondsSinceEpoch}';
      final afterLabel =
          'image_compress_after_${DateTime.now().millisecondsSinceEpoch}';

      profiler.takeSnapshot(beforeLabel, metadata: metadata);
      final result = await compressFunction();

      // 출력 이미지 크기 추가
      final resultMetadata = {...metadata};
      resultMetadata['outputSizeBytes'] = result.length;
      resultMetadata['compressionRatio'] = inputImage.length / result.length;
      profiler.takeSnapshot(afterLabel, metadata: resultMetadata);

      // 차이 계산 및 로깅
      final diff = profiler.calculateDiff(beforeLabel, afterLabel);
      if (diff != null) {
        final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
        if (heapDiffMB > 10) {
          logger.w('이미지 압축에 많은 메모리 사용: $reason - ${heapDiffMB}MB');
        }
      }

      // 압축 결과 로깅
      final inputMB = inputImage.length / (1024 * 1024);
      final outputMB = result.length / (1024 * 1024);
      final ratio = inputImage.length / result.length;
      logger.i(
          '이미지 압축 결과: $reason - ${inputMB.toStringAsFixed(2)}MB → ${outputMB.toStringAsFixed(2)}MB (${ratio.toStringAsFixed(1)}x)');

      return result;
    } catch (e, stackTrace) {
      logger.e('이미지 압축 중 오류 발생: $reason', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 이미지 디코딩 작업을 프로파일링합니다.
  static Future<T> profileImageDecoding<T>({
    required String source,
    required Future<T> Function() decodeFunction,
    WidgetRef? ref,
  }) async {
    final profiler = ref?.read(memoryProfilerProvider.notifier) ?? null;

    // 프로파일러가 비활성화된 경우 직접 함수 실행
    if (profiler == null || !profiler.state.isEnabled) {
      return decodeFunction();
    }

    final metadata = {
      'type': 'image_decoding',
      'source': source,
    };

    try {
      // 디코딩 작업 전후 메모리 상태 비교
      final beforeLabel =
          'image_decode_before_${DateTime.now().millisecondsSinceEpoch}';
      final afterLabel =
          'image_decode_after_${DateTime.now().millisecondsSinceEpoch}';

      profiler.takeSnapshot(beforeLabel, metadata: metadata);
      final result = await decodeFunction();
      profiler.takeSnapshot(afterLabel, metadata: metadata);

      // 차이 계산 및 로깅
      final diff = profiler.calculateDiff(beforeLabel, afterLabel);
      if (diff != null) {
        final heapDiffMB = diff.heapDiff.used ~/ (1024 * 1024);
        if (heapDiffMB > 8) {
          logger.w('이미지 디코딩에 많은 메모리 사용: $source - ${heapDiffMB}MB');
        }
      }

      return result;
    } catch (e, stackTrace) {
      logger.e('이미지 디코딩 중 오류 발생: $source', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

/// CropAspectRatio 클래스 정의
/// 이미지 크롭 작업에서 사용하는 애스펙트 비율 정보
class CropAspectRatio {
  final double ratioX;
  final double ratioY;

  const CropAspectRatio({
    required this.ratioX,
    required this.ratioY,
  });
}
