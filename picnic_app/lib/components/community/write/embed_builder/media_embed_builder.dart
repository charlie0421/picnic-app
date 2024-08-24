import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:video_player/video_player.dart';

class LocalImageEmbedBuilder extends EmbedBuilder {
  final bool isUploading;
  final double uploadProgress;

  LocalImageEmbedBuilder({this.isUploading = false, this.uploadProgress = 0.0});

  @override
  String get key => 'local-image';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final filePath = node.value.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;
    return Stack(
      children: [
        SizedBox(
          width: width,
          child: Image.file(File(filePath), fit: BoxFit.contain),
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: uploadProgress),
                  const SizedBox(height: 10),
                  Text(
                    'Uploading ${(uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class NetworkImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final imageUrl = node.value.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;
    return SizedBox(
      width: width,
      child: Image.network(imageUrl, fit: BoxFit.contain),
    );
  }
}

class LocalVideoEmbedBuilder extends EmbedBuilder {
  final bool isUploading;
  final double uploadProgress;

  LocalVideoEmbedBuilder({this.isUploading = false, this.uploadProgress = 0.0});

  @override
  String get key => 'local-video';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final filePath = node.value.data;
    final VideoPlayerController videoController =
        VideoPlayerController.file(File(filePath));
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;

    return Stack(
      children: [
        FutureBuilder(
          future: videoController.initialize(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return SizedBox(
                width: width,
                child: AspectRatio(
                  aspectRatio: videoController.value.aspectRatio,
                  child: VideoPlayer(videoController),
                ),
              );
            } else {
              return SizedBox(
                width: width,
                height: width * 9 / 16,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
        if (isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: uploadProgress),
                  const SizedBox(height: 10),
                  Text(
                    'Uploading ${(uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.grey00),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class NetworkVideoEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.videoType;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final videoUrl = node.value.data;
    final VideoPlayerController videoController =
        VideoPlayerController.network(videoUrl);
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;

    return FutureBuilder(
      future: videoController.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            ),
          );
        } else {
          return SizedBox(
            width: width,
            height: width * 9 / 16,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
