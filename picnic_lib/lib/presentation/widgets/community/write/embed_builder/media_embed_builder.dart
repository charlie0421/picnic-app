import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/image_processing_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/widgets/lazy_image_widget.dart';
import 'package:picnic_lib/presentation/widgets/ui/s3_uploader.dart';
import 'package:universal_io/io.dart';

class LocalImageEmbedBuilder extends EmbedBuilder {
  final Function(String localPath, String networkUrl) onUploadComplete;
  final S3Uploader _s3Uploader;

  LocalImageEmbedBuilder({required this.onUploadComplete})
      : _s3Uploader = S3Uploader(
          accessKey: Environment.awsAccessKey,
          secretKey: Environment.awsSecretKey,
          region: Environment.awsRegion,
          bucketName: Environment.awsBucket,
        );

  @override
  String get key => 'local-image';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final imageUrl = node.value.data;
    return FutureBuilder<String>(
      future: _uploadImage(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Uploading...'),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          logger.i('Error in FutureBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 10),
                const Text('Upload failed. Tap to retry.'),
                const SizedBox(height: 10),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          logger.i('Network URL received: ${snapshot.data}');
          return Image.network(
            snapshot.data!,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              logger.i('Error loading image: $error');
              return Text('Error loading image: $error');
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<String> _uploadImage(String source) async {
    try {
      final imageProcessingService = ImageProcessingService();
      Uint8List originalBytes;

      if (kIsWeb) {
        // 웹 환경에서는 URL로부터 이미지 데이터를 가져옵니다
        final response = await http.get(Uri.parse(source));
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch image data');
        }
        originalBytes = response.bodyBytes;
      } else {
        // 모바일/데스크톱용 파일 처리 로직
        final file = File(source);
        if (!await file.exists()) {
          throw Exception('File does not exist: $source');
        }
        originalBytes = await file.readAsBytes();
      }

      // ImageProcessingService를 사용하여 이미지 최적화
      // 포스트 이미지용 최적화: 1200x1200 최대 크기, 80% 품질
      final Uint8List? optimizedBytes =
          await imageProcessingService.processImage(
        originalBytes,
        maxWidth: 1200,
        maxHeight: 1200,
        quality: 80,
        outputFormat: 'jpeg',
        maintainAspectRatio: true,
      );

      if (optimizedBytes == null) {
        throw Exception('Failed to process image');
      }

      // 최적화 결과 로깅
      final originalSize = originalBytes.length;
      final optimizedSize = optimizedBytes.length;
      final compressionRatio = (1 - optimizedSize / originalSize) * 100;

      logger.i(
          '포스트 이미지 최적화 완료: ${originalSize ~/ 1024}KB → ${optimizedSize ~/ 1024}KB (${compressionRatio.toStringAsFixed(1)}% 압축)');

      // 최적화된 이미지를 S3에 업로드
      final mediaUrl = await _s3Uploader.uploadFile(
        'post/image',
        optimizedBytes,
        (progress) {
          logger.i('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        },
      );

      onUploadComplete(source, mediaUrl);
      return mediaUrl;
    } catch (e, s) {
      logger.i('Error uploading image', error: e, stackTrace: s);
      rethrow;
    }
  }
}

class NetworkImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final imageUrl = node.value.data;
    final screenWidth = getPlatformScreenSize(context).width;
    final width = screenWidth / 2;
    return SizedBox(
      width: width,
      child: LazyImageWidget(
        imageUrl: imageUrl,
        width: getPlatformScreenSize(context).width.toInt() - 10,
        fit: BoxFit.contain,
      ),
    );
  }
}
