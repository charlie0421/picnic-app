import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/pages/pic/camera-view-page.dart';

class PicCameraScreen extends ConsumerStatefulWidget {
  final String routeName = '/pic-camera';

  const PicCameraScreen({super.key});

  @override
  ConsumerState<PicCameraScreen> createState() => _PicCameraScreenState();
}

class _PicCameraScreenState extends ConsumerState<PicCameraScreen> {
  @override
  Widget build(BuildContext context) {
    return const PicCameraViewPage();
  }
}
