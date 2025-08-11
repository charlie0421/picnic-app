import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailFromUrl extends StatefulWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? loading;

  const VideoThumbnailFromUrl({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loading,
  });

  @override
  State<VideoThumbnailFromUrl> createState() => _VideoThumbnailFromUrlState();
}

class _VideoThumbnailFromUrlState extends State<VideoThumbnailFromUrl> {
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final thumbnailData = await VideoThumbnail.thumbnailData(
      video: widget.videoUrl,
      imageFormat: ImageFormat.PNG,
      maxWidth: ((widget.width ?? 160).toInt()) * 2,
      quality: 25,
    );
    if (!mounted) return;
    setState(() {
      _thumbnailData = thumbnailData;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailData == null) {
      return Center(child: widget.loading ?? const SizedBox.shrink());
    }
    return Image.memory(
      _thumbnailData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

class VideoThumbnailFromFile extends StatefulWidget {
  final String filePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? loading;

  VideoThumbnailFromFile({
    super.key,
    required File file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loading,
  }) : filePath = file.path;

  @override
  State<VideoThumbnailFromFile> createState() => _VideoThumbnailFromFileState();
}

class _VideoThumbnailFromFileState extends State<VideoThumbnailFromFile> {
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final thumbnailData = await VideoThumbnail.thumbnailData(
      video: widget.filePath,
      imageFormat: ImageFormat.PNG,
      maxWidth: ((widget.width ?? 160).toInt()),
      quality: 25,
    );
    if (!mounted) return;
    setState(() {
      _thumbnailData = thumbnailData;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailData == null) {
      return Center(child: widget.loading ?? const SizedBox.shrink());
    }
    return Image.memory(
      _thumbnailData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
