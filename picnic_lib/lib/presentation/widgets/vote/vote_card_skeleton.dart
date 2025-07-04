import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// 투표 카드 스켈레톤 상태
enum VoteCardStatus {
  upcoming, // 예정
  ongoing, // 진행 중
  ended, // 종료
}

/// 투표 카드 스켈레톤 위젯
class VoteCardSkeleton extends StatelessWidget {
  final VoteCardStatus status;

  const VoteCardSkeleton({
    super.key,
    this.status = VoteCardStatus.ongoing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더 카드 (제목, 시간 정보)
          Container(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 48.h),
                  _buildHeaderSkeleton(),
                ],
              ),
            ),
          ),

          // 투표 아이템 컨테이너 (진행중/종료 상태만)
          if (status != VoteCardStatus.upcoming) ...[
            SizedBox(height: 24.h),
            _buildVoteItemsContainer(),

            // 하단 정보 컨테이너 (진행중/종료 상태용)
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.grey[300]!, width: 1.r),
              ),
              child: _buildFooterSkeleton(),
            ),
          ],

          // 하단 정보 (예정 투표용)
          if (status == VoteCardStatus.upcoming) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.grey[300]!, width: 1.r),
              ),
              child: _buildFooterSkeleton(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 스켈레톤 (Shimmer 적용)
        Shimmer.fromColors(
          baseColor: AppColors.grey300,
          highlightColor: AppColors.grey100,
          child: Center(
            child: Container(
              height: 22.h,
              width: 200.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // 타이머 영역 (개별 숫자 박스들)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 일(D) 부분: 08D
            _buildTimerBox(18.w), // 0
            SizedBox(width: 2.w),
            _buildTimerBox(18.w), // 8
            SizedBox(width: 2.w),
            _buildTimerBox(18.w), // D
            SizedBox(width: 8.w),

            // 시간(:) 부분: 04:18:20
            _buildTimerBox(18.w), // 0
            SizedBox(width: 2.w),
            _buildTimerBox(18.w), // 4
            SizedBox(width: 6.w),
            _buildTimerBox(18.w), // 4

            SizedBox(width: 8.w),

            _buildTimerBox(18.w), // 1
            SizedBox(width: 2.w),
            _buildTimerBox(18.w), // 8
            SizedBox(width: 6.w),
            _buildTimerBox(18.w), // 4

            SizedBox(width: 8.w),

            _buildTimerBox(18.w), // 2
            SizedBox(width: 2.w),
            _buildTimerBox(18.w), // 0
          ],
        ),
      ],
    );
  }

  /// 타이머 개별 숫자/문자 박스 생성
  Widget _buildTimerBox(double width) {
    return Container(
      width: width,
      height: 20.h,
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  Widget _buildVoteItemsSkeleton() {
    switch (status) {
      case VoteCardStatus.upcoming:
        // 예정: 간단한 목록 형태 (2개)
        return Column(
          children:
              List.generate(2, (index) => _buildUpcomingVoteItemSkeleton()),
        );
      case VoteCardStatus.ongoing:
        // 진행 중: 투표 버튼과 실시간 정보 포함 (3개)
        return Column(
          children:
              List.generate(3, (index) => _buildOngoingVoteItemSkeleton()),
        );
      case VoteCardStatus.ended:
        // 종료: 결과와 순위 정보 포함 (3개)
        return Column(
          children:
              List.generate(3, (index) => _buildEndedVoteItemSkeleton(index)),
        );
    }
  }

  Widget _buildUpcomingVoteItemSkeleton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          // 아티스트 이미지 스켈레톤
          Container(
            width: 30.w,
            height: 30.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),

          // 이름 영역
          Expanded(
            child: Container(
              height: 14.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingVoteItemSkeleton() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // 순위 영역
          SizedBox(
            width: 30.w,
            child: Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(width: 6.w),

          // 아티스트 이미지 스켈레톤
          Container(
            width: 35.w,
            height: 35.h,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아티스트 이름 스켈레톤
                Container(
                  height: 14.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 4.h),

                // 투표수와 퍼센트 스켈레톤
                Row(
                  children: [
                    Container(
                      height: 16.h,
                      width: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      height: 12.h,
                      width: 30.w,
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
          SizedBox(width: 12.w),

          // 투표 버튼 스켈레톤
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedVoteItemSkeleton(int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          // 순위 메달/숫자 영역 (1,2,3위는 다른 크기)
          SizedBox(
            width: 35.w,
            child: Container(
              width: index < 3 ? 20.w : 16.w,
              height: index < 3 ? 20.h : 16.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(index < 3 ? 10.r : 4.r),
              ),
            ),
          ),
          SizedBox(width: 8.w),

          // 아티스트 이미지 스켈레톤 (1위는 조금 더 크게)
          Container(
            width: index == 0 ? 40.w : 35.w,
            height: index == 0 ? 40.h : 35.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),

          // 이름과 결과 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 아티스트 이름 스켈레톤
                Container(
                  height: 14.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 4.h),

                // 최종 투표수와 퍼센트
                Row(
                  children: [
                    Container(
                      height: 16.h,
                      width: 70.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      height: 14.h,
                      width: 40.w,
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

          // 결과 아이콘 영역 (트로피나 체크 등)
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
    );
  }

  Widget _buildVoteItemsContainer() {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: Container(
        width: double.infinity,
        height: 260,
        padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: _buildVoteItemsSkeleton(),
      ),
    );
  }

  Widget _buildFooterSkeleton() {
    switch (status) {
      case VoteCardStatus.upcoming:
        // 예정: 참여 예정자 수 정보
        return Shimmer.fromColors(
          baseColor: AppColors.grey300,
          highlightColor: AppColors.grey100,
          child: Row(
            children: [
              Container(
                height: 12.h,
                width: 80.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        );
      case VoteCardStatus.ongoing:
        // 진행 중: 총 참여자 수와 남은 시간
        return Shimmer.fromColors(
          baseColor: AppColors.grey300,
          highlightColor: AppColors.grey100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 12.h,
                width: 100.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              Container(
                height: 12.h,
                width: 60.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        );
      case VoteCardStatus.ended:
        // 종료: 총 참여자 수와 종료 정보
        return Shimmer.fromColors(
          baseColor: AppColors.grey300,
          highlightColor: AppColors.grey100,
          child: Container(
            height: 12.h,
            width: 120.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        );
    }
  }
}
