import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// 스켈레톤 블록에 붙는 키.
///
/// 테스트가 골격을 **블록 단위로** 잡을 수 있게 공개한다. 이게 없으면 회귀
/// 테스트가 스켈레톤 바깥 껍데기만 재게 되고, 안쪽을 통째로 지워도 초록이 뜬다.
@visibleForTesting
abstract final class VoteDetailSkeletonKeys {
  // --- 상단(헤더/제목/날짜/버튼) 영역: 카드 없이 페이지 배경 위에 바로 놓인다. ---
  static const Key header = ValueKey('vote_detail_skeleton.header');
  static const Key titleLine1 = ValueKey('vote_detail_skeleton.title1');
  static const Key titleLine2 = ValueKey('vote_detail_skeleton.title2');
  static const Key date = ValueKey('vote_detail_skeleton.date');
  static const Key button = ValueKey('vote_detail_skeleton.button');

  /// 상단 영역에서 위 -> 아래 순서인 블록.
  static const List<List<Key>> topRowsTopToBottom = <List<Key>>[
    <Key>[header],
    <Key>[titleLine1],
    <Key>[titleLine2],
    <Key>[date],
    <Key>[button],
  ];

  // --- 투표 목록 카드 영역 ---

  /// 목록 카드 프레임(흰 배경 + 테두리 + 라운드).
  /// 불투명하므로 반드시 **Shimmer 바깥**에 있어야 한다.
  static const Key voteListFrame = ValueKey('vote_detail_skeleton.list.frame');

  /// 카드 상단의 검색바 자리.
  static const Key search = ValueKey('vote_detail_skeleton.list.search');

  /// 카드가 그리는 투표 아이템 행 수.
  static const int itemCount = 5;

  static Key medal(int index) => ValueKey('vote_detail_skeleton.item$index.medal');
  static Key rank(int index) => ValueKey('vote_detail_skeleton.item$index.rank');
  static Key avatar(int index) =>
      ValueKey('vote_detail_skeleton.item$index.avatar');
  static Key name(int index) => ValueKey('vote_detail_skeleton.item$index.name');
  static Key score(int index) =>
      ValueKey('vote_detail_skeleton.item$index.score');
  static Key action(int index) =>
      ValueKey('vote_detail_skeleton.item$index.action');

  /// 카드 안에서 위 -> 아래 순서인 행. 한 원소가 한 시각적 행이다.
  ///
  /// 테스트는 이 목록만 훑으므로, 여기에 없는 블록은 지워도 초록이 뜬다.
  /// 새 블록을 추가하면 반드시 여기에도 넣을 것.
  static List<List<Key>> get listRowsTopToBottom => <List<Key>>[
        <Key>[search],
        for (var i = 0; i < itemCount; i++) itemRow(i),
      ];

  static List<Key> itemRow(int index) => <Key>[
        for (final column in itemColumnsLeftToRight(index)) ...column,
      ];

  /// 아이템 한 행 안에서 왼쪽 -> 오른쪽 순서인 열. 열 안쪽 블록은 세로로 쌓인다.
  static List<List<Key>> itemColumnsLeftToRight(int index) => <List<Key>>[
        <Key>[if (index < 3) medal(index), rank(index)],
        <Key>[avatar(index)],
        <Key>[name(index), score(index)],
        <Key>[action(index)],
      ];
}

/// Skeleton/shimmer loading UI for [VoteDetailPage].
///
/// Extracted to keep the main page file focused on interactive logic.
///
/// ## 왜 불투명한 것이 Shimmer 밖에 있어야 하나
/// [Shimmer] 는 자식 전체를 `BlendMode.srcIn` 인 ShaderMask 로 덮는다
/// (shimmer 3.0.0 `_Shimmer.paint`). srcIn 은 자식의 **알파만** 남기고 색은 전부
/// 그라디언트로 갈아끼우므로, 불투명 배경을 Shimmer 안에 넣으면 그 위에 무엇을
/// 그리든 배경까지 한 덩어리로 칠해져 아무 구조도 없는 회색 라운드 사각형 하나가
/// 된다. 이 파일은 예전에 정확히 그 상태였다 — 목록 카드의 흰 배경
/// (`Container(color: Colors.white)`)이 페이지 최상위 `Shimmer` 안에 있어서,
/// 검색바와 5개 아이템 행이 전부 배경과 함께 뭉개져 보이지 않았다.
///
/// 그래서 지금 구조는:
///   - 목록 카드 프레임(흰 배경 / 테두리 / 라운드)은 Shimmer **바깥**,
///   - 알파를 가진 블록들만 Shimmer **안**.
/// 그러면 반짝이는 건 블록뿐이고 블록 사이 여백은 알파 0 이라 카드 배경이 비쳐
/// 골격이 실제로 눈에 보인다.
///
/// 저장소 안의 같은 패턴: `_FeaturedVoteCardSkeleton`
/// (`home_featured_vote_carousel.dart`), `VideoListItemSkeleton`.
///
/// [buildVoteListOnly] 는 페이지 밖(`vote_detail_page.dart` 의 아이템 로딩
/// 브랜치)에서도 단독으로 쓰이므로, 카드가 **자기 Shimmer 를 직접 들고 있다**.
/// 호출부가 Shimmer 로 감싸 주기를 기대하면 그 호출부에서는 흰 블록이 흰 카드
/// 위에 그려져 아무것도 보이지 않는다.
class VoteDetailSkeleton extends StatelessWidget {
  const VoteDetailSkeleton({super.key});

