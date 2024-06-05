import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picnic_app/components/ui/large-popup.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/style.dart';

import '../../providers/pic_provider.dart';

enum Source { camera, gallery }

enum ViewMode { loading, ready, saving, timer }

class PicCameraViewPage extends ConsumerStatefulWidget {
  const PicCameraViewPage({super.key});

  @override
  ConsumerState<PicCameraViewPage> createState() => _PicCameraViewState();
}

class _PicCameraViewState extends ConsumerState<PicCameraViewPage> {
  ui.Image? _overlayImage;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  FlashMode _flashMode = FlashMode.auto;
  int _setTimer = 3;
  int _remainTime = 0;
  Timer? _timer;
  Uint8List? _capturedImageBytes;
  Color _previewBackgroundColor = Colors.transparent;
  bool _cameraInitialized = false;
  File? _recentImage;

  ViewMode _viewMode = ViewMode.loading;
  Source _source = Source.camera;

  @override
  void initState() {
    super.initState();

    ref.read(userImageProvider);
    ref.read(convertedImageProvider);
    _initializeCameras();
    _fetchRecentImage();
    _viewMode = ViewMode.ready;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: MediaQuery.of(context).padding,
        color: AppColors.Gray00,
        child: Column(
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
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Stack(
                    children: [
                      // 하단 레이어
                      if (_viewMode == ViewMode.ready ||
                          _viewMode == ViewMode.loading ||
                          _viewMode == ViewMode.saving ||
                          _viewMode == ViewMode.timer)
                        if (_cameraInitialized)
                          Container(
                            alignment: Alignment.center,
                            child: CameraPreview(
                              _controller!,
                              child: CustomPaint(
                                painter: OverlayImagePainter(
                                    overlayImage: _overlayImage),
                              ),
                            ),
                          ),
                      // 상단 레이어
                      if (_viewMode == ViewMode.loading)
                        Container(
                          color: Colors.transparent,
                          child: const Center(
                              child: Text('카메라 초기화중...',
                                  style: TextStyle(
                                      fontSize: 30,
                                      color: AppColors.Primary500))),
                        )
                      else if (_viewMode == ViewMode.timer)
                        AnimatedContainer(
                          alignment: Alignment.center,
                          duration: const Duration(milliseconds: 100),
                          color: _previewBackgroundColor,
                          child: Text(
                            _remainTime <= 300 ? '' : '${_remainTime ~/ 1000}',
                            style: TextStyle(
                              color: AppColors.Primary500,
                              fontSize: 100.sp,
                            ),
                          ),
                        )
                      else if (_viewMode == ViewMode.saving)
                        Container(
                            color: Colors.transparent,
                            child: const Center(
                                child: Text('사진 합성중...',
                                    style: TextStyle(
                                        fontSize: 30,
                                        color: AppColors.Primary500))))
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 100.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                      child: _recentImage == null
                          ? Container(
                              color: Colors.grey, width: 50.w, height: 50.w)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(_recentImage!,
                                  width: 50.w, height: 50.w, fit: BoxFit.cover),
                            )),
                  GestureDetector(
                    onTap: () {
                      if (_flashMode == FlashMode.auto) {
                        _setFlashMode(FlashMode.torch);
                      } else if (_flashMode == FlashMode.torch) {
                        _setFlashMode(FlashMode.off);
                      } else {
                        _setFlashMode(FlashMode.auto);
                      }
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.Gray500,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _flashMode == FlashMode.auto
                            ? Icons.flash_auto
                            : _flashMode == FlashMode.torch
                                ? Icons.flash_on
                                : Icons.flash_off,
                        color: AppColors.Gray00,
                        size: 25,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_viewMode == ViewMode.saving) return;

                      if (_viewMode == ViewMode.timer ||
                          _viewMode == ViewMode.saving) {
                        _timer?.cancel();
                        setState(() {
                          _viewMode = ViewMode.ready;
                        });
                        return;
                      }

                      setState(() {
                        _viewMode = ViewMode.timer;
                        _remainTime = _setTimer * 1000;
                      });

                      _timer = Timer.periodic(const Duration(milliseconds: 500),
                          (timer) async {
                        if (_remainTime > 0) {
                          setState(() {
                            _remainTime -= 500;
                            _previewBackgroundColor =
                                _previewBackgroundColor == Colors.transparent
                                    ? AppColors.Gray900.withOpacity(0.2)
                                    : Colors.transparent;
                          });
                        } else {
                          if (_controller != null) {
                            _controller!.pausePreview();
                          }

                          setState(() {
                            _previewBackgroundColor = Colors.transparent;
                            _viewMode = ViewMode.saving;
                          });

                          timer.cancel();
                          await _captureImage();
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
                          color: _viewMode == ViewMode.timer ||
                                  _viewMode == ViewMode.saving ||
                                  _viewMode == ViewMode.loading
                              ? AppColors.Gray500
                              : AppColors.Mint500,
                          width: 10.w,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_setTimer == 0) {
                        setState(() {
                          _setTimer = 3;
                        });
                      } else if (_setTimer == 3) {
                        setState(() {
                          _setTimer = 7;
                        });
                      } else if (_setTimer == 7) {
                        setState(() {
                          _setTimer = 10;
                        });
                      } else {
                        setState(() {
                          _setTimer = 0;
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.Gray500,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      width: 45.w,
                      height: 45.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_setTimer == 0 ? 'off' : '${_setTimer}s',
                              style: getTextStyle(
                                      AppTypo.TITLE18B, AppColors.Gray00)
                                  .copyWith(
                                fontSize: 18.sp,
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _toggleCamera();
                    },
                    child: const Icon(Icons.change_circle,
                        color: AppColors.Primary500, size: 50),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchRecentImage() async {
    if (await Permission.photos.isDenied) {
      PermissionStatus status = await Permission.photos.request();
      if (status.isDenied) {
        return;
      }
      try {
        print("Fetching asset paths...");
        List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          filterOption: FilterOptionGroup(
            orders: [
              const OrderOption(type: OrderOptionType.createDate, asc: false)
            ],
            // Limit the results to speed up the process
            containsPathModified: true,
            imageOption: const FilterOption(
              sizeConstraint: SizeConstraint(
                minHeight: 100,
                minWidth: 100,
              ),
            ),
          ),
        );

        print("Asset paths fetched: ${paths.length}");
        if (paths.isNotEmpty) {
          List<AssetEntity> recentAssets =
              await paths[0].getAssetListPaged(page: 0, size: 1);

          if (recentAssets.isNotEmpty) {
            File? file = await recentAssets[0].file;
            setState(() {
              _recentImage = file;
            });
            print("Recent image path: ${file?.path}");
          } else {
            print("No recent assets found.");
          }
        } else {
          print("No paths found.");
        }
      } catch (e) {
        print("Error fetching recent image: $e");
      }
    } else {
      print("Permission denied.");
    }
  }

  Future<void> _loadOverlayImage() async {
    setState(() {
      _viewMode = ViewMode.loading;
    });

    final ByteData data = await rootBundle.load(
        'assets/mockup/pic/che${ref.watch(picSelectedIndexProvider) + 1}.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final img.Image image = img.decodeImage(bytes)!;
    final uiImage = await _convertImage(image);
    setState(() {
      _overlayImage = uiImage;
      _viewMode = ViewMode.ready;
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
    setState(() {
      _viewMode = ViewMode.loading;
    });

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _setCamera(_cameras!.first);
    }

    setState(() {
      _cameraInitialized = true;
      _viewMode = ViewMode.ready;
    });
    await _loadOverlayImage(); // 오버레이 이미지를 항상 로드
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final currentDirection = _controller!.description.lensDirection;
    CameraDescription? newCameraDescription;

    // 현재 카메라와 반대 방향의 카메라를 찾습니다.
    if (currentDirection == CameraLensDirection.back) {
      newCameraDescription = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
    } else {
      newCameraDescription = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
    }

    // 현재 카메라 컨트롤러 해제
    await _controller?.dispose();

    // 새 카메라 컨트롤러 설정
    CameraController newController = CameraController(
      newCameraDescription,
      ResolutionPreset.max,
    );

    // 새 컨트롤러로 초기화
    await newController.initialize();

    // 상태 업데이트
    setState(() {
      _controller = newController;
    });
  }

  void _setFlashMode(FlashMode mode) {
    if (_controller != null) {
      _controller!.setFlashMode(mode);
    }
    setState(() {
      _flashMode = mode;
    });
  }

  Future<void> _setCamera(CameraDescription cameraDescription) async {
    logger.i('cameraDescription: $cameraDescription');
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
    );

    await _controller?.dispose();

    _controller = cameraController;

    await _controller!.initialize();
  }

  Future<void> _captureImage() async {
    try {
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      _capturedImageBytes = byteData!.buffer.asUint8List();

      setState(() {
        _viewMode = ViewMode.ready;
      });

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: LargePopupWidget(
                title: '갤러리에 저장하기',
                closeButton: GestureDetector(
                  onTap: () {
                    setState(() {
                      _viewMode = ViewMode.ready;
                    });
                    _controller!.resumePreview();
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset(
                    'assets/icons/vote/close.svg',
                    width: 24.w,
                    height: 24.w,
                  ),
                ),
                content: _capturedImageBytes != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.memory(_capturedImageBytes!),
                          SizedBox(
                            width: 200.w,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _saveImage();
                                setState(() {
                                  _viewMode = ViewMode.ready;
                                });

                                _controller!.resumePreview();
                                Navigator.of(context).pop();
                              },
                              child: const Text('저장하기'),
                            ),
                          ),
                        ],
                      )
                    : Container()),
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
