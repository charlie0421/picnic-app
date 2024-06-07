import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';

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

    // logger.d('Portal type: $portalType');
    // logger.d('Current portal type: ${navigationInfo.portalType}');
    // logger.d(
    //     'navigationInfo.portalType == portalType: ${navigationInfo.portalType == portalType} ');

    final bool isSelected = navigationInfo.portalType == portalType;

    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () {
        navigationInfoNotifier.setPortal(portalType);
      },
      child: Container(
        height: 24.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.Gray900,
            width: 0.5.r,
          ),
          color: isSelected ? AppColors.Gray00 : Colors.transparent,
        ),
        child: Center(
          child: Text(
            portalType.name.toUpperCase(),
            style: isSelected
                ? getTextStyle(AppTypo.BODY14B, AppColors.Gray900)
                : getTextStyle(AppTypo.BODY14R, AppColors.Gray900),
          ),
        ),
      ),
    );
  }
}
