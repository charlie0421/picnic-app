import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
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
  ui.Image? _convertedUserImage; // 변환된 사용자 이미지
  List<CameraDescription>? cameras;
  CameraController? controller;
  FlashMode flashMode = FlashMode.auto;
  int setTimer = 3;
  int remainTime = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    ref.read(userImageProvider);
    ref.read(convertedImageProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOverlayImage();
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
        Container(
          alignment: Alignment.topCenter,
          child: AspectRatio(
            aspectRatio: 5.5 / 8.5,
            child: Stack(
              children: [
                controller != null
                    ? Container(
                        alignment: Alignment.center,
                        child: CameraPreview(
                          controller!,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: OverlayImagePainter(
                                overlayImage: _overlayImage),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.black,
                      ),
                // GridView.count(
                //   crossAxisCount: 3,
                //   childAspectRatio: 5.5 / 8.5,
                //   children: List.generate(9, (index) {
                //     return Container(
                //         decoration: BoxDecoration(
                //           border: Border.all(
                //               color: AppColors.Primary500.withOpacity(0.5)),
                //         ),
                //         child: Center(
                //             child: index == 4
                //                 ? Text('${remainTime == 0 ? '' : '$remainTime'}',
                //                     style: TextStyle(
                //                         color: AppColors.Gray00, fontSize: 40.sp))
                //                 : Container()));
                //   }),
                // ),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    '${remainTime == 0 ? '' : '$remainTime'}',
                    style: TextStyle(
                      color: AppColors.Gray00,
                      fontSize: 80.sp,
                    ),
                  ),
                ),
                Positioned(
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
                                    color: AppColors.Gray00)
                                : flashMode == FlashMode.torch
                                    ? const Icon(Icons.flash_on,
                                        color: AppColors.Gray00)
                                    : const Icon(Icons.flash_off,
                                        color: AppColors.Gray00),
                            iconSize: 24,
                            color: AppColors.Gray00,
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
                                  AppTypo.BODY14R, AppColors.Gray00),
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
                                style: getTextStyle(
                                    AppTypo.TITLE18B, AppColors.Gray00),
                                textAlign: TextAlign.center),
                            Text('타이머',
                                style: getTextStyle(
                                    AppTypo.BODY14R, AppColors.Gray00),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      IconButton(
                        icon: const Icon(Icons.change_circle,
                            color: AppColors.Gray00),
                        iconSize: 36,
                        color: AppColors.Gray00,
                        onPressed: () async {
                          _toggleCamera();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () async {
              setState(() {
                remainTime = setTimer;
              });

              _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                logger.i('remainTime: $remainTime');
                if (remainTime > 0) {
                  setState(() {
                    remainTime--;
                  });
                } else {
                  timer.cancel();
                  _synthesizeImage();
                }
              });
            },
            child: const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.Mint500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _synthesizeImage() async {
    if (controller == null) return;
    try {
      OverlayLoadingProgress.start(context);

      final XFile file = await controller!.takePicture();
      final img.Image image = img.decodeImage(await file.readAsBytes())!;
      final uiImage = await _convertImage(image);
      ref.read(userImageProvider.notifier).state = File(file.path);
      ref.read(convertedImageProvider.notifier).state = File(file.path);
      // _userImage = File(file.path);
      // _convertedUserImage = uiImage;
      Navigator.pop(context);
    } catch (e) {
      logger.e(e);
    } finally {
      OverlayLoadingProgress.stop();
    }
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
      final offsetX = size.width - targetWidth; // 이미지를 우측으로 이동
      final offsetY = size.height - size.height; // 이미지를 하단으로 이동
      final dstRect = Rect.fromLTWH(offsetX, offsetY, targetWidth, size.height);

      // 원본 이미지의 전체 영역을 목표 영역에 그립니다.
      canvas.drawImageRect(overlayImage!, srcRect, dstRect, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
