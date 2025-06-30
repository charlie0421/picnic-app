import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// End 투표 상태용 스켈레톤 위젯 (헤더 + 결과 표시)
class VoteCardSkeletonActiveAndEnd extends StatelessWidget {
  const VoteCardSkeletonActiveAndEnd({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        margin: EdgeInsets.only(top: 4, bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 부분 스켈레톤 (크기 축소)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.r),
                border: Border.all(color: Colors.grey[300]!, width: 1.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 제목 영역 (크기 축소)
                  Container(
                    height: 16.h,
                    width: double.infinity * 0.7,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  
                  // 투표 종료 상태 (크기 축소)
                  Container(
                    height: 12.h,
                    width: 50.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // 투표 결과 영역 스켈레톤 (간소화)
            Container(
              width: double.infinity,
              height: 80.h,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.r),
                border: Border.all(color: Colors.grey[300]!, width: 1.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 간단한 순위 스켈레톤들
                  for (int i = 0; i < 3; i++)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30.w,
                          height: 30.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: 40.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


} 