  /// 셔머 그라디언트 색(= `Colors.grey.shade300` / `shade100`).
  ///
  /// 테스트가 "블록이 실제로 칠해졌는가" 를 픽셀로 확인할 때 기준색으로 쓴다.
  @visibleForTesting
  static const Color shimmerBaseColor = Color(0xFFE0E0E0);
  @visibleForTesting
  static const Color shimmerHighlightColor = Color(0xFFF5F5F5);

  /// 목록 카드의 배경색. 블록 사이 여백에서 이 색이 보여야 골격이 읽힌다.
  @visibleForTesting
  static const Color cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          // 상단 영역에는 불투명 배경이 없다 — 블록만 있으므로 통째로 감싸도 된다.
          child: Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSkeleton(),
                const SizedBox(height: 20),
                _buildTitleSkeleton(),
                const SizedBox(height: 12),
                _buildDateSkeleton(),
                const SizedBox(height: 12),
                _buildButtonSkeleton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // 카드는 자기 프레임과 자기 Shimmer 를 직접 들고 있다. 여기서 감싸면
        // 흰 카드 배경까지 srcIn 에 먹혀 목록 전체가 회색 덩어리가 된다.
        SliverToBoxAdapter(child: _buildVoteListSkeletonStatic()),
      ],
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      key: VoteDetailSkeletonKeys.header,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 57.w),
      child: Column(
        children: [
          Container(
            key: VoteDetailSkeletonKeys.titleLine1,
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            key: VoteDetailSkeletonKeys.titleLine2,
            height: 24,
            width: 200.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSkeleton() {
    return Center(
      child: Container(
        key: VoteDetailSkeletonKeys.date,
        height: 18,
        width: 250.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

  Widget _buildButtonSkeleton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: Container(
          key: VoteDetailSkeletonKeys.button,
          width: 120.w,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
      ),
    );
  }

  /// Vote list area skeleton, usable standalone (e.g. within an existing CustomScrollView).
  static Widget buildVoteListOnly() => _buildVoteListSkeletonStatic();

  static Widget _buildVoteListSkeletonStatic() {
    return Padding(
      // 바깥 여백은 프레임 밖에 둔다 — [VoteDetailSkeletonKeys.voteListFrame] 의
      // 사각형이 "실제로 칠해지는 카드" 와 정확히 같아야 픽셀 검사가 성립한다.
      padding: EdgeInsets.only(top: 24, left: 16.w, right: 16.w),
      child: _buildVoteListFrame(),
    );
  }

  static Widget _buildVoteListFrame() {
    return Container(
      key: VoteDetailSkeletonKeys.voteListFrame,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: shimmerBaseColor, width: 1.r),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70.r),
          topRight: Radius.circular(70.r),
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
        color: cardColor,
      ),
      child: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        // 이 안에는 불투명 배경을 두지 말 것 (클래스 문서의 srcIn 문단 참고).
        child: Padding(
          padding: EdgeInsets.only(
            top: 56,
            left: 16.w,
            right: 16.w,
            bottom: 24,
          ).r,
          child: Column(
            children: [
              Container(
                key: VoteDetailSkeletonKeys.search,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(
                VoteDetailSkeletonKeys.itemCount,
                (index) => _buildVoteItemSkeletonStatic(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildVoteItemSkeletonStatic(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Row(
        children: [
          SizedBox(
            width: 39,
            child: Column(
              children: [
                if (index < 3)
                  Container(
                    key: VoteDetailSkeletonKeys.medal(index),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  key: VoteDetailSkeletonKeys.rank(index),
                  width: 20,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            key: VoteDetailSkeletonKeys.avatar(index),
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: VoteDetailSkeletonKeys.name(index),
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  key: VoteDetailSkeletonKeys.score(index),
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            key: VoteDetailSkeletonKeys.action(index),
            width: 24,
            height: 24,
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
