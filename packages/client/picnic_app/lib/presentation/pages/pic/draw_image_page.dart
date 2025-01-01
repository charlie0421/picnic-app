import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/presentation/providers/celeb_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class DrawImagePage extends ConsumerStatefulWidget {
  const DrawImagePage({super.key});

  @override
  ConsumerState<DrawImagePage> createState() => _DrawImagePageState();
}

class _DrawImagePageState extends ConsumerState<DrawImagePage>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(asyncCelebListProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          Transform.rotate(
              angle:
                  sin(_controller!.value * 2 * pi) * 0.05, // 이 부분에서 흔들림 효과 조절
              child: Image.asset('assets/images/random_image.webp')),
          const SizedBox(height: 20),
          Text(
            S.of(context).label_draw_image,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
          Text(
            S.of(context).text_draw_image,
            style: getTextStyle(AppTypo.body16R, AppColors.grey900),
          ),
        ],
      ),
    );
  }
}
