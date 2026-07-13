import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';
import 'package:picnic_lib/ui/style.dart';

/// 홈 화면 전용 "현재 진행중인 투표" 요약 카드.
///
/// [VoteInfoCard]와 달리 rank-1 항목만 표시하며 낮은 높이로 렌더링된다.
/// 저장/공유는 `VoteInfoCard`와 동일한 [ShareUtils] 메커니즘을 재사용한다.
class HomeFeaturedVoteCard extends ConsumerStatefulWidget {
  final VoteModel vote;

  const HomeFeaturedVoteCard({super.key, required this.vote});

  @override
  ConsumerState<HomeFeaturedVoteCard> createState() =>
      _HomeFeaturedVoteCardState();
}

class _HomeFeaturedVoteCardState extends ConsumerState<HomeFeaturedVoteCard> {
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  bool _isSaving = false;

  void _handleSaveImage() async {
    await ShareUtils.saveImage(
      _globalKey,
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        setState(() => _isSaving = true);
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() => _isSaving = false);
      },
    );
  }

  void _handleShareToTwitter() async {
    await ShareUtils.shareToSocial(
      _shareKey,
      message: getLocaleTextFromJson(
        widget.vote.title,
        navigatorKey.currentContext!,
      ),
      hashtag:
          '#Picnic #Vote #PicnicApp #${getLocaleTextFromJson(widget.vote.title, navigatorKey.currentContext!).replaceAll(' ', '')}',
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        setState(() => _isSaving = true);
      },
      downloadLink: await createBranchLink(
        getLocaleTextFromJson(widget.vote.title, context),
        '${Environment.appLinkPrefix}/vote/detail/${widget.vote.id}',
      ),
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() => _isSaving = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vote = widget.vote;
    final topItem =
        (vote.voteItem?.isNotEmpty ?? false) ? vote.voteItem!.first : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: RepaintBoundary(
        key: _globalKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _shareKey,
              child: Column(
                children: [
                  Text(
                    getLocaleTextFromJson(vote.title, context),
                    style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (vote.stopAt != null)
                    CountdownTimer(
                      endTime: vote.stopAt!,
                      status: VoteStatus.active,
                    ),
                  const SizedBox(height: 12),
                  if (topItem != null) _buildTopItem(topItem),
                ],
              ),
            ),
            if (!_isSaving)
              ShareSection(
                saveButtonText: AppLocalizations.of(context).save,
                shareButtonText: AppLocalizations.of(context).share,
                onSave: _handleSaveImage,
                onShare: _handleShareToTwitter,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItem(VoteItemModel item) {
    final name = item.artist?.name != null
        ? getLocaleTextFromJson(item.artist!.name)
        : (item.artistGroup?.name != null
            ? getLocaleTextFromJson(item.artistGroup!.name)
            : '');
    final imageUrl = item.artist?.image ?? item.artistGroup?.image ?? '';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: PicnicCachedNetworkImage(
            imageUrl: imageUrl,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            name,
            style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${item.voteTotal ?? 0}',
          style: getTextStyle(AppTypo.body16B, AppColors.primary500),
        ),
      ],
    );
  }
}
