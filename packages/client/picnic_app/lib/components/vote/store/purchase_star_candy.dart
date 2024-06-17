import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';

class PurchaseStarCandy extends StatelessWidget {
  const PurchaseStarCandy({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 36.w),
        const CommonPointInfo(),
        SizedBox(height: 36.w),
      ],
    );
  }
}
