import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/ui/style.dart';

Future showVotingCompleteDialog({
  required BuildContext context,
  required VoteModel voteModel,
  required VoteItemModel voteItemModel,
  required Map<String, dynamic> result,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
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

    return RepaintBoundary(
      key: _globalKey,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        backgroundColor: Colors.transparent,
        child: LargePopupWidget(
          showCloseButton: false,
          backgroundColor: AppColors.secondary500,
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 203.w,
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
                    width: 195.w,
                    height: 43,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26.r),
                      border: Border.all(
                          color: AppColors.secondary500,
                          width: 2.5.r,
                          strokeAlign: BorderSide.strokeAlignInside),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          package: 'picnic_lib',
                          'assets/icons/header/star.png',
                          width: 24.w,
                          height: 24,
                        ),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).text_vote_complete,
                            style: getTextStyle(
                              AppTypo.title18B,
                              AppColors.point900,
                            ).copyWith(height: 1),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Image.asset(
                          package: 'picnic_lib',
                          'assets/icons/header/star.png',
                          width: 24.w,
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                    width: 291.w,
                    height: 70,
                    padding: EdgeInsets.only(left: 12.w),
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
                        SizedBox(width: 16.w),
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
                              () {
                                try {
                                  final updatedAtStr =
                                      widget.result['updatedAt'] as String?;
                                  if (updatedAtStr == null) {
                                    return '${DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now().add(const Duration(hours: 9)))}(KST)';
                                  }
                                  final parsedDate =
                                      DateTime.tryParse(updatedAtStr);
                                  if (parsedDate == null) {
                                    return '${DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now().add(const Duration(hours: 9)))}(KST)';
                                  }
                                  return '${DateFormat('yyyy.MM.dd HH:mm').format(parsedDate.add(const Duration(hours: 9)))}(KST)';
                                } catch (e) {
                                  logger.w(
                                      'Failed to parse updatedAt: ${widget.result['updatedAt']}, error: $e');
                                  return '${DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now().add(const Duration(hours: 9)))}(KST)';
                                }
                              }(),
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
                  width: 291.w,
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
                            top: 8, bottom: 8, left: 24.w, right: 24.w),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Text(
                                getLocaleTextFromJson(widget.voteModel.title),
                                style: getTextStyle(
                                  AppTypo.caption12B,
                                  AppColors.grey900,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: AppColors.grey300,
                        indent: 13.w,
                        endIndent: 13.w,
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.only(right: 16.w),
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
                                  children: () {
                                    if ((widget.voteItemModel.artist?.id ??
                                                0) !=
                                            0 &&
                                        widget.voteItemModel.artist != null) {
                                      return _artist(
                                          widget.voteItemModel.artist!);
                                    } else if (widget
                                            .voteItemModel.artistGroup !=
                                        null) {
                                      return _group(
                                          widget.voteItemModel.artistGroup!);
                                    } else {
                                      // fallback: 기본 위젯 반환
                                      return [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.grey200,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: 30,
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Unknown Artist',
                                          style: getTextStyle(AppTypo.body16B,
                                              AppColors.grey900),
                                          textAlign: TextAlign.center,
                                        ),
                                      ];
                                    }
                                  }(),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    NumberFormat.decimalPattern().format(
                                        widget.result['existingVoteTotal']),
                                    style: getTextStyle(
                                        AppTypo.caption12B, AppColors.grey400),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '+${NumberFormat.decimalPattern().format(widget.result['addedVoteTotal'])}',
                                    style: getTextStyle(
                                        AppTypo.body14B, AppColors.primary500),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    NumberFormat.decimalPattern().format(
                                        widget.result['updatedVoteTotal']),
                                    style: getTextStyle(
                                        AppTypo.title18B, AppColors.primary500),
                                  ),
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
                if (!_isSaving)
                  ShareSection(
                    saveButtonText: AppLocalizations.of(context).save,
                    shareButtonText: AppLocalizations.of(context).share,
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
                    onShare: () async {
                      if (_isSaving) return;
                      final artist = (widget.voteItemModel.artist?.id ?? 0) != 0
                          ? getLocaleTextFromJson(
                              widget.voteItemModel.artist?.name ?? {})
                          : getLocaleTextFromJson(
                              widget.voteItemModel.artistGroup?.name ?? {});
                      final voteTitle =
                          getLocaleTextFromJson(widget.voteModel.title);

                      logger.i(
                          'Environment.appLinkPrefix: ${Environment.appLinkPrefix}');
                      if (navigatorKey.currentContext != null) {
                        ShareUtils.shareToSocial(
                          _globalKey,
                          message:
                              '$artist - $voteTitle ${AppLocalizations.of(navigatorKey.currentContext!).vote_share_message} 🎉',
                          hashtag:
                              '#Picnic #Vote #PicnicApp #${voteTitle.replaceAll(' ', '')}',
                          downloadLink: await createBranchLink(
                              getLocaleTextFromJson(widget.voteModel.title),
                              '${Environment.appLinkPrefix}/vote/detail/${widget.voteModel.id}'),
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
                      }
                    },
                  ),
                SizedBox(height: 4),
                Image.asset(
                  'assets/app_icon_128.png',
                  width: 50,
                ),
              ],
            ),
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
      // artistGroup이 null인 경우를 안전하게 처리
      if (artist.artistGroup?.name != null)
        Text(
          getLocaleTextFromJson(artist.artistGroup!.name),
          style: getTextStyle(AppTypo.caption12R, AppColors.grey600)
              .copyWith(height: .8),
          textAlign: TextAlign.center,
        ),
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
