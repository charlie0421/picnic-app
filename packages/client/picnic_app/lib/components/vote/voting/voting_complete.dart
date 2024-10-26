import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:animated_digit/animated_digit.dart';
import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/voting/gradient_circular_progress_indicator.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/models/vote/artist_group.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

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

class _VotingCompleteDialogState extends ConsumerState<VotingCompleteDialog>
    with SingleTickerProviderStateMixin {
  bool _isSaving = false;
  final GlobalKey _globalKey = GlobalKey();
  AppinioSocialShare appinioSocialShare = AppinioSocialShare();

  Future<void> _captureAndSaveImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = (await getApplicationDocumentsDirectory()).path;
      String path = '$directory/voting_dialog.png';
      File imgFile = File(path);
      imgFile.writeAsBytesSync(pngBytes);

      final result = await ImageGallerySaverPlus.saveFile(path);
      logger.d('image saved: $path, result: $result');
    } catch (e, s) {
      logger.e('image saving fail: $e', stackTrace: s);
      rethrow;
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveDialogAsImage() async {
    setState(() {
      _isSaving = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _captureAndSaveImage().then((value) {
        _isSaving = false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 300),
            content: Text(S.of(context).image_save_success)));
      });
    });
  }

  Future<void> _captureAndShareImage() async {
    try {
      setState(() {
        _isSaving = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () async {
        RenderRepaintBoundary boundary = _globalKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        var image = await boundary.toImage();
        ByteData? byteData =
            await image.toByteData(format: ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final directory = (await getApplicationDocumentsDirectory()).path;
        String path = '$directory/voting_dialog.png';
        File imgFile = File(path);
        imgFile.writeAsBytesSync(pngBytes);

        final result = Platform.isIOS
            ? await appinioSocialShare.iOS
                .shareToTwitter(S.of(context).share_twitter, path)
            : await appinioSocialShare.android
                .shareToTwitter(S.of(context).share_twitter, path);
        logger.d('image share result: $result');
        if (result == 'ERROR_APP_NOT_AVAILABLE') {
          showSimpleDialog(
            content: S.of(context).share_no_twitter,
          );
        }
      });
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(milliseconds: 300),
          content: Text(S.of(context).share_image_fail)));
      rethrow;
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _shareDialogImage() async {
    setState(() {
      _isSaving = true;
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _captureAndShareImage());
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);

    return RepaintBoundary(
      key: _globalKey,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.cw),
        backgroundColor: Colors.transparent,
        child: LargePopupWidget(
          backgroundColor: AppColors.mint500,
          content: Container(
            padding:
                EdgeInsets.only(top: 24, left: 24.cw, right: 24.cw, bottom: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                            top: 16.cw,
                            bottom: 0.cw,
                            left: 24.cw,
                            right: 24.cw),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(S.of(context).text_this_time_vote,
                                style: getTextStyle(
                                    AppTypo.caption12M, AppColors.primary500)),
                            SizedBox(width: 16.cw),
                            Expanded(
                              child: Text(
                                getLocaleTextFromJson(widget.voteModel.title),
                                style: getTextStyle(
                                  AppTypo.body14B,
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
                        indent: 13.cw,
                        endIndent: 13.cw,
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 12),
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
                                height: 140,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: widget.voteItemModel.artist.id != 0
                                      ? _artist(widget.voteItemModel.artist)
                                      : _group(
                                          widget.voteItemModel.artistGroup),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.cw),
                            Expanded(
                              flex: 1,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 120.cw,
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
                                          value: widget
                                              .result['existingVoteTotal'],
                                          enableSeparator: true,
                                          duration: _duration,
                                          textStyle: getTextStyle(
                                              AppTypo.caption12B,
                                              AppColors.grey400)),
                                      AnimatedDigitWidget(
                                          value:
                                              widget.result['addedVoteTotal'],
                                          enableSeparator: true,
                                          prefix: '+',
                                          duration: _duration,
                                          textStyle: getTextStyle(
                                              AppTypo.body14B,
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
                const SizedBox(height: 16),
                !_isSaving
                    ? SizedBox(
                        height: 32,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: _saveDialogAsImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary500,
                                  shadowColor: AppColors.primary500,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(104.cw, 32.cw),
                                  maximumSize: Size(104.cw, 32.cw),
                                ),
                                child: Text(
                                    S.of(context).label_button_save_vote_paper,
                                    style: getTextStyle(
                                        AppTypo.body14B, AppColors.grey00),
                                    textAlign: TextAlign.center)),
                            SizedBox(width: 16.cw),
                            ElevatedButton(
                                onPressed: _shareDialogImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary500,
                                  shadowColor: AppColors.primary500,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(104.cw, 32.cw),
                                  maximumSize: Size(104.cw, 32.cw),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(S.of(context).label_button_share,
                                        style: getTextStyle(
                                            AppTypo.body14B, AppColors.grey00)),
                                    SizedBox(width: 4.cw),
                                    SvgPicture.asset(
                                      'assets/icons/twitter_style=fill.svg',
                                      width: 16.cw,
                                      height: 16,
                                    ),
                                  ],
                                )),
                          ],
                        ),
                      )
                    : Image.asset(
                        'assets/images/logo.png',
                        width: 75.cw,
                        height: 57,
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
      const SizedBox(height: 8),
      Text(
        getLocaleTextFromJson(artist.name),
        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(
        getLocaleTextFromJson(artist.artist_group.name),
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600)
            .copyWith(height: .8),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 3),
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
            imageUrl: group.image,
            width: 60,
            height: 60,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        getLocaleTextFromJson(group.name),
        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(
        getLocaleTextFromJson(group.name),
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600)
            .copyWith(height: .8),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 3),
      AnimatedDigitWidget(
          value: widget.result['updatedVoteTotal'],
          enableSeparator: true,
          duration: _duration,
          textStyle: getTextStyle(AppTypo.caption12B, AppColors.primary500)),
    ];
  }
}
