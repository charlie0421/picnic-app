import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/ui/style.dart';
import 'vote_item_request_models.dart';
import 'application_count_tag.dart';

/// 공통 아티스트 정보 위젯
class CommonArtistWidget extends StatelessWidget {
  final ArtistModel? artist;
  final String artistName;
  final String? groupName;
  final int applicationCount;
  final double width;
  final double height;
  final String? currentSearchQuery;
  final int? listIndex;
  final Widget? trailing;

  const CommonArtistWidget({
    super.key,
    required this.artist,
    required this.artistName,
    this.groupName,
    required this.applicationCount,
    this.width = 48.0,
    this.height = 48.0,
    this.currentSearchQuery,
    this.listIndex,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // null 안전 처리
    final safeArtistName = artistName.isNotEmpty ? artistName : '알 수 없는 아티스트';
    final displayName = artist != null && artist!.name.isNotEmpty
        ? ArtistNameUtils.getDisplayName(artist!.name)
        : safeArtistName;

    final displayGroupName = artist?.artistGroup != null && artist!.artistGroup!.name.isNotEmpty
        ? ArtistNameUtils.getDisplayName(artist!.artistGroup!.name)
        : (groupName?.isNotEmpty == true ? groupName! : '');

    return Row(
      children: [
        // 아티스트 이미지 (더 작게)
        _buildArtistImage(),
        SizedBox(width: 8.w), // 간격 더 축소 (12.w -> 8.w)

        // 아티스트 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 높이 최소화
            children: [
              // 아티스트 이름
              _buildArtistName(displayName),
              if (displayGroupName.isNotEmpty) ...[
                SizedBox(height: 1.h), // 간격 더 축소 (2.h -> 1.h)
                _buildGroupInfo(displayGroupName),
              ],
            ],
          ),
        ),

        // 오른쪽 trailing 위젯 (상태 또는 버튼)
        if (trailing != null) ...[
          SizedBox(width: 6.w), // 간격 더 축소 (8.w -> 6.w)
          Row( // Column 대신 Row로 변경해서 더 컴팩트하게
            mainAxisSize: MainAxisSize.min,
            children: [
              // 신청수 태그
              ApplicationCountTag(applicationCount: applicationCount),
              SizedBox(width: 4.w), // 간격 더 축소 (8.w -> 4.w)
              trailing!,
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildArtistImage() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: artist?.image != null
            ? PicnicCachedNetworkImage(
                imageUrl: artist!.image!,
                fit: BoxFit.cover,
                width: width,
                height: height,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary500.withValues(alpha: 0.2),
                      AppColors.primary500.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary500,
                  size: 16.r,
                ),
              ),
      ),
    );
  }

  Widget _buildArtistName(String displayName) {
    // null 및 빈 문자열 안전 처리
    final safeName = displayName.isNotEmpty ? displayName : '알 수 없는 아티스트';
    
    if (currentSearchQuery != null && currentSearchQuery!.isNotEmpty) {
      // 검색 결과에서는 하이라이트 적용
      return KoreanSearchUtils.buildConditionalHighlightText(
        safeName,
        currentSearchQuery!,
        getTextStyle(AppTypo.caption12B, AppColors.grey900),
        highlightColor: AppColors.primary500.withValues(alpha: 0.2),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      // 일반 텍스트
      return Text(
        safeName,
        style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _buildGroupInfo(String displayGroupName) {
    // null 및 빈 문자열 안전 처리
    final safeGroupName = displayGroupName.isNotEmpty ? displayGroupName : '';
    
    return currentSearchQuery != null && currentSearchQuery!.isNotEmpty
        ? KoreanSearchUtils.buildConditionalHighlightText(
            safeGroupName,
            currentSearchQuery!,
            getTextStyle(AppTypo.caption12R, AppColors.grey600),
            highlightColor: AppColors.primary500.withValues(alpha: 0.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : Text(
            safeGroupName,
            style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
  }
}
