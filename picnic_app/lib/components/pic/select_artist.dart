import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/celeb_list_provider.dart';
import 'package:picnic_app/providers/pic_provider.dart';
import 'package:picnic_app/ui/style.dart';

class SelectArtist extends ConsumerStatefulWidget {
  const SelectArtist({super.key});

  @override
  createState() => _SelectArtistState();
}

class _SelectArtistState extends ConsumerState<SelectArtist> {
  int selectedPicIndex = 0;

  ui.Image? _overlayImage;
  ui.Image? _convertedUserImage; // 변환된 사용자 이미지
  List<CameraDescription>? cameras;
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOverlayImage();
      _initializeCameras();
    });
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

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;

    return ListView(
      children: [
        Container(
            height: 100.h,
            padding: EdgeInsets.only(
              left: 36.w,
              top: 8.h,
            ),
            child: _buildSelectArtist()),
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/mockup/pic/프레임 배경 1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Expanded(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Consumer(builder:
                    (BuildContext context, WidgetRef ref, Widget? child) {
                  return Container(
                    height: 90.h,
                    padding: EdgeInsets.only(left: 36.w),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 16.w),
                      itemBuilder: (context, index) {
                        return _buildSelectPic(index);
                      },
                    ),
                  );
                }),
                SizedBox(height: 10.h),
                Container(
                    width: 180.w,
                    height: 277.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Hero(
                      tag: 'pic',
                      child: Image.asset(
                          'assets/mockup/pic/che${selectedPicIndex + 1}.png'),
                    )),
                SizedBox(height: 10.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(180.w, 49.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    _showCameraView(context, ref);
                  },
                  child: Text(
                    'Go Pic!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildSelectPic(int index) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedPicIndex = index;
          ref.read(picSelectedIndexProvider.notifier).state = index;
        });
      },
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Opacity(
              opacity: selectedPicIndex == index ? 1 : 0.2,
              child: Image.asset(
                'assets/mockup/pic/che${index + 1}.png',
                width: 71.w,
                height: 110.h,
              ))),
    );
  }

  _buildSelectArtist() {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);

    return asyncCelebListState.when(
      data: (data) {
        return Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data?.length ?? 0,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        data?[index].thumbnail ?? '',
                        width: 60.w,
                        height: 60.h,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(data?[index].name_ko ?? '',
                        style: getTextStyle(AppTypo.BODY16B, AppColors.Gray900))
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => const Text('error'),
    );
  }

  void _showCameraView(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
                gradient: commonGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                )),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 5.5 / 8.5,
                  child: CameraPreview(
                    controller!,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: OverlayImagePainter(overlayImage: _overlayImage),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 40).r,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 12.h),
                        ),
                        onPressed: () async {
                          OverlayLoadingProgress.start(context);

                          final XFile file = await controller!.takePicture();
                          final img.Image image =
                              img.decodeImage(await file.readAsBytes())!;
                          final uiImage = await _convertImage(image);
                          ref.read(userImageProvider.notifier).state =
                              File(file.path);
                          ref.read(convertedImageProvider.notifier).state =
                              File(file.path);
                          // _userImage = File(file.path);
                          // _convertedUserImage = uiImage;
                          OverlayLoadingProgress.stop();
                          Navigator.pop(context);
                        },
                        child: const Text('사진 찍기'),
                      ),
                      const SizedBox(width: 16),
                      if (cameras != null && cameras!.isNotEmpty)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 12.h),
                          ),
                          onPressed: () async {
                            _toggleCamera();
                            Future.delayed(const Duration(milliseconds: 1000),
                                () {
                              setState(() {});
                            });
                          },
                          child: const Text('카메라 전환'),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 20.w,
                  right: 20.w,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 36),
                    color: AppColors.Gray00,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<ui.Image> _convertImage(img.Image image) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.fromList(img.encodePng(image)), (uiImage) {
      completer.complete(uiImage);
    });
    return completer.future;
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
