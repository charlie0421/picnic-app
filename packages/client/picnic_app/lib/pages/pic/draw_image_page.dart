import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/celeb_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class DrawImagePage extends ConsumerStatefulWidget {
  const DrawImagePage({super.key});

  @override
  ConsumerState<DrawImagePage> createState() => _DrawImagePageState();
}

class _DrawImagePageState extends ConsumerState<DrawImagePage>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -0.05, end: 0.05).animate(_controller!)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    int userId = 2;

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
            style: getTextStyle(AppTypo.TITLE18B, AppColors.Grey900),
          ),
          Text(
            S.of(context).text_draw_image,
            style: getTextStyle(AppTypo.BODY16R, AppColors.Grey900),
          ),
        ],
      ),
    );
  }
}
