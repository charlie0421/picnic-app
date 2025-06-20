import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/pages/pic/draw_image_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

class DrawImageScreen extends ConsumerWidget {
  static const String routeName = '/draw-image';

  const DrawImageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appSettingProvider);
    return Scaffold(
      appBar: AppBar(),
      body: const DrawImagePage(),
    );
  }
}
