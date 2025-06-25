import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// Active/End 투표 상태용 스켈레톤 위젯 (헤더 + 투표 아이템)
class VoteCardSkeletonActive extends StatelessWidget {
  const VoteCardSkeletonActive({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        margin: EdgeInsets.only(top: 4, bottom: 6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 부분 스켈레톤
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(color: Colors.grey[300]!, width: 1.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 영역
                    Container(
                      height: 20.h,
                      width: double.infinity * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    
                    // 시간 정보 영역
                    Container(
                      height: 16.h,
                      width: double.infinity * 0.5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // 투표 아이템 영역 스켈레톤
              Container(
                width: double.infinity,
                height: 120.h,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(color: Colors.grey[300]!, width: 1.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2위 스켈레톤
                    _buildRankSkeleton(height: 40.h),
                    // 1위 스켈레톤 (가장 높음)
                    _buildRankSkeleton(height: 55.h),
                    // 3위 스켈레톤
                    _buildRankSkeleton(height: 30.h),
                  ],
                ),
              ),
              
              SizedBox(height: 10.h),
              
              // 공유 버튼 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 32.h,
                    width: 90.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  Container(
                    height: 32.h,
                    width: 90.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankSkeleton({required double height}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 아티스트 이미지
        Container(
          width: 35.w,
          height: 35.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: 4.h),
        
        // 아티스트 이름
        Container(
          width: 50.w,
          height: 10.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.r),
          ),
        ),
        SizedBox(height: 4.h),
        
        // 투표 바
        Container(
          width: 50.w,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        SizedBox(height: 3.h),
        
        // 투표 수
        Container(
          width: 40.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      ],
    );
  }
} 