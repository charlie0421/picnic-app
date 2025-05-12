import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/providers/area_provider.dart';

class AreaSelector extends ConsumerWidget {
  const AreaSelector({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = ref.watch(areaProvider);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.primary500,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: area,
        underline: const SizedBox(),
        icon: AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: 0.5,
          child: const Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white,
            size: 16,
          ),
        ),
        style: getTextStyle(AppTypo.caption10SB, AppColors.grey900),
        dropdownColor: AppColors.primary500,
        borderRadius: BorderRadius.circular(8.r),
        elevation: 8,
        items: [
          DropdownMenuItem(
            value: 'kpop',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: area == 'kpop' ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
                boxShadow: area == 'kpop'
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'K-POP',
                    style: getTextStyle(
                        area == 'kpop'
                            ? AppTypo.caption12R
                            : AppTypo.caption10SB,
                        area == 'kpop'
                            ? AppColors.primary500
                            : AppColors.grey00),
                  ),
                ],
              ),
            ),
          ),
          DropdownMenuItem(
            value: 'musical',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: area == 'musical' ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
                boxShadow: area == 'musical'
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'K-MUSICAL',
                    style: getTextStyle(
                        area == 'musical'
                            ? AppTypo.caption12R
                            : AppTypo.caption10SB,
                        area == 'musical'
                            ? AppColors.primary500
                            : AppColors.grey00),
                  ),
                ],
              ),
            ),
          ),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            ref.read(areaProvider.notifier).setArea(newValue);
          }
        },
      ),
    );
  }
}
