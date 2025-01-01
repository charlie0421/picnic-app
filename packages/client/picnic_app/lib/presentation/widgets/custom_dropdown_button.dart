import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/ui.dart';

class CustomDropdownMenuItem {
  final String value;
  final String text;

  CustomDropdownMenuItem({
    required this.value,
    required this.text,
  });
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
    return IntrinsicWidth(
      child: Container(
        height: 26,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 16.cw),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
        child: DropdownButtonFormField<String>(
          key: key,
          value: value,
          icon: Transform.rotate(
            angle: 1.57,
            child: SvgPicture.asset(
              'assets/icons/play_style=fill.svg',
              colorFilter: const ColorFilter.mode(
                AppColors.grey400,
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
            return DropdownMenuItem(
              alignment: Alignment.center,
              value: item.value,
              child: Text(
                item.text,
                style: value == item.value
                    ? getTextStyle(AppTypo.caption12R, AppColors.grey700)
                    : getTextStyle(AppTypo.caption12R, AppColors.grey400),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
