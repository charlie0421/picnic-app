import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilitySummaryWidget extends StatelessWidget {
  const CompatibilitySummaryWidget({
    super.key,
    required this.localizedResult,
  });

  final LocalizedCompatibility? localizedResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      constraints: const BoxConstraints(maxHeight: 72),
      child: Stack(
        children: [
          if (localizedResult != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              constraints: const BoxConstraints(minHeight: 60),
              child: Center(
                child: Text(
                  localizedResult!.compatibilitySummary,
                  style: getTextStyle(AppTypo.caption12B, AppColors.grey00),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            top: 10,
            left: 0,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/fortune/quote_open.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey00, BlendMode.srcIn),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 0,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/fortune/quote_close.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey00, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}
