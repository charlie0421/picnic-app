import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picnic_app/pages/pic/pic_camera_view_page.dart';
import 'package:picnic_app/ui/style.dart';

class BottomBarWidget extends StatelessWidget {
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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              final ImagePicker _picker = ImagePicker();
              final XFile? image =
                  await _picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final croppedFile = await ImageCropper().cropImage(
                  sourcePath: image.path,
                  aspectRatio: const CropAspectRatio(ratioX: 5.5, ratioY: 8.5),
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
                );
                if (croppedFile != null) {
                  onImagePicked(File(croppedFile.path));
                }
              }
            },
            child: recentImage == null
                ? Container(color: Colors.grey, width: 50.w, height: 50.w)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      recentImage!,
                      width: 50.w,
                      height: 50.w,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          GestureDetector(
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
              height: 40.w,
              decoration: BoxDecoration(
                color: viewType == ViewType.image ||
                        viewMode == ViewMode.saving ||
                        viewMode == ViewMode.timer ||
                        !cameraInitialized
                    ? Colors.grey
                    : AppColors.Primary500,
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
            onTap: viewMode == ViewMode.ready ? onCapture : null,
            child: Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (viewMode == ViewMode.ready) ? Colors.white : Colors.grey,
                border: Border.all(
                  color: (viewMode == ViewMode.ready)
                      ? AppColors.Primary500
                      : Colors.grey,
                  width: 10.w,
                ),
              ),
              child: Icon(
                viewType == ViewType.image ? Icons.save : Icons.camera,
                color: (viewMode == ViewMode.ready)
                    ? AppColors.Primary500
                    : Colors.grey,
                size: 30,
              ),
            ),
          ),
          GestureDetector(
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
                    : AppColors.Primary500,
                borderRadius: BorderRadius.circular(50),
              ),
              width: 45.w,
              height: 45.w,
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
            onTap: cameraInitialized ? onCameraToggle : null,
            child: Icon(
              Icons.change_circle,
              color: cameraInitialized
                  ? (viewType == ViewType.image ||
                          viewMode == ViewMode.saving ||
                          viewMode == ViewMode.timer
                      ? Colors.grey
                      : AppColors.Primary500)
                  : Colors.grey,
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
