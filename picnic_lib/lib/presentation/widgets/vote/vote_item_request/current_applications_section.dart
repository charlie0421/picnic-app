import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'common_artist_widget.dart';

/// 모든 사용자의 신청을 아티스트별로 표시하는 섹션
class CurrentApplicationsSection extends StatefulWidget {
  final List<Map<String, dynamic>> artistApplicationSummaries;
  final int totalApplications;
  final bool isLoading;

  const CurrentApplicationsSection({
    super.key,
    required this.artistApplicationSummaries,
    required this.totalApplications,
    this.isLoading = false,
  });

  @override
  State<CurrentApplicationsSection> createState() => _CurrentApplicationsSectionState();
}

class _CurrentApplicationsSectionState extends State<CurrentApplicationsSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.03),
            AppColors.primary500.withValues(alpha: 0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          widget.isLoading ? _buildLoadingSkeleton() : _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              Icons.leaderboard_rounded,
              color: AppColors.primary500,
              size: 14.r,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: widget.isLoading
                ? Shimmer.fromColors(
                    baseColor: AppColors.grey300,
                    highlightColor: AppColors.grey100,
                    child: Container(
                      height: 16.h,
                      width: 150.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  )
                : Text(
                    AppLocalizations.of(context).vote_item_request_status,
                    style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(12.r, 0, 12.r, 12.r),
        itemCount: 5, // 스켈레톤 아이템 개수
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 4.h),
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.grey00,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.grey200.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 아티스트 이미지 스켈레톤
                Shimmer.fromColors(
                  baseColor: AppColors.grey300,
                  highlightColor: AppColors.grey100,
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // 아티스트 이름 스켈레톤
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 아티스트 이름 (메인)
                      Shimmer.fromColors(
                        baseColor: AppColors.grey300,
                        highlightColor: AppColors.grey100,
                        child: Container(
                          height: 12.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      // 그룹명 (서브)
                      Shimmer.fromColors(
                        baseColor: AppColors.grey300,
                        highlightColor: AppColors.grey100,
                        child: Container(
                          height: 10.h,
                          width: 60.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // 상태 배지 스켈레톤들 - 개별적으로 분리
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 첫 번째 배지
                    Shimmer.fromColors(
                      baseColor: AppColors.grey300,
                      highlightColor: AppColors.grey100,
                      child: Container(
                        width: 35.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    // 두 번째 배지
                    Shimmer.fromColors(
                      baseColor: AppColors.grey300,
                      highlightColor: AppColors.grey100,
                      child: Container(
                        width: 35.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (widget.artistApplicationSummaries.isEmpty) {
      return _buildEmptyState();
    }

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(12.r, 0, 12.r, 12.r),
        itemCount: widget.artistApplicationSummaries.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final summary = widget.artistApplicationSummaries[index];
          return _buildArtistSummaryItem(summary, index);
        },
      ),
    );
  }

  Widget _buildArtistSummaryItem(Map<String, dynamic> summary, int index) {
    final artistData = summary['artist'] as Map<String, dynamic>?;
    final pendingCount = summary['pendingCount'] as int;
    final approvedCount = summary['approvedCount'] as int;
    final rejectedCount = summary['rejectedCount'] as int;

    // 아티스트 정보 추출
    String artistName = '알 수 없는 아티스트';
    String? groupName;
    ArtistModel? artist;

    if (artistData != null) {
      try {
        artist = ArtistModel.fromJson(artistData);
        artistName = ArtistNameUtils.getDisplayName(artist.name);
        groupName = artist.artistGroup?.name != null
            ? ArtistNameUtils.getDisplayName(artist.artistGroup!.name)
            : null;
      } catch (e) {
        // JSON 파싱 실패 시 기본값 사용
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.grey200.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아티스트 정보
          Expanded(
            child: CommonArtistWidget(
              artist: artist,
              artistName: artistName,
              groupName: groupName,
              width: 32.w,
              height: 32.w,
              listIndex: index,
            ),
          ),
          SizedBox(width: 8.w),
          // 상태별 카운트 표시
          _buildStatusCounts(pendingCount, approvedCount, rejectedCount),
        ],
      ),
    );
  }

  Widget _buildStatusCounts(
      int pendingCount, int approvedCount, int rejectedCount) {
    // 전체 신청 수
    final totalCount = pendingCount + approvedCount + rejectedCount;

    // 통합 상태 결정
    String statusLabel;
    Color statusColor;
    int? displayCount; // 표시할 숫자

    if (totalCount == approvedCount && approvedCount > 0) {
      // 전체 승인
      statusLabel =
          AppLocalizations.of(context).vote_item_request_status_approved;
      statusColor = Colors.green;
      displayCount = null; // 승인된 경우 숫자 숨김
    } else if (totalCount == rejectedCount && rejectedCount > 0) {
      // 전체 거절
      statusLabel =
          AppLocalizations.of(context).vote_item_request_status_rejected;
      statusColor = Colors.red;
      displayCount = null; // 거절인 경우 숫자 숨김
    } else {
      // 나머지 (대기중/혼합)
      statusLabel =
          AppLocalizations.of(context).vote_item_request_status_pending;
      statusColor = Colors.orange;
      displayCount = totalCount; // 대기중인 경우 전체 건수 표시
    }

    return _buildStatusCountBadge(statusLabel, displayCount, statusColor);
  }

  Widget _buildStatusCountBadge(String label, int? count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        count != null ? '$label $count' : label,
        style: getTextStyle(
          AppTypo.caption12B,
          color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 32.r,
              color: AppColors.grey400,
            ),
            SizedBox(height: 8.h),
            Text(
              '아직 신청된 내역이 없습니다',
              style: getTextStyle(AppTypo.body14R, AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아티스트 이름 처리 유틸리티 클래스
class ArtistNameUtils {
  static String getDisplayName(Map<String, dynamic> nameMap) {
    final koreanName = nameMap['ko'] as String? ?? '';
    final englishName = nameMap['en'] as String? ?? '';

    if (koreanName.isNotEmpty) {
      return koreanName;
    } else if (englishName.isNotEmpty) {
      return englishName;
    } else {
      return '알 수 없는 아티스트';
    }
  }
}
