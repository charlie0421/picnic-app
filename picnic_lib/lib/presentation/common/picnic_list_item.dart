import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/style.dart';

class PicnicListItem extends StatelessWidget {
  final String leading;
  final String assetPath;
  final VoidCallback? onTap;
  final Widget? tailing;
  final Widget? title;

  const PicnicListItem({
    super.key,
    required this.leading,
    required this.assetPath,
    this.onTap,
    this.tailing,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 61,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(leading, style: getTextStyle(AppTypo.body16M)),
                    Expanded(child: title ?? const SizedBox.shrink()),
                    tailing ??
                        SvgPicture.asset(
                          package: 'picnic_lib',
                          assetPath,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            AppColors.grey900,
                            BlendMode.srcIn,
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Divider(color: AppColors.grey200),
      ],
    );
  }
}
