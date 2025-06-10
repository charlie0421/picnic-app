import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote_request_user.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';
import 'common_artist_widget.dart';
import 'status_badge.dart';

/// 현재 신청 리스트 섹션 위젯
class CurrentApplicationsSection extends StatelessWidget {
  final List<VoteRequestUser> currentUserApplications;
  final List<Map<String, dynamic>> currentUserApplicationsWithDetails;
  final Map<String, int> userApplicationCounts;
  final Future<ArtistModel?> Function(String) getArtistByName;

  const CurrentApplicationsSection({
    super.key,
    required this.currentUserApplications,
    required this.currentUserApplicationsWithDetails,
    required this.userApplicationCounts,
    required this.getArtistByName,
  });

  Map<String, String?> _getArtistInfo(VoteRequestUser application) {
    try {
      final detailData = currentUserApplicationsWithDetails.firstWhere(
        (detail) => detail['id'] == application.id,
        orElse: () => <String, dynamic>{},
      );

      if (detailData.isNotEmpty && detailData['vote_requests'] != null) {
        final voteRequest = detailData['vote_requests'];
        final artistName = voteRequest['title'] as String? ??
            t('vote_item_request_artist_name_missing');
        final groupName = voteRequest['description'] as String?;

        return {
          'artistName': artistName,
          'groupName': groupName,
        };
      }
      return {
        'artistName': t('vote_item_request_artist_name_missing'),
        'groupName': null,
      };
    } catch (e) {
      return {
        'artistName': t('vote_item_request_artist_name_missing'),
        'groupName': null,
      };
    }
  }

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
          Padding(
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
                    Icons.pending_actions_rounded,
                    color: AppColors.primary500,
                    size: 14.r,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '${t('vote_item_request_current_item_request')} (${currentUserApplications.length}개)',
                    style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
                        child: currentUserApplications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: AppColors.grey200.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            Icons.inbox_rounded,
                            color: AppColors.grey500,
                            size: 32.r,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          t('vote_item_request_no_item_request_yet'),
                          style:
                              getTextStyle(AppTypo.body14R, AppColors.grey500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(12.r, 0, 12.r, 12.r),
                    itemCount: currentUserApplications.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: false,
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final application = currentUserApplications[index];
                      final artistInfo = _getArtistInfo(application);
                      final artistName = artistInfo['artistName']!;
                      final groupName = artistInfo['groupName'];
                      final applicationCount = userApplicationCounts[application.id] ?? 0;

                      return Container(
                        margin: EdgeInsets.only(bottom: 4.h), // 간격 축소
                        padding: EdgeInsets.all(6.r), // 패딩 축소
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
                        child: FutureBuilder<ArtistModel?>(
                          future: getArtistByName(artistName),
                          builder: (context, snapshot) {
                            final artist = snapshot.data;
                            return CommonArtistWidget(
                              artist: artist,
                              artistName: artistName,
                              groupName: groupName,
                              applicationCount: applicationCount,
                              width: 32.w, // 크기 더 축소 (36.w -> 32.w)
                              height: 32.w, // 크기 더 축소 (36.w -> 32.w)
                              listIndex: index,
                              trailing: StatusBadge(status: application.status),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 