import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
