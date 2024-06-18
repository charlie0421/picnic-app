import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';

class CustomDropdownMenuItem {
  final String value;
  final String text;

  CustomDropdownMenuItem({
    required this.value,
    required this.text,
  });
}

class CustomDropdown extends StatelessWidget {
  final Key key;
  final String value;
  final ValueChanged<String?> onChanged;

  // final List<DropdownMenuItem<String>> items;
  final List<CustomDropdownMenuItem> items;

  const CustomDropdown({
    required this.key,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8).r,
        border: Border.all(
          color: AppColors.Grey300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IntrinsicWidth(
            child: DropdownButtonFormField<String>(
              key: key,
              value: value,
              icon: Transform.rotate(
                angle: 1.57,
                child: SvgPicture.asset(
                  'assets/icons/play_style=fill.svg',
                  colorFilter: const ColorFilter.mode(
                    AppColors.Grey400,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              isDense: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
              ),
              dropdownColor: AppColors.Grey00,
              borderRadius: BorderRadius.circular(8),
              items: items.map((item) {
                return DropdownMenuItem(
                  alignment: Alignment.center,
                  value: item.value,
                  child: Text(
                    item.text,
                    style: value == item.value
                        ? getTextStyle(AppTypo.CAPTION12R, AppColors.Grey700)
                        : getTextStyle(AppTypo.CAPTION12R, AppColors.Grey400),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
