import 'dart:io';

import 'package:flutter/material.dart';

class ImageThumbnailFromUrl extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;
  final Widget? loading;

  const ImageThumbnailFromUrl({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return loading ?? const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
    );

    if (borderRadius != null && borderRadius! > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: image,
      );
    }
    return image;
  }
}

class ImageThumbnailFromFile extends StatelessWidget {
  final File file;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;
  final Widget? loading;

  const ImageThumbnailFromFile({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
    );

    if (borderRadius != null && borderRadius! > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: image,
      );
    }
    return image;
  }
}
