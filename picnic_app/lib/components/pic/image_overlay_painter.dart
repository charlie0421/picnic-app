import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ImageOverlayPainter extends CustomPainter {
  final ui.Image? overlayImage;

  ImageOverlayPainter({this.overlayImage});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (overlayImage != null) {
      final srcRect = Rect.fromLTWH(0, 0, overlayImage!.width.toDouble(),
          overlayImage!.height.toDouble());
      final targetWidth =
          size.height * overlayImage!.width / overlayImage!.height;
      final offsetX = (size.width - targetWidth) / 2;
      const offsetY = 0.0;
      final dstRect = Rect.fromLTWH(offsetX, offsetY, targetWidth, size.height);

      canvas.drawImageRect(overlayImage!, srcRect, dstRect, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
