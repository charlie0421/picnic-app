import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/ui/search_results_list.dart';
import 'package:picnic_lib/ui/style.dart';

/// 아티스트 검색 결과 아이템 위젯
class ArtistSearchResultItem extends StatelessWidget {
  const ArtistSearchResultItem({
    super.key,
    required this.artist,
    this.searchQuery = '',
    this.onTap,
    this.onBookmarkTap,
    this.showBookmarkButton = true,
  });

  final ArtistModel artist;
  final String searchQuery;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;
  final bool showBookmarkButton;

  @override
  Widget build(BuildContext context) {
    return SearchResultCard(
      onTap: onTap,
      child: Row(
        children: [
          // 아티스트 이미지
          _buildArtistImage(),
          
          SizedBox(width: 12.w),
          
          // 아티스트 정보
          Expanded(
            child: _buildArtistInfo(context),
          ),
          
          // 북마크 버튼
          if (showBookmarkButton) _buildBookmarkButton(),
        ],
      ),
    );
  }

  Widget _buildArtistImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: PicnicCachedNetworkImage(
        width: 48.w,
        height: 48.w,
        imageUrl: 'artist/${artist.id}/image.png',
        borderRadius: BorderRadius.circular(24.r),
      ),
    );
  }

  Widget _buildArtistInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아티스트 이름 (하이라이트 적용)
        RichText(
          text: TextSpan(
            children: _buildHighlightedTextSpans(
              getLocaleTextFromJson(artist.name),
              searchQuery,
              AppTypo.body16B,
              AppColors.grey900,
            ),
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // 그룹명 (하이라이트 적용)
        if (artist.artistGroup != null)
          RichText(
            text: TextSpan(
              children: _buildHighlightedTextSpans(
                getLocaleTextFromJson(artist.artistGroup!.name),
                searchQuery,
                AppTypo.caption12M,
                AppColors.grey600,
              ),
            ),
          ),
        
        // 추가 정보 (성별, 생년월일 등)
        if (artist.gender != null || artist.birthDate != null)
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Text(
              _buildAdditionalInfo(),
              style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
            ),
          ),
      ],
    );
  }

  Widget _buildBookmarkButton() {
    return GestureDetector(
      onTap: onBookmarkTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        child: SvgPicture.asset(
          package: 'picnic_lib',
          'assets/icons/bookmark_style=fill.svg',
          width: 20.w,
          height: 20.w,
          colorFilter: ColorFilter.mode(
            artist.isBookmarked == true
                ? AppColors.primary500
                : AppColors.grey300,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  String _buildAdditionalInfo() {
    final List<String> infoParts = [];
    
    if (artist.gender != null) {
      infoParts.add(artist.gender!);
    }
    
    if (artist.formattedBirthDate != null) {
      infoParts.add(artist.formattedBirthDate!);
    }
    
    return infoParts.join(' • ');
  }

  /// 검색어를 하이라이트하는 TextSpan 목록 생성
  List<TextSpan> _buildHighlightedTextSpans(
    String text,
    String query,
    AppTypo typo,
    Color color,
  ) {
    query = query.trim();
    if (query.isEmpty) {
      return [TextSpan(text: text, style: getTextStyle(typo, color))];
    }

    final spans = <TextSpan>[];
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    int startIndex = 0;

    while (true) {
      final index = lowercaseText.indexOf(lowercaseQuery, startIndex);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(startIndex),
          style: getTextStyle(typo, color),
        ));
        break;
      }

      if (index > startIndex) {
        spans.add(TextSpan(
          text: text.substring(startIndex, index),
          style: getTextStyle(typo, color),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: getTextStyle(typo, color).copyWith(
          backgroundColor: AppColors.primary500.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      startIndex = index + query.length;
    }

    return spans;
  }
}

/// 아티스트 검색 결과 목록 위젯
class ArtistSearchResultsList extends StatelessWidget {
  const ArtistSearchResultsList({
    super.key,
    required this.artists,
    this.searchQuery = '',
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.onArtistTap,
    this.onBookmarkTap,
    this.onRetry,
    this.onLoadMore,
    this.hasMore = false,
    this.scrollController,
    this.showBookmarkButton = true,
  });

  final List<ArtistModel> artists;
  final String searchQuery;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final ValueChanged<ArtistModel>? onArtistTap;
  final ValueChanged<ArtistModel>? onBookmarkTap;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final ScrollController? scrollController;
  final bool showBookmarkButton;

  @override
  Widget build(BuildContext context) {
    return SearchResultsList<ArtistModel>(
      items: artists,
      isLoading: isLoading,
      hasError: hasError,
      errorMessage: errorMessage,
      emptyMessage: searchQuery.isEmpty 
          ? '검색어를 입력해주세요'
          : '"$searchQuery"에 대한 검색 결과가 없습니다',
      onRetry: onRetry,
      onLoadMore: onLoadMore,
      hasMore: hasMore,
      scrollController: scrollController,
      itemBuilder: (context, artist, index) {
        return ArtistSearchResultItem(
          artist: artist,
          searchQuery: searchQuery,
          showBookmarkButton: showBookmarkButton,
          onTap: onArtistTap != null ? () => onArtistTap!(artist) : null,
          onBookmarkTap: onBookmarkTap != null ? () => onBookmarkTap!(artist) : null,
        );
      },
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
    );
  }
} 