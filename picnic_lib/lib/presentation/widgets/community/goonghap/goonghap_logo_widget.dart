import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoonghapLogoWidget extends StatelessWidget {
  const GoonghapLogoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: SvgPicture.asset(
        package: 'picnic_lib',
        'assets/images/fortune/picnic_logo.svg',
        width: 78,
        fit: BoxFit.contain,
      ),
    );
  }
}
