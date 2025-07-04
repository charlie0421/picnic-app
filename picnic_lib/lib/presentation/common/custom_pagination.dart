import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';

class CustomPaginationBuilder extends SwiperPlugin {
  final int? itemCount;

  CustomPaginationBuilder({this.itemCount});

  @override
  Widget build(BuildContext context, SwiperPluginConfig config) {
    final int count = itemCount ?? config.itemCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        bool active = index == config.activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: active ? 12 : 8,
          height: active ? 12 : 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary500 : Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class CustomPagination extends StatelessWidget {
  final int itemCount;
  final int activeIndex;

  const CustomPagination({
    super.key,
    required this.itemCount,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 5.h, top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (index) {
          bool active = index == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            width: active ? 12 : 8,
            height: active ? 12 : 8,
            decoration: BoxDecoration(
              color: active ? AppColors.primary500 : Colors.grey,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
