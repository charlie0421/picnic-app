import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/pic/image_overlay_painter.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final ui.Image? overlayImage;
  final GlobalKey repaintBoundaryKey;
  final bool cameraInitialized;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.overlayImage,
    required this.repaintBoundaryKey,
    required this.cameraInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        child: RepaintBoundary(
          key: repaintBoundaryKey,
          child: Stack(
            children: [
              if (cameraInitialized)
                Positioned.fill(
                  child: CameraPreview(controller!),
                ),
              if (overlayImage != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ImageOverlayPainter(overlayImage: overlayImage),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
