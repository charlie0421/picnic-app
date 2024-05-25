import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/constants.dart';

import '../../providers/fan_provider.dart';

class MakgeFan extends ConsumerStatefulWidget {
  const MakgeFan({super.key});

  @override
  _MakeFanState createState() => _MakeFanState();
}

class _MakeFanState extends ConsumerState<MakgeFan> {
  @override
  State<MakgeFan> createState() => _MakeFanState();

  ui.Image? _overlayImage;
  ui.Image? _convertedUserImage; // 변환된 사용자 이미지
  final picker = ImagePicker();
  List<CameraDescription>? cameras;
  CameraController? controller;

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

  Future<void> _initializeCameras() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      await _setCamera(cameras!.first);
    }
  }

  Future<void> _setCamera(CameraDescription cameraDescription) async {
    logger.i('cameraDescription: $cameraDescription');
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
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
      ResolutionPreset.medium,
    );

    // 새 컨트롤러로 초기화
    await newController.initialize();

    // 상태 업데이트
    setState(() {
      controller = newController;
    });
  }

  Future<void> _loadOverlayImage() async {
    final ByteData data = await rootBundle.load(
        'assets/mockup/fan/che${ref.watch(fanSelectedIndexProvider) + 1}.png');
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

  Future<void> getImage() async {
    OverlayLoadingProgress.start(context);
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final img.Image image = img.decodeImage(await pickedFile.readAsBytes())!;
      final uiImage = await _convertImage(image);
      setState(() {
        ref.read(userImageProvider.notifier).state = File(pickedFile.path);
        // _userImage = File(pickedFile.path);
        _convertedUserImage = uiImage;
      });
    }
    OverlayLoadingProgress.stop();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    int selectedFanIndex = ref.watch(fanSelectedIndexProvider);
    final userImage = ref.watch(userImageProvider);
    final convertedUserImage = ref.watch(convertedImageProvider);

    return Column(
      children: [
        Container(
          height: 58,
          padding: EdgeInsets.only(right: 16.w, top: 16.h, bottom: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.asset('assets/mockup/fan/replay.png',
                  width: 24.w, height: 24.h),
              SizedBox(width: 32.w),
              Image.asset('assets/mockup/fan/reply.png',
                  width: 24.w, height: 24.h),
              SizedBox(width: 32.w),
              Image.asset('assets/mockup/fan/prompt_suggestion.png',
                  width: 24.w, height: 24.h),
              SizedBox(width: 32.w),
              Image.asset('assets/mockup/fan/delete.png',
                  width: 24.w, height: 24.h),
              SizedBox(width: 32.w),
              Image.asset('assets/mockup/fan/more_vert.png',
                  width: 24.w, height: 24.h),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/mockup/fan/프레임 배경 1.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              SizedBox(height: 10.h),
              Container(
                height: 54.h,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/mockup/fan/help.png',
                        width: 54.w, height: 54.h),
                    Image.asset('assets/mockup/fan/save.png',
                        width: 54.w, height: 54.h),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Stack(
                children: [
                  if (ref.watch(userImageProvider.notifier).state != null)
                    Container(
                      width: 250.w,
                      height: 386.h,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(userImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Container(
                      width: 250.w,
                      height: 386.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: userImage == null
                            ? Colors.white
                            : Colors.transparent,
                      ),
                      child: Hero(
                        tag: 'fan',
                        child: Image.asset(
                            'assets/mockup/fan/che${selectedFanIndex + 1}.png'),
                      )),
                ],
              ),
              SizedBox(height: 34.h),
              Container(
                height: 54.h,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/mockup/fan/background.png'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: getImage,
                          child: const Text('사진첩'),
                        ),
                        if (cameras != null && cameras!.isNotEmpty)
                          const SizedBox(width: 16),
                        if (cameras != null && cameras!.isNotEmpty)
                          ElevatedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext context) {
                                  return StatefulBuilder(builder:
                                      (BuildContext context,
                                          StateSetter setState) {
                                    return SizedBox(
                                      height: MediaQuery.of(context)
                                          .size
                                          .height, // 전체 화면 높이를 사용
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CameraPreview(
                                            controller!,
                                            child: CustomPaint(
                                              size: Size.infinite,
                                              painter: OverlayImagePainter(
                                                  overlayImage: _overlayImage),
                                            ),
                                          ),
                                          Container(
                                            width: double.infinity,
                                            alignment: Alignment.bottomCenter,
                                            padding: const EdgeInsets.only(
                                                bottom: 100),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    OverlayLoadingProgress
                                                        .start(context);

                                                    final XFile file =
                                                        await controller!
                                                            .takePicture();
                                                    final img.Image image = img
                                                        .decodeImage(await file
                                                            .readAsBytes())!;
                                                    final uiImage =
                                                        await _convertImage(
                                                            image);
                                                    ref
                                                        .read(userImageProvider
                                                            .notifier)
                                                        .state = File(file.path);
                                                    ref
                                                        .read(
                                                            convertedImageProvider
                                                                .notifier)
                                                        .state = File(file.path);
                                                    // _userImage = File(file.path);
                                                    // _convertedUserImage = uiImage;
                                                    OverlayLoadingProgress
                                                        .stop();
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('사진 찍기'),
                                                ),
                                                const SizedBox(width: 16),
                                                if (cameras != null &&
                                                    cameras!.isNotEmpty)
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      _toggleCamera();
                                                      Future.delayed(
                                                          const Duration(
                                                              milliseconds:
                                                                  1000), () {
                                                        setState(() {});
                                                      });
                                                    },
                                                    child: const Text('카메라 전환'),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                },
                              );
                            },
                            child: const Text('카메라'),
                          ),
                      ],
                    ),
                    Image.asset('assets/mockup/fan/decoration.png',
                        width: 54.w, height: 54.h),
                  ],
                ),
              ),
              SizedBox(height: 34.h),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class OverlayImagePainter extends CustomPainter {
  final ui.Image? overlayImage;

  OverlayImagePainter({this.overlayImage});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    if (overlayImage != null) {
      // 오버레이 이미지의 크기를 기반으로 오른쪽 아래에 위치시키기 위한 계산
      final double imageWidth = overlayImage!.width.toDouble();
      final double imageHeight = overlayImage!.height.toDouble();
      final Offset position = Offset(
          size.width - imageWidth, size.height - imageHeight); // 오른쪽 아래 위치 계산

      // 오버레이 이미지를 그립니다.
      canvas.drawImage(overlayImage!, position, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
