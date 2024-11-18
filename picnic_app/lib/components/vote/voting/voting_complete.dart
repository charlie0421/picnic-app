import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:animated_digit/animated_digit.dart';
import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/voting/gradient_circular_progress_indicator.dart';
import 'package:picnic_app/config/config_service.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/models/vote/artist_group.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
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

class _VotingCompleteDialogState extends ConsumerState<VotingCompleteDialog> {
  bool _isSaving = false;
  final GlobalKey _globalKey = GlobalKey();
  AppinioSocialShare appinioSocialShare = AppinioSocialShare();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  void _loadAds() async {
    final configService = ref.read(configServiceProvider);

    String? adUnitId = isIOS()
        ? await configService.getConfig('ADMOB_IOS_VOTE_COMPLETE')!
        : await configService.getConfig('ADMOB_ANDROID_VOTE_COMPLETE')!;

    _bannerAd = BannerAd(
      adUnitId: adUnitId!,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  Future<ui.Image?> _captureWidget(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      return image;
    } catch (e) {
      logger.e('Failed to capture widget: $e');
      return null;
    }
  }

  Future<void> _captureAndSaveImage() async {
    try {
      setState(() {
        _isSaving = true;
      });

      // 렌더링 대기
      await Future.delayed(const Duration(milliseconds: 500));

      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Failed to find render boundary');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image to bytes');

      final pngBytes = byteData.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/voting_dialog.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      final result = await ImageGallerySaverPlus.saveFile(path);
      logger.d('image saved: $path, result: $result');

      await file.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 300),
            content: Text(S.of(context).image_save_success),
          ),
        );
      }
    } catch (e) {
      logger.e('image saving fail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 300),
            content: Text(S.of(context).share_image_fail),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _captureAndShareImage() async {
    try {
      setState(() {
        _isSaving = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Failed to find render boundary');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image to bytes');

      final pngBytes = byteData.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/voting_dialog.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      final artist = widget.voteItemModel.artist.id != 0
          ? getLocaleTextFromJson(widget.voteItemModel.artist.name)
          : getLocaleTextFromJson(widget.voteItemModel.artistGroup.name);
      final voteTitle = getLocaleTextFromJson(widget.voteModel.title);

      final shareMessage = '''$artist - $voteTitle
${Intl.message('vote_share_message')} 🎉
#Picnic #Vote #${artist.replaceAll(' ', '')} #PicnicApp''';

      final result = Platform.isIOS
          ? await appinioSocialShare.iOS.shareToTwitter(shareMessage, path)
          : await appinioSocialShare.android.shareToTwitter(shareMessage, path);

      logger.d('image share result: $result');

      if (result == 'ERROR_APP_NOT_AVAILABLE') {
        showSimpleDialog(
          type: DialogType.error,
          content: Intl.message('share_no_twitter'),
        );
      } else if (result == 'SUCCESS') {
        final voteCount = widget.result['addedVoteTotal'];
        if (voteCount >= 100) {
          final userInfo = ref.read(userInfoProvider);
          await _awardBonus(userInfo.value?.id);
        }
      }

      await ref.read(userInfoProvider.notifier).getUserProfiles();

      await file.delete();
    } catch (e) {
      logger.e('image sharing fail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 300),
            content: Text(S.of(context).share_image_fail),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _awardBonus(String? userId) async {
    if (userId == null) return;

    try {
      logger.d('Awarding bonus candy for user: $userId');
      logger.d('voteId: ${widget.voteModel.id}');
      logger.d('votePickId: ${widget.result['votePickId']}');
      final response = await supabase.functions.invoke(
        'check-and-award-bonus',
        body: {
          'voteId': widget.voteModel.id,
          'userId': userId,
          'votePickId': widget.result['votePickId'], // vote_pick 테이블의 ID
        },
      );

      if (response.data['success']) {
        showSimpleDialog(
          content: Intl.message('bonus_candy_awarded'),
        );
      }
    } catch (e) {
      showSimpleDialog(
        type: DialogType.error,
        content: Intl.message('bonus_candy_fail'),
      );
      logger.e('Failed to award bonus: $e');
    }
  }

  Future<void> _saveDialogAsImage() async {
    if (_isSaving) return;

    try {
      setState(() {
        _isSaving = true;
      });

      await _captureAndSaveImage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 300),
            content: Text(S.of(context).image_save_success),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 300),
            content: Text(S.of(context).share_image_fail),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _shareDialogImage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _captureAndShareImage();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);

    return Material(
      color: AppColors.transparent,
      child: RepaintBoundary(
        key: _globalKey,
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.cw),
          backgroundColor: Colors.transparent,
          child: LargePopupWidget(
            backgroundColor: AppColors.mint500,
            content: Container(
              padding: EdgeInsets.only(
                  top: 24, left: 24.cw, right: 24.cw, bottom: 48),
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
                                  style: getTextStyle(AppTypo.caption12M,
                                      AppColors.primary500)),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: widget.voteItemModel.artist.id !=
                                            0
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
                  if (_isBannerLoaded && _bannerAd != null)
                    Stack(
                      children: [
                        // 실제 광고 (화면에 표시됨)
                        if (!_isSaving)
                          Container(
                            alignment: Alignment.center,
                            width: _bannerAd!.size.width.toDouble(),
                            height: _bannerAd!.size.height.toDouble(),
                            color: Colors.white,
                            child: AdWidget(ad: _bannerAd!),
                          ),
                        // 캡처용 플레이스홀더 (저장/공유 시에만 표시)
                        if (_isSaving)
                          Container(
                            alignment: Alignment.center,
                            width: _bannerAd!.size.width.toDouble(),
                            height: _bannerAd!.size.height.toDouble(),
                            color: Colors.white,
                            child: Image.asset(
                              'assets/images/vote/banner_complete_bottom_${Intl.getCurrentLocale() == "ko" ? 'ko' : 'en'}.jpg',
                              // 광고 영역 플레이스홀더 이미지
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    )
                  else
                    SizedBox(height: AdSize.largeBanner.height.toDouble()),
                  !_isSaving
                      ? Stack(
                          children: [
                            // 버튼들
                            Container(
                              padding: EdgeInsets.only(top: 16),
                              height: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed: _saveDialogAsImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary500,
                                      shadowColor: AppColors.primary500,
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size(104.cw, 32),
                                      maximumSize: Size(104.cw, 32),
                                    ),
                                    child: Text(
                                      S
                                          .of(context)
                                          .label_button_save_vote_paper,
                                      style: getTextStyle(
                                        AppTypo.body14B,
                                        AppColors.grey00,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(width: 16.cw),
                                  ElevatedButton(
                                    onPressed: _shareDialogImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary500,
                                      shadowColor: AppColors.primary500,
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size(104.cw, 32),
                                      maximumSize: Size(104.cw, 32),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          S.of(context).label_button_share,
                                          style: getTextStyle(
                                            AppTypo.body14B,
                                            AppColors.grey00,
                                          ),
                                        ),
                                        SizedBox(width: 4.cw),
                                        SvgPicture.asset(
                                          'assets/icons/twitter_style=fill.svg',
                                          width: 16.cw,
                                          height: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 버블 메시지
                            Positioned(
                              top: 56,
                              right: 16.cw,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 180.cw),
                                height: 56,
                                child: BubbleBox(
                                  shape: BubbleShapeBorder(
                                    border: BubbleBoxBorder(
                                      color: AppColors.primary500,
                                      width: 1.5,
                                      style: BubbleBoxBorderStyle.dashed,
                                    ),
                                    position: const BubblePosition.center(40),
                                    arrowHeight: 8,
                                    arrowAngle: 8,
                                    direction: BubbleDirection.top,
                                  ),
                                  backgroundColor: AppColors.grey00,
                                  child: Text(
                                    S.of(context).voting_share_benefit_text,
                                    style: getTextStyle(
                                      AppTypo.caption10SB,
                                      AppColors.primary500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
        getLocaleTextFromJson(artist.artist_group!.name),
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
            imageUrl: group.image!,
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

  @override
  void dispose() {
    _bannerAd?.dispose();
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
