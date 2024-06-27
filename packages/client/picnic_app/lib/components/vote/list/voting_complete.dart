import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:animated_digit/animated_digit.dart';
import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

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

      final result = await ImageGallerySaver.saveFile(path);
      print('이미지 저장됨: $path, 결과: $result');
    } catch (e) {
      print('이미지 저장 실패: $e');
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
        logger.d('이미지 공유 결과: $result');
        if (result == 'ERROR_APP_NOT_AVAILABLE') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              duration: const Duration(milliseconds: 300),
              content: Text('트위터 앱이 없습니다.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              duration: const Duration(milliseconds: 300),
              content: Text(S.of(context).share_image_success)));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(milliseconds: 300),
          content: Text(S.of(context).share_image_fail)));
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
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        backgroundColor: Colors.transparent,
        child: LargePopupWidget(
          backgroundColor: AppColors.Mint500,
          closeButton: !_isSaving
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset(
                    'assets/icons/cancle_style=line.svg',
                    width: 24.w,
                    height: 24.w,
                    colorFilter: const ColorFilter.mode(
                        AppColors.Grey00, BlendMode.srcIn),
                  ),
                )
              : null,
          content: Container(
            padding: EdgeInsets.only(
                top: 24.w, left: 24.w, right: 24.w, bottom: 48.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 203.w,
                  height: 51.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.Grey00,
                    borderRadius: BorderRadius.circular(26.r),
                    border: Border.all(
                        color: AppColors.Primary500,
                        width: 2.5.r,
                        strokeAlign: BorderSide.strokeAlignInside),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    width: 195.w,
                    height: 43.w,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26.r),
                      border: Border.all(
                          color: AppColors.Mint500,
                          width: 2.5.r,
                          strokeAlign: BorderSide.strokeAlignInside),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          'assets/icons/header/star.png',
                          width: 24.w,
                          height: 24.w,
                        ),
                        Expanded(
                          child: Text(S.of(context).text_vote_complete,
                              style: getTextStyle(
                                  AppTypo.TITLE18B, AppColors.Point900),
                              textAlign: TextAlign.center),
                        ),
                        Image.asset(
                          'assets/icons/header/star.png',
                          width: 24.w,
                          height: 24.w,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.w),
                Container(
                    width: 291.w,
                    height: 70.w,
                    padding: EdgeInsets.only(left: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.Grey00,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.Primary500,
                        width: 1.5.r,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(48.r),
                          child: CachedNetworkImage(
                            imageUrl: userInfo.value?.avatar_url ?? '',
                            width: 48.w,
                            height: 48.w,
                            placeholder: (context, url) =>
                                buildPlaceholderImage(),
                            fit: BoxFit.cover,
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
                                  AppTypo.CAPTION12B, AppColors.Grey900),
                            ),
                            SizedBox(height: 2.w),
                            Text(
                              '${DateFormat('yyyy.MM.dd HH:mm').format(DateTime.tryParse(widget.result['updatedAt'])!.add(const Duration(hours: 9)))}(KST)',
                              style: getTextStyle(
                                  AppTypo.CAPTION12R, AppColors.Grey600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    )),
                SizedBox(height: 12.w),
                Container(
                  width: 291.w,
                  decoration: BoxDecoration(
                    color: AppColors.Grey00,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: AppColors.Primary500,
                      width: 1.5.r,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                            top: 16.w, bottom: 0.w, left: 24.w, right: 24.w),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(S.of(context).text_this_time_vote,
                                style: getTextStyle(
                                    AppTypo.CAPTION12M, AppColors.Primary500)),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                widget.voteModel.getTitle() ?? '',
                                style: getTextStyle(
                                  AppTypo.BODY14B,
                                  AppColors.Grey900,
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
                        color: AppColors.Grey300,
                        indent: 13.w,
                        endIndent: 13.w,
                        thickness: 1,
                        height: 1.w,
                      ),
                      SizedBox(height: 12.w),
                      Container(
                        padding: EdgeInsets.only(right: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                width: 120.w,
                                height: 140.w,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(64.r),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.voteItemModel
                                                .mystar_member.image ??
                                            '',
                                        width: 56.w,
                                        height: 56.w,
                                      ),
                                    ),
                                    SizedBox(height: 8.w),
                                    Text(
                                      widget.voteItemModel.mystar_member
                                              .getTitle() ??
                                          '',
                                      style: getTextStyle(
                                          AppTypo.BODY16B, AppColors.Grey900),
                                    ),
                                    SizedBox(height: 5.w),
                                    Text(
                                      widget.voteItemModel.mystar_member
                                          .getGroupTitle(),
                                      style: getTextStyle(AppTypo.CAPTION12R,
                                          AppColors.Grey600),
                                    ),
                                    SizedBox(height: 4.5.w),
                                    AnimatedDigitWidget(
                                        value:
                                            widget.result['updatedVoteTotal'],
                                        enableSeparator: true,
                                        duration: _duration,
                                        textStyle: getTextStyle(
                                            AppTypo.CAPTION12B,
                                            AppColors.Primary500)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              flex: 1,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 120.w,
                                    height: 120.w,
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
                                              AppTypo.CAPTION12B,
                                              AppColors.Grey400)),
                                      AnimatedDigitWidget(
                                          value:
                                              widget.result['addedVoteTotal'],
                                          enableSeparator: true,
                                          prefix: '+',
                                          duration: _duration,
                                          textStyle: getTextStyle(
                                              AppTypo.BODY14B,
                                              AppColors.Primary500)),
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
                SizedBox(height: 16.w),
                !_isSaving
                    ? SizedBox(
                        height: 32.w,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: _saveDialogAsImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.Primary500,
                                  shadowColor: AppColors.Primary500,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(104.w, 32.w),
                                  maximumSize: Size(104.w, 32.w),
                                ),
                                child: Text(
                                    S.of(context).label_button_save_vote_paper,
                                    style: getTextStyle(
                                        AppTypo.BODY14B, AppColors.Grey00))),
                            SizedBox(width: 16.w),
                            ElevatedButton(
                                onPressed: _shareDialogImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.Primary500,
                                  shadowColor: AppColors.Primary500,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(104.w, 32.w),
                                  maximumSize: Size(104.w, 32.w),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(S.of(context).label_button_share,
                                        style: getTextStyle(
                                            AppTypo.BODY14B, AppColors.Grey00)),
                                    SizedBox(width: 4.w),
                                    SvgPicture.asset(
                                      'assets/icons/twitter_style=fill.svg',
                                      width: 16.w,
                                      height: 16.w,
                                    ),
                                  ],
                                )),
                          ],
                        ),
                      )
                    : Image.asset(
                        'assets/images/logo.png',
                        width: 75.w,
                        height: 57.w,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GradientCircularProgressIndicator extends StatefulWidget {
  final double value;
  final double strokeWidth;
  final List<Color> gradientColors;

  const GradientCircularProgressIndicator({
    super.key,
    required this.value,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  _GradientCircularProgressIndicatorState createState() =>
      _GradientCircularProgressIndicatorState();
}

class _GradientCircularProgressIndicatorState
    extends State<GradientCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    )..forward(); // 진행 후 멈춤

    _animation =
        Tween<double>(begin: 0, end: widget.value).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientCircularProgressPainter(
            value: _animation.value,
            strokeWidth: widget.strokeWidth,
            gradientColors: widget.gradientColors,
          ),
          child: const SizedBox(
            width: 100,
            height: 100,
          ),
        );
      },
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final List<Color> gradientColors;

  _GradientCircularProgressPainter({
    required this.value,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      colors: gradientColors,
      stops: const [0.0, 0.75],
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint endPaint = Paint()
      ..color = gradientColors.last
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double radius = (size.width - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double startAngle = -3.14159 / 2;
    final double sweepAngle = 2 * 3.14159 * value;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (value <= 0.75) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * 3.14159 * 0.75,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + 2 * 3.14159 * 0.75,
        sweepAngle - 2 * 3.14159 * 0.75,
        false,
        endPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
