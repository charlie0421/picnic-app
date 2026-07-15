import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';
import 'package:picnic_lib/ui/style.dart';

/// 홈 화면 전용 "현재 진행중인 투표" 요약 카드.
///
/// 1위 항목을 큰 이미지로 강조하고, 득표 점유율([percent])을 퍼센트로 표시한다.
/// 캐러셀([HomeFeaturedVoteCarousel]) 안에서 bounded height 로 렌더링되며,
/// 이미지는 남은 공간을 채운다. 저장/공유는 `VoteInfoCard`와 동일한
/// [ShareUtils] 메커니즘을 재사용한다.
class HomeFeaturedVoteCard extends ConsumerStatefulWidget {
  final VoteModel vote;

  /// 1위 항목의 득표 점유율(0.0 ~ 1.0).
  final double percent;

  const HomeFeaturedVoteCard({
    super.key,
    required this.vote,
    this.percent = 0,
  });

  @override
  ConsumerState<HomeFeaturedVoteCard> createState() =>
      _HomeFeaturedVoteCardState();
}

class _HomeFeaturedVoteCardState extends ConsumerState<HomeFeaturedVoteCard> {
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  bool _isSaving = false;

  // 저장/공유 시작 시 홈의 로딩 오버레이 State 를 붙잡아 둔다. 캐러셀을 스와이프해
  // 이 카드가 dispose 돼도(카드 context 무효화) 이 참조로 hide() 가 도달하므로
  // 오버레이가 홈을 영구히 덮는 일이 없다.
  LoadingOverlayWithIconState? _overlay;

  void _showOverlay() {
    _overlay = LoadingOverlayWithIcon.of(context);
    _overlay?.show();
    if (mounted) setState(() => _isSaving = true);
  }

  void _hideOverlay() {
    _overlay?.hide();
    _overlay = null;
    if (mounted) setState(() => _isSaving = false);
  }

  void _handleSaveImage() async {
    await ShareUtils.saveImage(
      _globalKey,
      onStart: _showOverlay,
      onComplete: _hideOverlay,
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
      onStart: _showOverlay,
      downloadLink: await createBranchLink(
        getLocaleTextFromJson(widget.vote.title, context),
        '${Environment.appLinkPrefix}/vote/detail/${widget.vote.id}',
      ),
      onComplete: _hideOverlay,
    );
  }

  /// 카드 탭 시 해당 투표 상세로 이동.
  void _openVote() {
    final vote = widget.vote;
    ref.read(navigationInfoProvider.notifier).setCurrentPage(
          vote.voteCategory == VoteCategory.achieve.name
              ? VoteDetailAchievePage(
                  voteId: vote.id,
                  votePortal: VotePortal.vote,
                )
              : VoteDetailPage(
                  voteId: vote.id,
                  votePortal: VotePortal.vote,
                ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final vote = widget.vote;
    final topItem =
        (vote.voteItem?.isNotEmpty ?? false) ? vote.voteItem!.first : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: RepaintBoundary(
        key: _globalKey,
        // 흰 배경을 캡처 경계(_globalKey) 안에 둬야 저장 이미지가 검게 안 나온다.
        child: ColoredBox(
          color: AppColors.grey00,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openVote,
                child: RepaintBoundary(
                  key: _shareKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // 제목 + 남은시간 (고정)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16, 16.w, 8),
                      child: Column(
                        children: [
                          Text(
                            getLocaleTextFromJson(vote.title, context),
                            style: getTextStyle(
                                AppTypo.title18B, AppColors.grey900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          // 저장 이미지에서는 타이머 제외(_isSaving 동안 숨김)
                          if (!_isSaving && vote.stopAt != null) ...[
                            const SizedBox(height: 8),
                            CountdownTimer(
                              endTime: vote.stopAt!,
                              status: VoteStatus.active,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 1위 큰 이미지 (남은 공간 채움)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 4, 16.w, 0),
                        child: topItem != null
                            ? _buildHeroItem(topItem)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isSaving)
              Transform.translate(
                offset: const Offset(0, -10),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ShareSection(
                    saveButtonText: AppLocalizations.of(context).save,
                    shareButtonText: AppLocalizations.of(context).share,
                    onSave: _handleSaveImage,
                    onShare: _handleShareToTwitter,
                  ),
                ),
              ),
            // 저장 시엔 ShareSection이 빠져 hero가 카드 밑단까지 커지며 이름/퍼센트가
            // 잘린다. 하단 여백을 줘서 캡처 이미지에서 잘리지 않게 한다.
            if (_isSaving) const SizedBox(height: 16),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroItem(VoteItemModel item) {
    final name = item.artist?.name != null
        ? getLocaleTextFromJson(item.artist!.name)
        : (item.artistGroup?.name != null
            ? getLocaleTextFromJson(item.artistGroup!.name)
            : '');
    final imageUrl = item.artist?.image ?? item.artistGroup?.image ?? '';
    final percentText = widget.percent > 0
        ? '${(widget.percent * 100).toStringAsFixed(1)}%'
        : '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PicnicCachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
          // 하단 그라디언트 (이름/퍼센트 가독성)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC1A1F2C)],
              ),
            ),
          ),
          // 1위 금메달 (좌상단) — 텍스트 대신 이미지로 표기
          Positioned(
            top: 10,
            left: 10,
            child: SvgPicture.asset(
              'assets/images/gold_medal.svg',
              package: 'picnic_lib',
              height: 44,
            ),
          ),
          // 이름 + 퍼센트 (하단)
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: getTextStyle(AppTypo.title18B, AppColors.grey00),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                if (percentText.isNotEmpty)
                  Text(
                    percentText,
                    style: getTextStyle(
                            AppTypo.title18B, AppColors.secondary500)
                        .copyWith(fontSize: 26.sp, height: 1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
