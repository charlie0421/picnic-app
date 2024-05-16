import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ImageComposer extends CustomPainter {
  final ui.Image userImage;
  final ui.Image overlayImage;
  final double overlayImageWidth; // 오버레이 이미지의 너비
  final double overlayImageHeight; // 오버레이 이미지의 높이

  ImageComposer({
    required this.userImage,
    required this.overlayImage,
    required this.overlayImageWidth,
    required this.overlayImageHeight,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // 사용자가 선택한 이미지를 그립니다.
    final userImagePaint = Paint();
    canvas.drawImageRect(
      userImage,
      ui.Rect.fromLTWH(0, 0, userImage.width.toDouble(), userImage.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      userImagePaint,
    );

    // 미리 정의된 이미지를 오버레이 합니다.
    final overlayImagePaint = Paint();
    canvas.drawImageRect(
      overlayImage,
      ui.Rect.fromLTWH(0, 0, overlayImageWidth, overlayImageHeight),
      ui.Rect.fromLTWH(
        (size.width - overlayImageWidth) / 2,
        (size.height - overlayImageHeight) / 2,
        overlayImageWidth,
        overlayImageHeight,
      ),
      overlayImagePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}