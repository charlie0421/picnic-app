import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:universal_platform/universal_platform.dart';

/// 이미지 처리 서비스
/// 이미지 리사이징, 압축, 포맷 변환 등의 기능을 제공합니다.
class ImageProcessingService {
  static final ImageProcessingService _instance =
      ImageProcessingService._internal();
  factory ImageProcessingService() => _instance;
  ImageProcessingService._internal();

  /// 이미지 리사이징 및 압축
  Future<Uint8List?> processImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
    String? outputFormat,
    bool maintainAspectRatio = true,
  }) async {
    try {
      // 이미지 디코딩
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        logger.e('이미지 디코딩 실패');
        return null;
      }

      // 원본 크기 정보
      final originalWidth = image.width;
      final originalHeight = image.height;
      final originalSize = imageBytes.length;

      logger.d(
          '원본 이미지: ${originalWidth}x$originalHeight, ${originalSize ~/ 1024}KB');

      // 리사이징이 필요한지 확인
      img.Image processedImage = image;

      if (maxWidth != null || maxHeight != null) {
        final targetSize = _calculateTargetSize(
          originalWidth,
          originalHeight,
          maxWidth,
          maxHeight,
          maintainAspectRatio,
        );

        if (targetSize.width.toInt() != originalWidth ||
            targetSize.height.toInt() != originalHeight) {
          processedImage = img.copyResize(
            image,
            width: targetSize.width.toInt(),
            height: targetSize.height.toInt(),
            interpolation: img.Interpolation.cubic,
          );

          logger.d(
              '이미지 리사이징: ${targetSize.width.toInt()}x${targetSize.height.toInt()}');
        }
      }

      // 출력 포맷 결정
      final format = outputFormat ?? _determineOptimalFormat(imageBytes);

      // 이미지 인코딩
      Uint8List? compressedBytes;

      switch (format) {
        case 'jpeg':
          compressedBytes = Uint8List.fromList(
              img.encodeJpg(processedImage, quality: quality));
          break;
        case 'png':
          compressedBytes =
              Uint8List.fromList(img.encodePng(processedImage, level: 6));
          break;
        case 'webp':
          // WebP 인코딩은 플랫폼에 따라 다르게 처리
          if (UniversalPlatform.isWeb || UniversalPlatform.isAndroid) {
            compressedBytes = Uint8List.fromList(img.encodeJpg(processedImage,
                quality: quality)); // WebP 대신 JPEG 사용
          } else {
            compressedBytes = Uint8List.fromList(
                img.encodeJpg(processedImage, quality: quality));
          }
          break;
        default:
          compressedBytes = Uint8List.fromList(
              img.encodeJpg(processedImage, quality: quality));
      }

      final compressedSize = compressedBytes.length;
      final compressionRatio = (1 - compressedSize / originalSize) * 100;

      logger.d(
          '이미지 압축 완료: ${compressedSize ~/ 1024}KB (${compressionRatio.toStringAsFixed(1)}% 압축)');

      return compressedBytes;
    } catch (e, stackTrace) {
      logger.e('이미지 처리 실패', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 썸네일 생성
  Future<Uint8List?> generateThumbnail(
    Uint8List imageBytes, {
    int size = 150,
    int quality = 80,
  }) async {
    return processImage(
      imageBytes,
      maxWidth: size,
      maxHeight: size,
      quality: quality,
      outputFormat: 'jpeg',
      maintainAspectRatio: true,
    );
  }

  /// 다중 해상도 이미지 생성
  Future<Map<String, Uint8List>> generateMultipleResolutions(
    Uint8List imageBytes, {
    List<ImageResolution>? resolutions,
    int quality = 85,
  }) async {
    final defaultResolutions = resolutions ??
        [
          const ImageResolution('thumbnail', 150, 150),
          const ImageResolution('small', 300, 300),
          const ImageResolution('medium', 600, 600),
          const ImageResolution('large', 1200, 1200),
        ];

    final results = <String, Uint8List>{};

    for (final resolution in defaultResolutions) {
      final processedBytes = await processImage(
        imageBytes,
        maxWidth: resolution.width,
        maxHeight: resolution.height,
        quality: quality,
        maintainAspectRatio: true,
      );

      if (processedBytes != null) {
        results[resolution.name] = processedBytes;
      }
    }

    return results;
  }

  /// 이미지 메타데이터 추출
  ImageMetadata extractMetadata(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return const ImageMetadata(
          width: 0,
          height: 0,
          sizeBytes: 0,
          format: 'unknown',
        );
      }

      final format = _detectImageFormat(imageBytes);

      return ImageMetadata(
        width: image.width,
        height: image.height,
        sizeBytes: imageBytes.length,
        format: format,
        hasAlpha: image.hasAlpha,
        numChannels: image.numChannels,
      );
    } catch (e) {
      logger.e('메타데이터 추출 실패', error: e);
      return const ImageMetadata(
        width: 0,
        height: 0,
        sizeBytes: 0,
        format: 'unknown',
      );
    }
  }

  /// 이미지 포맷 감지
  String _detectImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'unknown';

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpeg';
    }

    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }

    // WebP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }

    // GIF
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'gif';
    }

    return 'unknown';
  }

  /// 최적 포맷 결정
  String _determineOptimalFormat(Uint8List imageBytes) {
    final format = _detectImageFormat(imageBytes);

    // WebP 지원 여부에 따라 결정
    if (UniversalPlatform.isWeb || UniversalPlatform.isAndroid) {
      // WebP를 지원하는 플랫폼
      if (format == 'png') {
        // PNG는 WebP로 변환하여 크기 절약
        return 'webp';
      } else {
        // JPEG는 그대로 유지
        return 'jpeg';
      }
    } else {
      // iOS 등 WebP 지원이 제한적인 플랫폼
      if (format == 'png') {
        return 'png';
      } else {
        return 'jpeg';
      }
    }
  }

  /// 타겟 크기 계산
  ui.Size _calculateTargetSize(
    int originalWidth,
    int originalHeight,
    int? maxWidth,
    int? maxHeight,
    bool maintainAspectRatio,
  ) {
    if (!maintainAspectRatio) {
      return ui.Size(
        (maxWidth ?? originalWidth).toDouble(),
        (maxHeight ?? originalHeight).toDouble(),
      );
    }

    double targetWidth = originalWidth.toDouble();
    double targetHeight = originalHeight.toDouble();

    if (maxWidth != null && targetWidth > maxWidth) {
      final ratio = maxWidth / targetWidth;
      targetWidth = maxWidth.toDouble();
      targetHeight = targetHeight * ratio;
    }

    if (maxHeight != null && targetHeight > maxHeight) {
      final ratio = maxHeight / targetHeight;
      targetHeight = maxHeight.toDouble();
      targetWidth = targetWidth * ratio;
    }

    return ui.Size(
        targetWidth.round().toDouble(), targetHeight.round().toDouble());
  }

  /// 메모리 효율적인 이미지 처리 (큰 이미지용)
  Future<Uint8List?> processLargeImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
    int chunkSize = 1024 * 1024, // 1MB 청크
  }) async {
    try {
      // 큰 이미지의 경우 단계적으로 처리
      final metadata = extractMetadata(imageBytes);

      if (metadata.sizeBytes > 10 * 1024 * 1024) {
        // 10MB 이상
        logger.i(
            '큰 이미지 감지 (${metadata.sizeBytes ~/ (1024 * 1024)}MB), 단계적 처리 시작');

        // 먼저 50% 크기로 축소
        final firstPass = await processImage(
          imageBytes,
          maxWidth: (metadata.width * 0.5).round(),
          maxHeight: (metadata.height * 0.5).round(),
          quality: 90,
        );

        if (firstPass == null) return null;

        // 그 다음 최종 크기로 조정
        return processImage(
          firstPass,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
      } else {
        // 일반 크기는 바로 처리
        return processImage(
          imageBytes,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
      }
    } catch (e) {
      logger.e('큰 이미지 처리 실패', error: e);
      return null;
    }
  }

  /// 배치 이미지 처리
  Future<List<Uint8List?>> processBatch(
    List<Uint8List> imageBytesList, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
    int maxConcurrency = 3,
  }) async {
    final results = <Uint8List?>[];

    // 동시 처리 수 제한
    for (int i = 0; i < imageBytesList.length; i += maxConcurrency) {
      final batch = imageBytesList.skip(i).take(maxConcurrency);

      final futures = batch.map((bytes) => processImage(
            bytes,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
          ));

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);
    }

    return results;
  }
}

