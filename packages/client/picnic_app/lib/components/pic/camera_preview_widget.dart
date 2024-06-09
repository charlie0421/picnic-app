import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;

import 'package:picnic_app/components/pic/image_overlay_painter.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final ui.Image? overlayImage;
  final GlobalKey repaintBoundaryKey;
  final bool cameraInitialized;

  const CameraPreviewWidget({
    Key? key,
    required this.controller,
    required this.overlayImage,
    required this.repaintBoundaryKey,
    required this.cameraInitialized,
  }) : super(key: key);

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
