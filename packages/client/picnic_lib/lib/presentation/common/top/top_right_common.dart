import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/providers/area_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

class TopRightCommon extends ConsumerWidget {
  const TopRightCommon({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(areaProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(areaProvider.notifier).setArea('kpop');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: area == 'kpop'
                        ? AppColors.primary500
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: area == 'kpop'
                        ? [
                            BoxShadow(
                              color: AppColors.primary500.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'K-POP',
                    style: TextStyle(
                      color: area == 'kpop'
                          ? Colors.white
                          : const Color(0xFF666666),
                      fontSize: 10.sp,
                      fontWeight:
                          area == 'kpop' ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(areaProvider.notifier).setArea('musical');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: area == 'musical'
                        ? AppColors.primary500
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: area == 'musical'
                        ? [
                            BoxShadow(
                              color: AppColors.primary500.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'K-MUSICAL',
                    style: TextStyle(
                      color: area == 'musical'
                          ? Colors.white
                          : const Color(0xFF666666),
                      fontSize: 10.sp,
                      fontWeight:
                          area == 'musical' ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
