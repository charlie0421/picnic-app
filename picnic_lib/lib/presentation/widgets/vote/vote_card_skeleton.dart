import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_card_layout.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

/// 투표 카드 스켈레톤 상태
enum VoteCardStatus {
  upcoming, // 예정
  ongoing, // 진행 중
  ended, // 종료
}

/// 투표 카드 스켈레톤 위젯
class VoteCardSkeleton extends StatelessWidget {
  final VoteCardStatus status;

  const VoteCardSkeleton({super.key, this.status = VoteCardStatus.ongoing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.only(top: 8, bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _buildContents(context, bounded: constraints.hasBoundedHeight),
      ),
    );
  }

  Widget _buildContents(BuildContext context, {required bool bounded}) {
    final body = status == VoteCardStatus.upcoming
        ? _buildUpcomingGridSkeleton(context, bounded: bounded)
        : Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildVoteItemsContainer(),
          );
    final cardCapture = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderSkeleton(),
        if (bounded) Flexible(fit: FlexFit.loose, child: body) else body,
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bounded)
          Flexible(fit: FlexFit.loose, child: cardCapture)
        else
          cardCapture,
        _buildFooterSkeleton(context),
      ],
    );
  }

  Widget _buildHeaderSkeleton() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          constraints: BoxConstraints(
            minHeight: status == VoteCardStatus.ongoing ? 48 : 0,
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: status == VoteCardStatus.ongoing ? 48 : 0,
          ),
          child: Shimmer.fromColors(
            baseColor: AppColors.grey300,
            highlightColor: AppColors.grey100,
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
        if (status == VoteCardStatus.upcoming)
          Container(
            height: 20,
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.center,
            child: Shimmer.fromColors(
              baseColor: AppColors.grey300,
              highlightColor: AppColors.grey100,
              child: Container(
                width: 72.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        if (status == VoteCardStatus.ended)
          Shimmer.fromColors(
            baseColor: AppColors.grey300,
            highlightColor: AppColors.grey100,
            child: Container(
              width: 72.w,
              height: 17,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        if (status != VoteCardStatus.ended) _buildTimerSkeleton(),
      ],
    );
  }

  Widget _buildTimerSkeleton() {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimerBox(18),
          const SizedBox(width: 2),
          _buildTimerBox(18),
          const SizedBox(width: 6),
          _buildTimerBox(18),
          const SizedBox(width: 2),
          _buildTimerBox(18),
          const SizedBox(width: 10),
          _buildTimerBox(18),
          const SizedBox(width: 2),
          _buildTimerBox(18),
          const SizedBox(width: 10),
          _buildTimerBox(18),
          const SizedBox(width: 2),
          _buildTimerBox(18),
        ],
      ),
    );
  }

  Widget _buildUpcomingGridSkeleton(
    BuildContext context, {
    required bool bounded,
  }) {
    final grid = Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: PicnicUi.border, width: 1.5.w),
      ),
      child: Column(
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (bounded)
            Expanded(child: grid)
          else
            SizedBox(
              height: VoteCardLayout.thumbnailGridExtent(
                context,
                VoteCardLayout.maximumThumbnailRows,
              ),
              child: grid,
            ),
          SizedBox(
            height: VoteCardLayout.thumbnailPagerHeight,
            child: Center(
              child: Shimmer.fromColors(
                baseColor: AppColors.grey300,
                highlightColor: AppColors.grey100,
                child: Container(
                  width: 96.w,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 타이머 개별 숫자/문자 박스 생성
  Widget _buildTimerBox(double width) {
    return Container(
      width: width,
      height: 18,
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
          children: List.generate(
            2,
            (index) => _buildUpcomingVoteItemSkeleton(),
          ),
        );
      case VoteCardStatus.ongoing:
        // 진행 중: 투표 버튼과 실시간 정보 포함 (3개)
        return Column(
          children: List.generate(
            3,
            (index) => _buildOngoingVoteItemSkeleton(),
          ),
        );
      case VoteCardStatus.ended:
        // 종료: 결과와 순위 정보 포함 (3개)
        return Column(
          children: List.generate(
            3,
            (index) => _buildEndedVoteItemSkeleton(index),
          ),
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
    // 불투명한 카드 프레임(흰 배경 + 테두리)은 Shimmer **바깥**에 있어야 한다.
    // Shimmer 는 자식을 BlendMode.srcIn ShaderMask 로 덮으므로(shimmer 3.0.0
    // `_Shimmer.paint`), 프레임이 Shimmer 안에 있으면 그 위의 아이템 블록들이
    // 배경과 한 덩어리로 칠해져 구조 없는 회색 라운드 사각형만 남는다.
    // 같은 패턴: vote_detail_skeleton.dart 등.
    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
      decoration: BoxDecoration(
        color: PicnicUi.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: PicnicUi.border, width: 1.5),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        child: _buildVoteItemsSkeleton(),
      ),
    );
  }

  Widget _buildFooterSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: VoteCardLayout.shareSectionExtent(context) - 16,
        child: Shimmer.fromColors(
          baseColor: AppColors.grey300,
          highlightColor: AppColors.grey100,
          child: Row(
            mainAxisAlignment: status == VoteCardStatus.ongoing
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              Container(
                width: status == VoteCardStatus.ongoing ? 100.w : 120.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              if (status == VoteCardStatus.ongoing)
                Container(
                  width: 60.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
