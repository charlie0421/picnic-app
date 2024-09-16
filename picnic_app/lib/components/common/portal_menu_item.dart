import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class PortalMenuItem extends ConsumerWidget {
  const PortalMenuItem({
    super.key,
    required this.portalType,
  });

  final PortalType portalType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationInfo = ref.watch(navigationInfoProvider);
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);

    final bool isSelected = navigationInfo.portalType == portalType;

    return Container(
      height: 26,
      margin: EdgeInsets.only(left: 16.cw),
      child: InkWell(
        borderRadius: BorderRadius.circular(13).r,
        onTap: () {
          navigationInfoNotifier.setPortal(portalType);
        },
        child: Container(
          height: 26,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 12.cw),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13).r,
            border: Border.all(
              color: AppColors.grey900,
              width: 1.r,
            ),
            color: isSelected ? AppColors.grey00 : Colors.transparent,
          ),
          child: Center(
            child: Text(
              portalType.name.toUpperCase(),
              style: isSelected
                  ? getTextStyle(AppTypo.body14B, AppColors.grey900)
                  : getTextStyle(AppTypo.body14R, AppColors.grey900),
            ),
          ),
        ),
      ),
    );
  }
}
