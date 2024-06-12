import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picnic_app/components/pic/bottom_bar_widget.dart';
import 'package:picnic_app/components/pic/image_overlay_painter.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/ui/style.dart';

class PicCameraViewPage extends ConsumerStatefulWidget {
  const PicCameraViewPage({super.key});

  @override
  ConsumerState<PicCameraViewPage> createState() => _PicCameraViewState();
}

enum ViewMode { loading, ready, timer, saving }

enum ViewType { camera, image }

class _PicCameraViewState extends ConsumerState<PicCameraViewPage> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _cameraInitialized = false;
  File? _recentImage;
  File? _userImage;
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  FlashMode _flashMode = FlashMode.auto;
  ui.Image? _overlayImage;
  Uint8List? _capturedImageBytes;
  int _setTimer = 3;
  int _remainTime = 0;
  Timer? _timer;

  ViewMode _viewMode = ViewMode.loading;
  ViewType _viewType = ViewType.camera;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _fetchRecentImage();
    _loadOverlayImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: MediaQuery.of(context).padding,
        color: AppColors.Gray00,
        child: Column(
          children: [
            _buildTopBar(context),
            if (_userImage != null)
              _buildImagePreview()
            else
              _buildCameraPreview(),
            BottomBarWidget(
              controller: _controller,
              flashMode: _flashMode,
              recentImage: _recentImage,
              onFlashToggle: _setFlashMode,
              onCapture: _handleCapture,
              onImagePicked: (file) => setState(() {
                _userImage = file;
                _viewMode = ViewMode.ready;
                _viewType = ViewType.image;
              }),
              onCameraToggle: _toggleCamera,
              cameraInitialized: _cameraInitialized,
              userImage: _userImage,
              timerValue: _setTimer,
              onTimerToggle: _toggleTimer,
              viewMode: _viewMode,
              viewType: _viewType,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTimer() {
    setState(() {
      _setTimer = (_setTimer == 0)
          ? 3
          : (_setTimer == 3)
              ? 7
              : (_setTimer == 7)
                  ? 10
                  : 0;
    });
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 60.h,
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: const Icon(Icons.close, size: 36),
        color: AppColors.Gray900,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Stack(
            children: [
              if (_userImage != null)
                Positioned.fill(
                  child: Image.file(
                    _userImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              if (_overlayImage != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ImageOverlayPainter(overlayImage: _overlayImage),
                  ),
                ),
              if (_viewMode == ViewMode.saving)
                Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Text(
                        Intl.message('label_pic_pic_synthesizing_image'),
                        style: TextStyle(
                            fontSize: 30, color: AppColors.Primary500)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Stack(
            children: [
              if (_cameraInitialized)
                Container(
                  alignment: Alignment.center,
                  child: CameraPreview(
                    _controller!,
                    child: CustomPaint(
                      painter: ImageOverlayPainter(overlayImage: _overlayImage),
                    ),
                  ),
                ),
              if (_viewMode == ViewMode.loading)
                Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Text(
                      Intl.message('label_pic_pic_initializing_camera'),
                      style:
                          TextStyle(fontSize: 30, color: AppColors.Primary500),
                    ),
                  ),
                )
              else if (_viewMode == ViewMode.timer)
                AnimatedContainer(
                  alignment: Alignment.center,
                  duration: const Duration(milliseconds: 50),
                  color: _isBlinking
                      ? Colors.white.withOpacity(0.8)
                      : Colors.transparent,
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
                  child: Center(
                    child: Text(
                      Intl.message('label_pic_pic_synthesizing_image'),
                      style:
                          TextStyle(fontSize: 30, color: AppColors.Primary500),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _setFlashMode(FlashMode mode) {
    if (_controller != null) {
      _controller!.setFlashMode(mode);
    }
    setState(() {
      _flashMode = mode;
    });
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final currentDirection = _controller!.description.lensDirection;
    CameraDescription? newCameraDescription;

    newCameraDescription = _cameras!.firstWhere(
      (camera) =>
          camera.lensDirection ==
          (currentDirection == CameraLensDirection.back
              ? CameraLensDirection.front
              : CameraLensDirection.back),
      orElse: () => _cameras!.first,
    );

    await _controller?.dispose();

    CameraController newController = CameraController(
      newCameraDescription,
      ResolutionPreset.max,
    );

    await newController.initialize();

    setState(() {
      _controller = newController;
    });
  }

  Future<void> _initializeCameras() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _setCamera(_cameras!.first);
      setState(() {
        _cameraInitialized = true;
        _viewMode = ViewMode.ready;
      });
    } else {
      setState(() {
        _cameraInitialized = false;
        _viewMode = ViewMode.loading;
      });
    }
  }

  Future<void> _setCamera(CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
    );

    await _controller?.dispose();

    _controller = cameraController;

    await _controller!.initialize();
  }

  Future<void> _fetchRecentImage() async {
    if (await Permission.photos.isDenied) {
      PermissionStatus status = await Permission.photos.request();
      if (status.isDenied) {
        return;
      }
    }

    try {
      List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false)
          ],
          containsPathModified: true,
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(
              minHeight: 100,
              minWidth: 100,
            ),
          ),
        ),
      );

      if (paths.isNotEmpty) {
        List<AssetEntity> recentAssets =
            await paths[0].getAssetListPaged(page: 0, size: 1);

        if (recentAssets.isNotEmpty) {
          File? file = await recentAssets[0].file;
          setState(() {
            _recentImage = file;
          });
        }
      }
    } catch (e) {
      print("Error fetching recent image: $e");
    }
  }

  Future<void> _loadOverlayImage() async {
    final ByteData data = await rootBundle
        .load('assets/mockup/pic/che1.png'); // Adjust path as needed
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

  final List<String> countdownSounds = [
    'sounds/1.mp3',
    'sounds/2.mp3',
    'sounds/3.mp3',
    'sounds/4.mp3',
    'sounds/5.mp3',
    'sounds/6.mp3',
    'sounds/7.mp3',
    'sounds/8.mp3',
    'sounds/9.mp3',
    'sounds/10.mp3',
    'sounds/shutter.mp3'
  ];
  final AudioPlayer _audioPlayer = AudioPlayer(); // Add this line

  void _handleCapture() {
    if (_viewMode != ViewMode.ready) return;

    if (_viewType == ViewType.image) {
      _captureImage();
    } else {
      if (_setTimer > 0) {
        setState(() {
          _remainTime = _setTimer * 1000;
          _viewMode = ViewMode.timer;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          int countdownIndex = (_remainTime ~/ 1000) - 2;
          if (countdownIndex >= 0 &&
              countdownIndex < countdownSounds.length - 1) {
            logger.i('Playing sound: ${countdownSounds[countdownIndex]}');
            // _audioPlayer.play(AssetSource(countdownSounds[countdownIndex]));
          }
          if (_remainTime <= 0) {
            timer.cancel();
            // _audioPlayer.play(AssetSource(countdownSounds.last));
            _captureImage();
          } else {
            setState(() {
              _remainTime -= 1000;
              _isBlinking = !_isBlinking; // Blinking effect
            });
          }
        });
      } else {
        _captureImage();
      }
    }
  }

  Future<void> _captureImage() async {
    setState(() {
      _remainTime = 0;
      _viewMode = ViewMode.saving;
    });
    try {
      _controller?.pausePreview(); // Pause the camera preview
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      _capturedImageBytes = byteData!.buffer.asUint8List();

      setState(() {
        _viewMode = ViewMode.ready;
      });

      _showSaveDialog();
    } catch (e) {
      print("Error capturing image: $e");
      setState(() {
        _viewMode = ViewMode.ready;
      });
      _controller?.resumePreview(); // Resume the camera preview on error
    }
  }

  void _showSaveDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: LargePopupWidget(
            title: Intl.message('label_pic_pic_save_gallery'),
            closeButton: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _controller!.resumePreview(); // Resume the camera preview
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
                      Container(
                          margin: EdgeInsets.only(top: 16.h),
                          child: Image.memory(_capturedImageBytes!)),
                      Container(
                        width: 200.w,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: ElevatedButton(
                          onPressed: () async {
                            await _saveImage();
                            _controller!
                                .resumePreview(); // Resume the camera preview
                            Navigator.of(context).pop();
                          },
                          child: Text(Intl.message('button_pic_pic_save')),
                        ),
                      ),
                    ],
                  )
                : Container(),
          ),
        );
      },
    );
    _controller?.resumePreview(); // Resume the camera preview on error
  }

  Future<void> _saveImage() async {
    try {
      if (_capturedImageBytes != null) {
        final result = await ImageGallerySaver.saveImage(
          _capturedImageBytes!,
          quality: 100,
          name: 'captured_image',
        );

        final snackBarContent = result['isSuccess']
            ? Text(Intl.message('message_pic_pic_save_success'))
            : Text(Intl.message('message_pic_pic_save_fail'));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: snackBarContent));
      }
    } catch (e) {
      print("Error saving image: $e");
    }
  }
}
