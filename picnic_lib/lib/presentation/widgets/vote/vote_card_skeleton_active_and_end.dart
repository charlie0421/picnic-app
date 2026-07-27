import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// 스켈레톤 블록에 붙는 키.
///
/// 테스트가 "프레임은 Shimmer 밖, 블록은 Shimmer 안" 구조와 실제 페인트를
/// 블록 단위로 검사할 수 있게 공개한다.
@visibleForTesting
abstract final class VoteCardSkeletonActiveAndEndKeys {
  /// 헤더 카드 프레임(흰 배경 + 테두리 + 라운드). 불투명하므로 반드시
  /// **Shimmer 바깥**에 있어야 한다.
  static const Key headerFrame =
      ValueKey('vote_card_skeleton_active_and_end.header.frame');
  static const Key title = ValueKey('vote_card_skeleton_active_and_end.title');
  static const Key status =
      ValueKey('vote_card_skeleton_active_and_end.status');

  /// 결과 카드 프레임. 헤더와 같은 이유로 Shimmer 바깥.
  static const Key resultFrame =
      ValueKey('vote_card_skeleton_active_and_end.result.frame');

  /// 결과 카드가 그리는 순위 열 수.
  static const int rankCount = 3;

  static Key rankCircle(int index) =>
      ValueKey('vote_card_skeleton_active_and_end.rank$index.circle');
  static Key rankLabel(int index) =>
      ValueKey('vote_card_skeleton_active_and_end.rank$index.label');
}

/// End 투표 상태용 스켈레톤 위젯 (헤더 + 결과 표시)
///
/// ## 왜 불투명한 것이 Shimmer 밖에 있어야 하나
/// [Shimmer] 는 자식 전체를 `BlendMode.srcIn` 인 ShaderMask 로 덮는다
/// (shimmer 3.0.0 `_Shimmer.paint`). srcIn 은 자식의 **알파만** 남기고 색은
/// 전부 그라디언트로 갈아끼우므로, 흰 배경 카드 프레임을 Shimmer 안에 넣으면
/// 그 위의 블록들이 배경과 한 덩어리로 칠해져 구조 없는 회색 라운드 사각형만
/// 남는다. 이 파일은 예전에 정확히 그 상태였다 — 위젯 최상위가 통째로
/// `Shimmer.fromColors` 안에 있었다.
///
/// 그래서 지금 구조는 `vote_detail_skeleton.dart` 와 같다:
///   - 카드 프레임(흰 배경 / 테두리 / 라운드)은 Shimmer **바깥**,
///   - 알파를 가진 블록들만 각 프레임이 직접 든 Shimmer **안**.
class VoteCardSkeletonActiveAndEnd extends StatelessWidget {
  const VoteCardSkeletonActiveAndEnd({super.key});

  /// 카드 프레임 배경색. 블록 사이 여백에서 이 색이 보여야 골격이 읽힌다.
  @visibleForTesting
  static const Color cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.only(top: 4, bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 부분 스켈레톤 (크기 축소)
          _buildHeaderFrame(),
          SizedBox(height: 8.h),
          // 투표 결과 영역 스켈레톤 (간소화)
          _buildResultFrame(),
        ],
      ),
    );
  }

  Widget _buildHeaderFrame() {
    return Container(
      key: VoteCardSkeletonActiveAndEndKeys.headerFrame,
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.grey[300]!, width: 1.r),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        // 이 안에는 불투명 배경을 두지 말 것 (클래스 문서의 srcIn 문단 참고).
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목 영역 (크기 축소)
            Container(
              key: VoteCardSkeletonActiveAndEndKeys.title,
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
              key: VoteCardSkeletonActiveAndEndKeys.status,
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
    );
  }

  Widget _buildResultFrame() {
    return Container(
      key: VoteCardSkeletonActiveAndEndKeys.resultFrame,
      width: double.infinity,
      height: 80.h,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.grey[300]!, width: 1.r),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 간단한 순위 스켈레톤들
            for (int i = 0;
                i < VoteCardSkeletonActiveAndEndKeys.rankCount;
                i++)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    key: VoteCardSkeletonActiveAndEndKeys.rankCircle(i),
                    width: 30.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    key: VoteCardSkeletonActiveAndEndKeys.rankLabel(i),
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
    );
  }
}
