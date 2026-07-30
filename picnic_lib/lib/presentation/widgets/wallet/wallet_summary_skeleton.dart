import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

/// 별사탕 파우치의 로딩 자리 표시자.
///
/// 앱의 나머지 카드/리스트와 같은 규약 — `Shimmer.fromColors(grey300 →
/// grey100)` 로 펄스하는 스켈레톤 (`vote_card_skeleton.dart`,
/// `vote_detail_skeleton.dart`, `purchase_star_candy_state.dart`) — 을 따른다.
/// 전에는 파우치만 [CircularProgressIndicator] 를 돌려서 앱에서 유일하게
/// 스피너로 로딩을 알리는 카드였다.
///
/// 불투명한 카드 프레임(배경 + 테두리)은 Shimmer **바깥**에 둔다. Shimmer 는
/// 자식을 `BlendMode.srcIn` ShaderMask 로 덮으므로(shimmer 3.0.0
/// `_Shimmer.paint`), 프레임이 안에 있으면 내용 블록들이 배경과 한 덩어리로
/// 칠해져 구조 없는 회색 사각형만 남는다. 같은 패턴:
/// `vote_card_skeleton.dart` `_buildVoteItemsContainer`.
class WalletSummarySkeleton extends StatelessWidget {
  const WalletSummarySkeleton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _WalletSegmentSkeleton(compact: compact)),
            const SizedBox(width: 8),
            Expanded(child: _WalletSegmentSkeleton(compact: compact)),
            const SizedBox(width: 8),
            Expanded(child: _WalletSegmentSkeleton(compact: compact)),
          ],
        ),
      ],
    );
  }
}

/// `WalletCurrencySegment` 한 칸의 자리 표시자.
///
/// 치수(테두리 반경, 패딩, 아이콘 크기, 각 줄의 높이)를 실제 세그먼트와 맞춰
/// 데이터가 도착하는 순간 카드 높이가 튀지 않게 한다. 글자줄 높이는 해당
/// 폰트 크기의 라인 박스에 맞춘 근사치이고, 총 높이 일치는
/// `wallet_summary_skeleton_test.dart` 가 실제 패널을 직접 재서 고정한다.
class _WalletSegmentSkeleton extends StatelessWidget {
  const _WalletSegmentSkeleton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 38.0 : 48.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey00,
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(17),
      ),
      padding: EdgeInsets.fromLTRB(8, compact ? 9 : 12, 6, compact ? 10 : 13),
      child: Shimmer.fromColors(
        baseColor: AppColors.grey300,
        highlightColor: AppColors.grey100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 통화 아이콘 자리.
            Container(
              width: iconSize,
              height: iconSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            // 통화 이름 (fontSize 11) 한 줄 자리.
            Container(
              width: 48,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 2),
            // 금액 (fontSize 22 / compact 18, height 1.05) 자리.
            Container(
              width: double.infinity,
              height: compact ? 19 : 23,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
