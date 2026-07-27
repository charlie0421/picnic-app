import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/ui/style.dart';

/// 스켈레톤 블록에 붙는 키.
///
/// 테스트가 "프레임은 Shimmer 밖, 블록은 Shimmer 안" 구조와 실제 페인트를
/// 블록 단위로 검사할 수 있게 공개한다.
@visibleForTesting
abstract final class VoteCardSkeletonUpcomingKeys {
  /// 헤더 카드 프레임(흰 배경 + 테두리 + 라운드). 불투명하므로 반드시
  /// **Shimmer 바깥**에 있어야 한다.
  static const Key headerFrame =
      ValueKey('vote_card_skeleton_upcoming.header.frame');
  static const Key title = ValueKey('vote_card_skeleton_upcoming.title');
  static const Key time = ValueKey('vote_card_skeleton_upcoming.time');

  /// 시작 예정 메시지 카드 프레임. 헤더와 같은 이유로 Shimmer 바깥.
  static const Key messageFrame =
      ValueKey('vote_card_skeleton_upcoming.message.frame');
  static const Key messageLine1 =
      ValueKey('vote_card_skeleton_upcoming.message.line1');
  static const Key messageLine2 =
      ValueKey('vote_card_skeleton_upcoming.message.line2');
}

/// Upcoming 투표 상태용 스켈레톤 위젯 (헤더만)
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
class VoteCardSkeletonUpcoming extends StatelessWidget {
  const VoteCardSkeletonUpcoming({super.key});

  /// 카드 프레임 배경색. 블록 사이 여백에서 이 색이 보여야 골격이 읽힌다.
  @visibleForTesting
  static const Color cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      margin: EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 부분 스켈레톤 (크기 축소)
          _buildHeaderFrame(),
          SizedBox(height: 8.h),
          // 시작 예정 메시지 영역 (높이 축소)
          _buildMessageFrame(),
        ],
      ),
    );
  }

  Widget _buildHeaderFrame() {
    return Container(
      key: VoteCardSkeletonUpcomingKeys.headerFrame,
      width: double.infinity,
      padding: EdgeInsets.all(10.r),
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
            // 제목 영역
            Container(
              key: VoteCardSkeletonUpcomingKeys.title,
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
              key: VoteCardSkeletonUpcomingKeys.time,
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
    );
  }

  Widget _buildMessageFrame() {
    return Container(
      key: VoteCardSkeletonUpcomingKeys.messageFrame,
      width: double.infinity,
      height: 40.h,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.grey[300]!, width: 1.r),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 시작 예정 텍스트 스켈레톤
            Container(
              key: VoteCardSkeletonUpcomingKeys.messageLine1,
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
              key: VoteCardSkeletonUpcomingKeys.messageLine2,
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
    );
  }
}
