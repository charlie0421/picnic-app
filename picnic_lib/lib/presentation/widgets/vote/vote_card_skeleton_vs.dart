import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// VS 투표 상태용 스켈레톤 위젯 (헤더 + 2개 아이템)
class VoteCardSkeletonVS extends StatelessWidget {
  const VoteCardSkeletonVS({super.key});

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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    SizedBox(height: 12.h),
                    
                    // 타이머 영역 (더 작게)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimerBox(), // 0
                        SizedBox(width: 2.w),
                        _buildTimerBox(), // 2
                        SizedBox(width: 6.w),
                        _buildTimerText(), // D
                        SizedBox(width: 6.w),
                        _buildTimerBox(), // 1
                        SizedBox(width: 2.w),
                        _buildTimerBox(), // 6
                        SizedBox(width: 6.w),
                        _buildTimerColon(), // :
                        SizedBox(width: 6.w),
                        _buildTimerBox(), // 1
                        SizedBox(width: 2.w),
                        _buildTimerBox(), // 1
                        SizedBox(width: 6.w),
                        _buildTimerColon(), // :
                        SizedBox(width: 6.w),
                        _buildTimerBox(), // 0
                        SizedBox(width: 2.w),
                        _buildTimerBox(), // 3
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // VS 투표 아이템 영역 스켈레톤 (높이 줄임)
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
                  children: [
                    // 첫 번째 아이템 (1위)
                    _buildVSItemSkeleton(isFirst: true),
                    
                    // VS 텍스트
                    Container(
                      width: 30.w,
                      height: 18.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9.r),
                      ),
                    ),
                    
                    // 두 번째 아이템 (2위)
                    _buildVSItemSkeleton(isFirst: false),
                  ],
                ),
              ),
              
              SizedBox(height: 10.h),
              
              // 공유 버튼 영역 (크기 줄임)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 36.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                  Container(
                    height: 36.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18.r),
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

  Widget _buildTimerBox() {
    return Container(
      width: 24.w,
      height: 24.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }

  Widget _buildTimerText() {
    return Container(
      width: 16.w,
      height: 16.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildTimerColon() {
    return Container(
      width: 6.w,
      height: 16.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.r),
      ),
    );
  }

  Widget _buildVSItemSkeleton({required bool isFirst}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 순위 표시 (상단)
        Container(
          width: 24.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        SizedBox(height: 8.h),
        
        // 아티스트 이미지 (원형, 크기 줄임)
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: isFirst ? Border.all(color: Colors.white, width: 2.r) : null,
          ),
        ),
        SizedBox(height: 10.h),
        
        // 아티스트 이름
        Container(
          width: 70.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7.r),
          ),
        ),
        SizedBox(height: 6.h),
        
        // 그룹명
        Container(
          width: 60.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
      ],
    );
  }
} 