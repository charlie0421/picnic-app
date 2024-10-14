import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:picnic_app/components/ui/s3_uploader.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/util/ui.dart';

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
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
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
          print('Error in FutureBuilder: ${snapshot.error}');
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
          print('Network URL received: ${snapshot.data}');
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
              print('Error loading image: $error');
              return Text('Error loading image: $error');
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<String> _uploadImage(String localPath) async {
    try {
      final file = File(localPath);

      if (!await file.exists()) {
        throw Exception('File does not exist: $localPath');
      }

      final streamController = StreamController<double>();

      final mediaUrl = await _s3Uploader.uploadFile(
        'post/image',
        file,
        (progress) {
          streamController.add(progress);
          print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        },
      );

      streamController.close();

      print('Upload completed. Media URL: $mediaUrl');
      onUploadComplete(localPath, mediaUrl);
      return mediaUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}

class NetworkImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final imageUrl = node.value.data;
    final screenWidth = getPlatformScreenSize(context).width;
    final width = screenWidth / 2;
    return SizedBox(
      width: width,
      child: Image.network(imageUrl, fit: BoxFit.contain),
    );
  }
}
