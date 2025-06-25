import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// Upcoming 투표 상태용 스켈레톤 위젯 (헤더만)
class VoteCardSkeletonUpcoming extends StatelessWidget {
  const VoteCardSkeletonUpcoming({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        margin: EdgeInsets.only(top: 4, bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 부분 스켈레톤 (크기 축소)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.r),
                border: Border.all(color: Colors.grey[300]!, width: 1.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 제목 영역
                  Container(
                    height: 14.h,
                    width: double.infinity * 0.65,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  
                  // 시간 정보 영역
                  Container(
                    height: 12.h,
                    width: double.infinity * 0.45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // 시작 예정 메시지 영역 (높이 축소)
            Container(
              width: double.infinity,
              height: 40.h,
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40.r),
                border: Border.all(color: Colors.grey[300]!, width: 1.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 시작 예정 텍스트 스켈레톤
                  Container(
                    height: 10.h,
                    width: double.infinity * 0.45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                  SizedBox(height: 3.h),
                  
                  // 시작 시간 스켈레톤
                  Container(
                    height: 8.h,
                    width: double.infinity * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
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