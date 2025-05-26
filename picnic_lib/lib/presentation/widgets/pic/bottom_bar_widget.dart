import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/memory_profiler.dart';
import 'package:picnic_lib/core/utils/memory_profiler_provider.dart';
import 'package:picnic_lib/core/utils/memory_profiling_hook.dart'
    as profiling_hook;
import 'package:picnic_lib/presentation/pages/pic/pic_camera_view_page.dart';
import 'package:picnic_lib/ui/style.dart';

class BottomBarWidget extends ConsumerWidget {
  final CameraController? controller;
  final FlashMode flashMode;
  final File? recentImage;
  final Function(FlashMode) onFlashToggle;
  final Function() onCapture;
  final Function(File) onImagePicked;
  final Function() onCameraToggle;
  final bool cameraInitialized;
  final File? userImage;
  final int timerValue;
  final Function() onTimerToggle;
  final ViewMode viewMode;
  final ViewType viewType;

  const BottomBarWidget({
    super.key,
    required this.controller,
    required this.flashMode,
    required this.recentImage,
    required this.onFlashToggle,
    required this.onCapture,
    required this.onImagePicked,
    required this.onCameraToggle,
    required this.cameraInitialized,
    required this.userImage,
    required this.timerValue,
    required this.onTimerToggle,
    required this.viewMode,
    required this.viewType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final ImagePicker picker = ImagePicker();

              // 이미지 선택 작업 프로파일링
              final XFile? image = await profiling_hook.MemoryProfilingHook
                  .profileImageLoading<XFile?>(
                imageUrl: 'gallery_picker',
                loadFunction: () =>
                    picker.pickImage(source: ImageSource.gallery),
                ref: ref,
              );

              if (image != null && context.mounted) {
                // 이미지 크롭 작업 프로파일링
                final aspectRatio =
                    const CropAspectRatio(ratioX: 5.5, ratioY: 8.5);
                final croppedFile = await profiling_hook.MemoryProfilingHook
                    .profileImageCropping<CroppedFile?>(
                  sourcePath: image.path,
                  aspectRatio:
                      profiling_hook.CropAspectRatio(ratioX: 5.5, ratioY: 8.5),
                  cropFunction: () => ImageCropper().cropImage(
                    sourcePath: image.path,
                    aspectRatio: aspectRatio,
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: 'Cropping',
                        toolbarColor: Colors.pinkAccent,
                        toolbarWidgetColor: Colors.white,
                        lockAspectRatio: true,
                      ),
                      IOSUiSettings(
                        title: 'Cropping',
                        aspectRatioLockEnabled: true,
                      ),
                      WebUiSettings(
                        context: context,
                      ),
                    ],
                  ),
                  ref: ref,
                );

                if (croppedFile != null) {
                  // 이미지 처리 결과 스냅샷 생성
                  final profiler = ref.read(memoryProfilerProvider.notifier);
                  final isEnabled = ref.read(memoryProfilerProvider).isEnabled;
                  if (isEnabled) {
                    profiler.takeSnapshot(
                      'image_crop_complete_${DateTime.now().millisecondsSinceEpoch}',
                      metadata: {
                        'type': 'image_crop_complete',
                        'sourcePath': image.path,
                        'resultPath': croppedFile.path,
                      },
                      level: MemoryProfiler.snapshotLevelMedium,
                    );
                  }

                  // 결과 이미지 전달
                  onImagePicked(File(croppedFile.path));

                  // 작업 완료 로그
                  logger.i('이미지 선택 및 크롭 완료: ${croppedFile.path}');
                }
              }
            },
            child: recentImage == null
                ? Container(color: Colors.grey, width: 50.w, height: 50)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      recentImage!,
                      width: 50.w,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: viewType == ViewType.image ||
                    viewMode == ViewMode.saving ||
                    viewMode == ViewMode.timer ||
                    !cameraInitialized
                ? null
                : () {
                    if (flashMode == FlashMode.auto) {
                      onFlashToggle(FlashMode.torch);
                    } else if (flashMode == FlashMode.torch) {
                      onFlashToggle(FlashMode.off);
                    } else {
                      onFlashToggle(FlashMode.auto);
                    }
                  },
            child: Container(
              width: 40.w,
              height: 40,
              decoration: BoxDecoration(
                color: viewType == ViewType.image ||
                        viewMode == ViewMode.saving ||
                        viewMode == ViewMode.timer ||
                        !cameraInitialized
                    ? Colors.grey
                    : AppColors.primary500,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                flashMode == FlashMode.auto
                    ? Icons.flash_auto
                    : flashMode == FlashMode.torch
                        ? Icons.flash_on
                        : Icons.flash_off,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: viewMode == ViewMode.ready ? onCapture : null,
            child: Container(
              width: 70.w,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (viewMode == ViewMode.ready) ? Colors.white : Colors.grey,
                border: Border.all(
                  color: (viewMode == ViewMode.ready)
                      ? AppColors.primary500
                      : Colors.grey,
                  width: 10.w,
                ),
              ),
              child: Icon(
                viewType == ViewType.image ? Icons.save : Icons.camera,
                color: (viewMode == ViewMode.ready)
                    ? AppColors.primary500
                    : Colors.grey,
                size: 30,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: viewType == ViewType.image ||
                    viewMode == ViewMode.saving ||
                    viewMode == ViewMode.timer ||
                    !cameraInitialized
                ? null
                : onTimerToggle,
            child: Container(
              decoration: BoxDecoration(
                color: viewType == ViewType.image ||
                        viewMode == ViewMode.saving ||
                        viewMode == ViewMode.timer ||
                        !cameraInitialized
                    ? Colors.grey
                    : AppColors.primary500,
                borderRadius: BorderRadius.circular(50),
              ),
              width: 45.w,
              height: 45,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timerValue == 0 ? 'off' : '${timerValue}s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: cameraInitialized ? onCameraToggle : null,
            child: Icon(
              Icons.change_circle,
              color: cameraInitialized
                  ? (viewType == ViewType.image ||
                          viewMode == ViewMode.saving ||
                          viewMode == ViewMode.timer
                      ? Colors.grey
                      : AppColors.primary500)
                  : Colors.grey,
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
