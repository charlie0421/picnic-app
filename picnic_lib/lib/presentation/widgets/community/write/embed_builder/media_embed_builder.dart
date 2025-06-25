import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
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
          return Container(
            width: double.infinity,
            height: 200,
            child: buildLoadingOverlay(),
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
      if (kIsWeb) {
        // 웹 환경에서는 URL로부터 이미지 데이터를 가져옵니다
        final response = await http.get(Uri.parse(source));
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch image data');
        }

        final Uint8List bytes = response.bodyBytes;
        final mediaUrl = await _s3Uploader.uploadFile(
          'post/image',
          bytes,
          (progress) {
            logger
                .i('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          },
        );

        onUploadComplete(source, mediaUrl);
        return mediaUrl;
      } else {
        // 모바일/데스크톱용 파일 처리 로직
        final file = File(source);
        if (!await file.exists()) {
          throw Exception('File does not exist: $source');
        }

        final streamController = StreamController<double>();

        final mediaUrl = await _s3Uploader.uploadFile(
          'post/image',
          file,
          (progress) {
            streamController.add(progress);
            logger
                .i('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          },
        );

        streamController.close();
        onUploadComplete(source, mediaUrl);
        return mediaUrl;
      }
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
      child: PicnicCachedNetworkImage(
          imageUrl: imageUrl,
          width: getPlatformScreenSize(context).width.toInt() - 10,
          fit: BoxFit.contain),
    );
  }
}
