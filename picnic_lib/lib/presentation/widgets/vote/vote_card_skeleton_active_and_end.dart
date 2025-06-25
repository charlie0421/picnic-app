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
                    
                    // 투표 종료 상태
                    Container(
                      height: 16.h,
                      width: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // 투표 결과 영역 스켈레톤 (더 컴팩트)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40.r),
                  border: Border.all(color: Colors.grey[300]!, width: 1.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2위 (왼쪽)
                    _buildRankingSkeleton(
                      imageSize: 45.w,
                      nameWidth: 60.w,
                      groupWidth: 40.w,
                      voteWidth: 50.w,
                      rankHeight: 12.h,
                    ),
                    
                    // 1위 (중앙, 가장 크게)
                    _buildRankingSkeleton(
                      imageSize: 60.w,
                      nameWidth: 70.w,
                      groupWidth: 50.w,
                      voteWidth: 60.w,
                      rankHeight: 14.h,
                      isWinner: true,
                    ),
                    
                    // 3위 (오른쪽)
                    _buildRankingSkeleton(
                      imageSize: 45.w,
                      nameWidth: 60.w,
                      groupWidth: 40.w,
                      voteWidth: 50.w,
                      rankHeight: 12.h,
                    ),
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

  Widget _buildRankingSkeleton({
    required double imageSize,
    required double nameWidth,
    required double groupWidth,
    required double voteWidth,
    required double rankHeight,
    bool isWinner = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 투표수 (상단)
        Container(
          width: voteWidth,
          height: rankHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(rankHeight / 2),
          ),
        ),
        SizedBox(height: 6.h),
        
        // 순위 표시
        Container(
          width: 24.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        SizedBox(height: 6.h),
        
        // 아티스트 이미지 (원형)
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: isWinner ? Border.all(color: Colors.white, width: 2.r) : null,
          ),
        ),
        SizedBox(height: 8.h),
        
        // 아티스트 이름
        Container(
          width: nameWidth,
          height: 12.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        SizedBox(height: 4.h),
        
        // 그룹명
        Container(
          width: groupWidth,
          height: 10.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.r),
          ),
        ),
      ],
    );
  }
} 