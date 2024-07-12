import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/ui/style.dart';

class CustomPaginationBuilder extends SwiperPlugin {
  @override
  Widget build(BuildContext context, SwiperPluginConfig config) {
    return Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(config.itemCount, (index) {
          bool active = index == config.activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: active ? 12 : 8,
            height: active ? 12 : 8,
            decoration: BoxDecoration(
              color: active ? AppColors.Primary500 : Colors.grey,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
