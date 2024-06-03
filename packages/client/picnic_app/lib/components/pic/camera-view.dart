import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:picnic_app/components/loading_view.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/style.dart';

import '../../providers/pic_provider.dart';

class PicCameraView extends ConsumerStatefulWidget {
  const PicCameraView({super.key});

  @override
  ConsumerState<PicCameraView> createState() => _PicCameraViewState();
}

class _PicCameraViewState extends ConsumerState<PicCameraView> {
  ui.Image? _overlayImage;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  List<CameraDescription>? cameras;
  CameraController? controller;
  FlashMode flashMode = FlashMode.auto;
  int setTimer = 3;
  int remainTime = 0;
  Timer? _timer;
  Uint8List? _capturedImageBytes;
  Color _previewBackgroundColor = Colors.transparent;
  bool _cameraInitialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    ref.read(userImageProvider);
    ref.read(convertedImageProvider);
    Future.delayed(const Duration(milliseconds: 300), () {
      _initializeCameras();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60.h,
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.close, size: 36),
            color: AppColors.Gray900,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            child: AspectRatio(
              aspectRatio: 5.5 / 8.5,
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Stack(
                  children: [
                    if (_cameraInitialized)
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        color: _previewBackgroundColor,
                        child: AspectRatio(
                          aspectRatio: 5.5 / 8.5,
                          child: CameraPreview(
                            controller!,
                            child: CustomPaint(
                              painter: OverlayImagePainter(
                                  overlayImage: _overlayImage),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.Gray00,
                        child: const Center(
                          child: LoadingView(),
                        ),
                      ),

                    // Container(
                    //   color: AppColors.Gray00,
                    //   child: CustomPaint(
                    //     size: Size.infinite,
                    //     painter:
                    //         OverlayImagePainter(overlayImage: _overlayImage),
                    //   ),
                    // ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        remainTime == 0 ? '' : '$remainTime',
                        style: TextStyle(
                          color: AppColors.Primary500,
                          fontSize: 100.sp,
                        ),
                      ),
                    ),
                    if (!_saving)
                      Positioned(
                        left: 16.w,
                        top: 16.h,
                        bottom: 16.h,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: flashMode == FlashMode.auto
                                      ? const Icon(Icons.flash_auto,
                                          color: AppColors.Primary500)
                                      : flashMode == FlashMode.torch
                                          ? const Icon(Icons.flash_on,
                                              color: AppColors.Primary500)
                                          : const Icon(
                                              Icons.flash_off,
                                              color: AppColors.Primary500,
                                            ),
                                  iconSize: 24,
                                  color: AppColors.Primary500,
                                  onPressed: () {
                                    if (flashMode == FlashMode.auto) {
                                      _setFlashMode(FlashMode.torch);
                                    } else if (flashMode == FlashMode.torch) {
                                      _setFlashMode(FlashMode.off);
                                    } else {
                                      _setFlashMode(FlashMode.auto);
                                    }
                                  },
                                ),
                                Text('플래시',
                                    style: getTextStyle(
                                        AppTypo.BODY14B, AppColors.Primary500),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            GestureDetector(
                              onTap: () {
                                if (setTimer == 3) {
                                  setState(() {
                                    setTimer = 7;
                                  });
                                } else if (setTimer == 7) {
                                  setState(() {
                                    setTimer = 10;
                                  });
                                } else {
                                  setState(() {
                                    setTimer = 3;
                                  });
                                }
                              },
                              child: Column(
                                children: [
                                  Text('${setTimer}s',
                                      style: getTextStyle(AppTypo.TITLE18B,
                                          AppColors.Primary500),
                                      textAlign: TextAlign.center),
                                  Text('타이머',
                                      style: getTextStyle(AppTypo.BODY14B,
                                          AppColors.Primary500),
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.change_circle,
                                      color: AppColors.Primary500),
                                  iconSize: 36,
                                  color: AppColors.Primary500,
                                  onPressed: () async {
                                    _toggleCamera();
                                  },
                                ),
                                Text('카메라\n전환',
                                    style: getTextStyle(
                                        AppTypo.BODY14B, AppColors.Primary500),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          height: 80.h,
          margin:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: GestureDetector(
            onTap: () async {
              setState(() {
                remainTime = setTimer;
                _saving = true;
              });

              _timer =
                  Timer.periodic(const Duration(seconds: 1), (timer) async {
                if (remainTime > 0) {
                  setState(() {
                    remainTime--;
                    _previewBackgroundColor =
                        _previewBackgroundColor == Colors.transparent
                            ? Colors.white
                            : Colors.transparent;
                  });
                } else {
                  timer.cancel();

                  if (controller != null) {
                    controller!.pausePreview();
                  }

                  await _captureImage();
                  setState(() {
                    _previewBackgroundColor = Colors.transparent;
                    _saving = false;
                  });
                }
              });
            },
            child: Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.Gray00,
                border: Border.all(
                  color: AppColors.Mint500,
                  width: 10.w,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadOverlayImage() async {
    final ByteData data = await rootBundle.load(
        'assets/mockup/pic/che${ref.watch(picSelectedIndexProvider) + 1}.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final img.Image image = img.decodeImage(bytes)!;
    final uiImage = await _convertImage(image);
    setState(() {
      _overlayImage = uiImage;
    });
  }

  Future<ui.Image> _convertImage(img.Image image) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.fromList(img.encodePng(image)), (uiImage) {
      completer.complete(uiImage);
    });
    return completer.future;
  }

  Future<void> _initializeCameras() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      await _setCamera(cameras!.first);
    }

    setState(() {
      _cameraInitialized = true;
    });

    await _loadOverlayImage(); // 오버레이 이미지를 항상 로드
  }

  void _toggleCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    final currentDirection = controller!.description.lensDirection;
    CameraDescription? newCameraDescription;

    // 현재 카메라와 반대 방향의 카메라를 찾습니다.
    if (currentDirection == CameraLensDirection.back) {
      newCameraDescription = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );
    } else {
      newCameraDescription = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras!.first,
      );
    }

    // 현재 카메라 컨트롤러 해제
    await controller?.dispose();

    // 새 카메라 컨트롤러 설정
    CameraController newController = CameraController(
      newCameraDescription,
      ResolutionPreset.max,
    );

    // 새 컨트롤러로 초기화
    await newController.initialize();

    // 상태 업데이트
    setState(() {
      controller = newController;
    });
  }

  void _setFlashMode(FlashMode mode) {
    if (controller != null) {
      controller!.setFlashMode(mode);
    }
    setState(() {
      flashMode = mode;
    });
  }

  Future<void> _setCamera(CameraDescription cameraDescription) async {
    logger.i('cameraDescription: $cameraDescription');
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
    );

    await controller?.dispose();

    controller = cameraController;

    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {});
      });
    });
  }

  Future<void> _captureImage() async {
    try {
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      _capturedImageBytes = byteData!.buffer.asUint8List();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: _capturedImageBytes != null
                ? Image.memory(_capturedImageBytes!)
                : Container(),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _saveImage();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> _saveImage() async {
    try {
      if (_capturedImageBytes != null) {
        final result = await ImageGallerySaver.saveImage(
          _capturedImageBytes!,
          quality: 100,
          name: 'captured_image',
        );

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved to gallery')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save image')),
          );
        }

        setState(() {
          _saving = false;
        });
        Navigator.pop(context);
      }
    } catch (e) {
      logger.e(e);
    }
  }
}

class OverlayImagePainter extends CustomPainter {
  final ui.Image? overlayImage;

  OverlayImagePainter({this.overlayImage});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (overlayImage != null) {
      // 원본 이미지의 전체 영역
      final srcRect = Rect.fromLTWH(0, 0, overlayImage!.width.toDouble(),
          overlayImage!.height.toDouble());

      // 카메라 프리뷰의 높이에 맞는 목표 영역
      final targetWidth =
          size.height * overlayImage!.width / overlayImage!.height;
      final offsetX = (size.width - targetWidth) / 2; // 이미지를 중앙으로 이동
      final offsetY = 0.0; // 이미지를 상단으로 이동
      final dstRect = Rect.fromLTWH(offsetX, offsetY, targetWidth, size.height);

      // 원본 이미지의 전체 영역을 목표 영역에 그립니다.
      canvas.drawImageRect(overlayImage!, srcRect, dstRect, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
