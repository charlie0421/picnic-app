import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/ui/style.dart';

/// 지연 로딩을 위한 이미지 위젯
class LazyImageWidget extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final int listIndex;

  const LazyImageWidget({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.listIndex,
  });

  @override
  State<LazyImageWidget> createState() => _LazyImageWidgetState();
}

class _LazyImageWidgetState extends State<LazyImageWidget> {
  bool _shouldLoadImage = false;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    // 리스트 상위 몇 개 항목은 즉시 로딩
    if (widget.listIndex < 3) {
      _shouldLoadImage = true;
    } else {
      // 나머지는 점진적으로 지연 후 로딩 (최대 500ms)
      final delay = (widget.listIndex * 50).clamp(100, 500);
      _loadTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) {
          setState(() {
            _shouldLoadImage = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _shouldLoadImage
          ? PicnicCachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              width: widget.width,
              height: widget.height,
            )
          : Container(
              color: AppColors.grey200,
              child: Icon(
                Icons.person,
                color: AppColors.grey500,
                size: 24.r,
              ),
            ),
    );
  }
} 