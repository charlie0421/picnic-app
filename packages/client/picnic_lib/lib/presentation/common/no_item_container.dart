import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/ui/style.dart';

class NoItemContainer extends StatelessWidget {
  const NoItemContainer({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            package: 'picnic_lib',
            'assets/icons/information_style=fill.svg',
            width: 40,
            height: 40,
            colorFilter: ColorFilter.mode(
              AppColors.primary500,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            message ?? S.of(context).common_text_no_data,
            style: getTextStyle(AppTypo.title18SB, AppColors.grey700),
          ),
        ],
      ),
    );
  }
}
