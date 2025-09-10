import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/style.dart';

class CustomDropdownMenuItem {
  final String value;
  final String text;

  CustomDropdownMenuItem({required this.value, required this.text});
}

class CustomDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  // final List<DropdownMenuItem<String>> items;
  final List<CustomDropdownMenuItem> items;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSelection =
        value.isNotEmpty && items.any((i) => i.value == value);
    final Color borderColor = hasSelection
        ? AppColors.primary500
        : AppColors.grey300;

    return IntrinsicWidth(
      child: Container(
        height: 32,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: DropdownButtonFormField<String>(
          key: key,
          initialValue: value,
          icon: Transform.rotate(
            angle: 1.57,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/play_style=fill.svg',
              colorFilter: const ColorFilter.mode(
                AppColors.grey600,
                BlendMode.srcIn,
              ),
              height: 16,
              width: 16,
            ),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          isDense: true,
          dropdownColor: AppColors.grey00,
          borderRadius: BorderRadius.circular(8),
          items: items.map((item) {
            final bool isSelected = value == item.value;
            final bool isPlaceholder = item.value.isEmpty;
            final TextStyle style = (!isPlaceholder && isSelected)
                ? getTextStyle(AppTypo.caption12B, AppColors.grey800)
                : getTextStyle(AppTypo.caption12M, AppColors.grey600);
            return DropdownMenuItem(
              alignment: Alignment.center,
              value: item.value,
              child: Text(item.text, style: style),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
