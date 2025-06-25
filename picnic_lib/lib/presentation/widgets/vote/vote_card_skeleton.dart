import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// 투표 카드 스켈레톤 위젯
class VoteCardSkeleton extends StatelessWidget {
  const VoteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.r),
          border: Border.all(color: Colors.grey[300]!, width: 1.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 스켈레톤
              Container(
                height: 24.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 12.h),
              
              // 날짜 정보 스켈레톤
              Container(
                height: 16.h,
                width: 200.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 16.h),
              
              // 투표 아이템들 스켈레톤 (3개)
              ...List.generate(3, (index) => _buildVoteItemSkeleton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteItemSkeleton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          // 순위 영역
          SizedBox(
            width: 39.w,
            child: Column(
              children: [
                Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          
          // 아티스트 이미지 스켈레톤
          Container(
            width: 45.w,
            height: 45.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          
          // 이름과 투표수 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아티스트 이름 스켈레톤
                Container(
                  height: 16.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                
                // 투표수 스켈레톤
                Container(
                  height: 20.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          
          // 투표 아이콘 스켈레톤
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }
} 