/// 이미지 해상도 정의
class ImageResolution {
  final String name;
  final int width;
  final int height;

  const ImageResolution(this.name, this.width, this.height);
}

/// 이미지 메타데이터
class ImageMetadata {
  final int width;
  final int height;
  final int sizeBytes;
  final String format;
  final bool? hasAlpha;
  final int? numChannels;

  const ImageMetadata({
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.format,
    this.hasAlpha,
    this.numChannels,
  });

  double get aspectRatio => height > 0 ? width / height : 1.0;
  int get sizeMB => sizeBytes ~/ (1024 * 1024);
  int get sizeKB => sizeBytes ~/ 1024;
}

/// 이미지 처리 설정
class ImageProcessingConfig {
  final int defaultQuality;
  final int thumbnailSize;
  final int maxImageSize;
  final bool enableWebP;
  final bool enableProgressiveJpeg;

  const ImageProcessingConfig({
    this.defaultQuality = 85,
    this.thumbnailSize = 150,
    this.maxImageSize = 2048,
    this.enableWebP = true,
    this.enableProgressiveJpeg = true,
  });

  factory ImageProcessingConfig.mobile() {
    return const ImageProcessingConfig(
      defaultQuality: 80,
      thumbnailSize: 120,
      maxImageSize: 1024,
      enableWebP: true,
    );
  }

  factory ImageProcessingConfig.web() {
    return const ImageProcessingConfig(
      defaultQuality: 85,
      thumbnailSize: 150,
      maxImageSize: 2048,
      enableWebP: true,
    );
  }
}
