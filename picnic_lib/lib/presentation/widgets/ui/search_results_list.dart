import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

/// 검색 결과를 표시하는 재사용 가능한 위젯
///
/// [T] 검색 결과 아이템의 타입
class SearchResultsList<T> extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.emptyMessage,
    this.onRetry,
    this.onLoadMore,
    this.hasMore = false,
    this.scrollController,
    this.padding,
    this.separatorBuilder,
  });

  /// 검색 결과 아이템 목록
  final List<T> items;

  /// 각 아이템을 빌드하는 함수
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// 로딩 상태
  final bool isLoading;

  /// 에러 상태
  final bool hasError;

  /// 에러 메시지
  final String? errorMessage;

  /// 빈 결과일 때 표시할 메시지
  final String? emptyMessage;

  /// 재시도 콜백
  final VoidCallback? onRetry;

  /// 더 많은 결과 로드 콜백
  final VoidCallback? onLoadMore;

  /// 더 많은 결과가 있는지 여부
  final bool hasMore;

  /// 스크롤 컨트롤러
  final ScrollController? scrollController;

  /// 패딩
  final EdgeInsetsGeometry? padding;

  /// 아이템 간 구분자 빌더
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return _buildErrorView(context);
    }

    if (isLoading && items.isEmpty) {
      return _buildLoadingView();
    }

    if (items.isEmpty) {
      return _buildEmptyView(context);
    }

    return _buildResultsList(context);
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(16),
          vertical: PicnicUi.vertical(16),
        ),
        child: PicnicFeedback(
          icon: Icons.error_outline,
          message: errorMessage ?? '검색 중 오류가 발생했습니다',
          actionLabel: onRetry == null ? null : '다시 시도',
          onAction: onRetry,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(16),
          vertical: PicnicUi.vertical(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MediumPulseLoadingIndicator(),
            SizedBox(height: PicnicUi.vertical(16)),
            Text(
              '검색 중...',
              style: PicnicUi.text(color: PicnicUi.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(16),
          vertical: PicnicUi.vertical(16),
        ),
        child: PicnicFeedback(
          icon: Icons.search_off,
          message: emptyMessage ?? '검색 결과가 없습니다',
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // 스크롤이 끝에 도달했을 때 더 많은 데이터 로드
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            hasMore &&
            !isLoading &&
            onLoadMore != null) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.separated(
        controller: scrollController,
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: PicnicUi.horizontal(16),
              vertical: PicnicUi.vertical(16),
            ),
        itemCount: items.length + (isLoading ? 1 : 0),
        separatorBuilder:
            separatorBuilder ??
            (context, index) => SizedBox(height: PicnicUi.vertical(8)),
        itemBuilder: (context, index) {
          // 로딩 인디케이터 표시
          if (index == items.length) {
            return _buildLoadMoreIndicator();
          }

          return itemBuilder(context, items[index], index);
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: PicnicUi.vertical(16)),
      child: Center(child: const SmallPulseLoadingIndicator()),
    );
  }
}

/// 검색 결과 아이템을 위한 기본 카드 위젯
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(vertical: PicnicUi.vertical(4)),
      child: Material(
        color: PicnicUi.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: PicnicUi.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: PicnicUi.minimumTapTarget,
            ),
            child: Padding(
              padding:
                  padding ??
                  EdgeInsets.symmetric(
                    horizontal: PicnicUi.horizontal(16),
                    vertical: PicnicUi.vertical(16),
                  ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
