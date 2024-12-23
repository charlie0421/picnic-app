import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/common/ads/banner_ad_widget.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/common/share_section.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/voting/gradient_circular_progress_indicator.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/models/vote/artist_group.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/vote_share_util.dart';

const Duration _duration = Duration(milliseconds: 1000);

Future showVotingCompleteDialog({
  required BuildContext context,
  required VoteModel voteModel,
  required VoteItemModel voteItemModel,
  required Map<String, dynamic> result,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return VotingCompleteDialog(
        voteModel: voteModel,
        voteItemModel: voteItemModel,
        result: result,
      );
    },
  );
}

class VotingCompleteDialog extends ConsumerStatefulWidget {
  final VoteModel voteModel;
  final VoteItemModel voteItemModel;
  final Map<String, dynamic> result;

  const VotingCompleteDialog({
    super.key,
    required this.voteModel,
    required this.voteItemModel,
    required this.result,
  });

  @override
  ConsumerState<VotingCompleteDialog> createState() =>
      _VotingCompleteDialogState();
}

class _VotingCompleteDialogState extends ConsumerState<VotingCompleteDialog> {
  bool _isSaving = false;
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);

    return Material(
      color: AppColors.transparent,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.cw),
        backgroundColor: Colors.transparent,
        child: LargePopupWidget(
          backgroundColor: AppColors.mint500,
          content: Column(
            children: [
              Container(
                width: 203.cw,
                height: 51,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.grey00,
                  borderRadius: BorderRadius.circular(26.r),
                  border: Border.all(
                      color: AppColors.primary500,
                      width: 2.5.r,
                      strokeAlign: BorderSide.strokeAlignInside),
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: 195.cw,
                  height: 43,
                  padding: EdgeInsets.symmetric(horizontal: 24.cw),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26.r),
                    border: Border.all(
                        color: AppColors.mint500,
                        width: 2.5.r,
                        strokeAlign: BorderSide.strokeAlignInside),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/icons/header/star.png',
                        width: 24.cw,
                        height: 24,
                      ),
                      Expanded(
                        child: Text(S.of(context).text_vote_complete,
                            style: getTextStyle(
                                    AppTypo.title18B, AppColors.point900)
                                .copyWith(height: 1),
                            textAlign: TextAlign.center),
                      ),
                      Image.asset(
                        'assets/icons/header/star.png',
                        width: 24.cw,
                        height: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                  width: 291.cw,
                  height: 70,
                  padding: EdgeInsets.only(left: 12.cw),
                  decoration: BoxDecoration(
                    color: AppColors.grey00,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.primary500,
                      width: 1.5.r,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(48.r),
                        child: ProfileImageContainer(
                          avatarUrl: userInfo.value?.avatarUrl,
                          width: 48,
                          height: 48,
                          borderRadius: 48,
                        ),
                      ),
                      SizedBox(width: 16.cw),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userInfo.value?.nickname ?? '',
                            style: getTextStyle(
                                AppTypo.caption12B, AppColors.grey900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('yyyy.MM.dd HH:mm').format(DateTime.tryParse(widget.result['updatedAt'])!.add(const Duration(hours: 9)))}(KST)',
                            style: getTextStyle(
                                AppTypo.caption12R, AppColors.grey600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  )),
              const SizedBox(height: 8),
              Container(
                width: 291.cw,
                decoration: BoxDecoration(
                  color: AppColors.grey00,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.primary500,
                    width: 1.5.r,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                          top: 2, bottom: 2, left: 24.cw, right: 24.cw),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(S.of(context).text_this_time_vote,
                              style: getTextStyle(
                                  AppTypo.caption12M, AppColors.primary500)),
                          Text(
                            getLocaleTextFromJson(widget.voteModel.title),
                            style: getTextStyle(
                              AppTypo.caption12B,
                              AppColors.grey900,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: AppColors.grey300,
                      indent: 13.cw,
                      endIndent: 13.cw,
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.only(right: 16.cw),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: widget.voteItemModel.artist.id != 0
                                    ? _artist(widget.voteItemModel.artist)
                                    : _group(widget.voteItemModel.artistGroup),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: GradientCircularProgressIndicator(
                                    value: widget.result['addedVoteTotal'] /
                                        widget.result['updatedVoteTotal'],
                                    strokeWidth: 20,
                                    gradientColors: const [
                                      Color(0xFF9374FF),
                                      Color(0xFF83FBC8),
                                    ],
                                  ),
                                ),
                                Positioned(
                                    child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedDigitWidget(
                                        value:
                                            widget.result['existingVoteTotal'],
                                        enableSeparator: true,
                                        duration: _duration,
                                        textStyle: getTextStyle(
                                            AppTypo.caption12B,
                                            AppColors.grey400)),
                                    AnimatedDigitWidget(
                                        value: widget.result['addedVoteTotal'],
                                        enableSeparator: true,
                                        prefix: '+',
                                        duration: _duration,
                                        textStyle: getTextStyle(AppTypo.body14B,
                                            AppColors.primary500)),
                                  ],
                                ))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              BannerAdWidget(
                configKey: 'VOTE_COMPLETE',
                adSize: AdSize.largeBanner,
              ),
              if (!_isSaving)
                ShareSection(
                  saveButtonText: S.of(context).save,
                  shareButtonText: S.of(context).share,
                  onSave: () {
                    if (_isSaving) return;
                    ShareUtils.saveImage(
                      _globalKey,
                      onStart: () {
                        OverlayLoadingProgress.start(context,
                            color: AppColors.primary500);
                        setState(() => _isSaving = true);
                      },
                      onComplete: () {
                        OverlayLoadingProgress.stop();
                        setState(() => _isSaving = false);
                      },
                    );
                  },
                  onShare: () {
                    if (_isSaving) return;
                    final artist = widget.voteItemModel.artist.id != 0
                        ? getLocaleTextFromJson(
                            widget.voteItemModel.artist.name)
                        : getLocaleTextFromJson(
                            widget.voteItemModel.artistGroup.name);
                    final voteTitle =
                        getLocaleTextFromJson(widget.voteModel.title);

                    ShareUtils.shareToSocial(
                      _globalKey,
                      message:
                          '$artist - $voteTitle ${Intl.message('vote_share_message')} 🎉',
                      hashtag:
                          '#Picnic #Vote #PicnicApp #${voteTitle.replaceAll(' ', '')}',
                      onStart: () {
                        OverlayLoadingProgress.start(context,
                            color: AppColors.primary500);
                        setState(() => _isSaving = true);
                      },
                      onComplete: () {
                        OverlayLoadingProgress.stop();
                        setState(() => _isSaving = false);
                      },
                    );
                  },
                ),
              SizedBox(height: 4),
              Image.asset(
                'assets/images/logo.png',
                width: 50,
              ),
            ],
          ),
          closeButton: _isSaving ? Container() : null,
        ),
      ),
    );
  }

  List<Widget> _artist(ArtistModel artist) {
    return [
      SizedBox(
        width: 60,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60.r),
          child: PicnicCachedNetworkImage(
            imageUrl: artist.image ?? '',
            width: 60,
            height: 60,
          ),
        ),
      ),
      Text(
        getLocaleTextFromJson(artist.name),
        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        textAlign: TextAlign.center,
      ),
      Text(
        getLocaleTextFromJson(artist.artist_group!.name),
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600)
            .copyWith(height: .8),
        textAlign: TextAlign.center,
      ),
      AnimatedDigitWidget(
          value: widget.result['updatedVoteTotal'],
          enableSeparator: true,
          duration: _duration,
          textStyle: getTextStyle(AppTypo.caption12B, AppColors.primary500)),
    ];
  }

  List<Widget> _group(ArtistGroupModel group) {
    return [
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(120),
          border: Border.all(color: AppColors.primary500, width: 1.5.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60.r),
          child: PicnicCachedNetworkImage(
            imageUrl: group.image!,
            width: 60,
            height: 60,
          ),
        ),
      ),
      Text(
        getLocaleTextFromJson(group.name),
        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        textAlign: TextAlign.center,
      ),
      Text(
        getLocaleTextFromJson(group.name),
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600)
            .copyWith(height: .8),
        textAlign: TextAlign.center,
      ),
      AnimatedDigitWidget(
          value: widget.result['updatedVoteTotal'],
          enableSeparator: true,
          duration: _duration,
          textStyle: getTextStyle(AppTypo.caption12B, AppColors.primary500)),
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
