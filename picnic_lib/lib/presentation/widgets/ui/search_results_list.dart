import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';

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
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16.h),
            Text(
              errorMessage ?? '검색 중 오류가 발생했습니다',
              style: getTextStyle(AppTypo.body16R, AppColors.grey600),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: AppColors.grey00,
                ),
                child: Text(
                  '다시 시도',
                  style: getTextStyle(AppTypo.body14B, AppColors.grey00),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MediumPulseLoadingIndicator(
              iconColor: AppColors.primary500,
            ),
            SizedBox(height: 16.h),
            Text(
              '검색 중...',
              style: getTextStyle(AppTypo.body16R, AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48.w,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16.h),
            Text(
              emptyMessage ?? '검색 결과가 없습니다',
              style: getTextStyle(AppTypo.body16R, AppColors.grey600),
              textAlign: TextAlign.center,
            ),
          ],
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
        padding: padding ?? EdgeInsets.all(16.w),
        itemCount: items.length + (isLoading ? 1 : 0),
        separatorBuilder: separatorBuilder ?? 
            (context, index) => SizedBox(height: 8.h),
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
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: SmallPulseLoadingIndicator(
          iconColor: AppColors.primary500,
        ),
      ),
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
      margin: margin ?? EdgeInsets.symmetric(vertical: 4.h),
      child: Material(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(8.r),
        elevation: 1,
        shadowColor: AppColors.grey900.withValues(alpha:0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ),
      ),
    );
  }
} 