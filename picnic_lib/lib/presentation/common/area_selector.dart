import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';

class AreaSelector extends ConsumerWidget {
  const AreaSelector({
    super.key,
  });

  DropdownMenuItem<String> _buildDropdownItem(
      String value, String label, String currentArea) {
    final isSelected = currentArea == value;
    return DropdownMenuItem(
      value: value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: isSelected
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
              label,
              style: getTextStyle(
                  isSelected ? AppTypo.caption12R : AppTypo.caption10SB,
                  isSelected ? AppColors.primary500 : AppColors.grey00),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(appSettingProvider);
    final area = setting.area;

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
          _buildDropdownItem('all', 'ALL', area),
          _buildDropdownItem('kpop', 'K-POP', area),
          _buildDropdownItem('musical', 'K-MUSICAL', area),
          _buildDropdownItem('pic-chart', 'PIC-CHART', area),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            ref.read(appSettingProvider.notifier).setArea(newValue);
          }
        },
      ),
    );
  }
}
