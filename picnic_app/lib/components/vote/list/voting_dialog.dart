import 'package:animated_digit/animated_digit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/common/simple_dialog.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/list/voting_complete.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/store_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

Future showVotingDialog({
  required BuildContext context,
  required VoteModel voteModel,
  required VoteItemModel voteItemModel,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return VotingDialog(
        voteModel: voteModel,
        voteItemModel: voteItemModel,
      );
    },
  );
}

class VotingDialog extends ConsumerStatefulWidget {
  final VoteModel voteModel;
  final VoteItemModel voteItemModel;

  const VotingDialog({
    Key? key,
    required this.voteModel,
    required this.voteItemModel,
  }) : super(key: key);

  @override
  ConsumerState<VotingDialog> createState() => _VotingDialogState();
}

class _VotingDialogState extends ConsumerState<VotingDialog> {
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _checkAll = false;
  bool _hasValue = false;
  bool _isOver = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _checkOver(_textEditingController.text);
      }
    });
  }

  void _checkOver(String text) {
    String newText = text.replaceAll(',', '');
    final int voteAmount = int.parse(newText.isNotEmpty ? newText : '0');
    final int myStarCandy = ref.watch(userInfoProvider).value?.star_candy ?? 0;

    setState(() {
      _isOver = voteAmount > myStarCandy;
    });
    _hasValue = true;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int myStarCandy = ref.watch(
        userInfoProvider.select((value) => value.value?.star_candy ?? 0));
    final String user_id =
        ref.watch(userInfoProvider.select((value) => value.value?.id ?? ''));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.w),
      backgroundColor: Colors.transparent,
      child: LargePopupWidget(
        // title: widget.voteModel.getTitle() ?? '',
        closeButton: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.pop(context);
          },
          child: SvgPicture.asset(
            'assets/icons/cancle_style=line.svg',
            width: 24.w,
            height: 24.w,
            colorFilter:
                const ColorFilter.mode(AppColors.Grey00, BlendMode.srcIn),
          ),
        ),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: AppColors.Primary500,
                    width: 1.5.r,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100.r),
                  child: CachedNetworkImage(
                    imageUrl: widget.voteItemModel.mystar_member.image ?? '',
                    width: 100.w,
                    height: 100.w,
                    placeholder: (context, url) => buildPlaceholderImage(),
                  ),
                ),
              ),
              SizedBox(height: 12.w),
              SizedBox(
                height: 24.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.voteItemModel.mystar_member.getTitle() ?? '',
                      style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
                    ),
                    SizedBox(width: 8.w),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.voteItemModel.mystar_member.getGroupTitle(),
                        style:
                            getTextStyle(AppTypo.CAPTION12R, AppColors.Grey600),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: AppColors.Grey300,
                thickness: 1,
                height: 20.0.w,
              ),
              SizedBox(
                height: 32.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/header/star.png',
                      width: 24.w,
                      height: 24.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        height: 32.w,
                        alignment: Alignment.topLeft,
                        padding: EdgeInsets.only(bottom: 6.w),
                        child: AnimatedDigitWidget(
                          value: myStarCandy,
                          duration: const Duration(milliseconds: 500),
                          enableSeparator: true,
                          curve: Curves.easeInOut,
                          textStyle: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.Primary500,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ref
                            .read(navigationInfoProvider.notifier)
                            .setCurrentPage(const StorePage());
                        ref
                            .read(navigationInfoProvider.notifier)
                            .setVoteBottomNavigationIndex(3);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 32.w,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: AppColors.Mint500,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.Primary500,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              Intl.message('label_button_recharge'),
                              style: getTextStyle(
                                  AppTypo.BODY14B, AppColors.Primary500),
                            ),
                            SizedBox(width: 4.w),
                            SvgPicture.asset(
                              'assets/icons/plus_style=fill.svg',
                              width: 16.w,
                              height: 16.w,
                              colorFilter: const ColorFilter.mode(
                                  AppColors.Primary500, BlendMode.srcIn),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.w),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _checkAll = !_checkAll;
                    _hasValue = _checkAll;
                  });
                  _textEditingController.text = _checkAll || _hasValue
                      ? formatNumberWithComma(
                          ref
                                  .watch(userInfoProvider)
                                  .value
                                  ?.star_candy
                                  .toString() ??
                              '',
                        )
                      : '';
                },
                child: SizedBox(
                  height: 21.w,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/check_style=line.svg',
                        width: 20.w,
                        height: 20.w,
                        colorFilter: ColorFilter.mode(
                          _checkAll ? AppColors.Primary500 : AppColors.Grey300,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        Intl.message('label_checkbox_entire_use'),
                        style: getTextStyle(
                          AppTypo.BODY14M,
                          _checkAll ? AppColors.Primary500 : AppColors.Grey300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8.w),
              Container(
                height: 48.w,
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        _isOver ? AppColors.StatusError : AppColors.Primary500,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(24).r,
                ),
                padding: EdgeInsets.only(left: 24.w, right: 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        height: 48.w,
                        child: TextFormField(
                          cursorHeight: 16.w,
                          cursorColor: AppColors.Primary500,
                          focusNode: _focusNode,
                          controller: _textEditingController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: Intl.message('label_input_input'),
                            hintStyle: getTextStyle(
                                AppTypo.BODY16R, AppColors.Grey300),
                            border: InputBorder.none,
                            focusColor: AppColors.Primary500,
                            fillColor: AppColors.Grey900,
                            suffixIcon: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _textEditingController.clear();
                                setState(() {
                                  _hasValue = false;
                                  _checkAll = false;
                                });
                              },
                              child: SvgPicture.asset(
                                'assets/icons/cancle_style=fill.svg',
                                colorFilter: ColorFilter.mode(
                                  _hasValue
                                      ? AppColors.Grey700
                                      : AppColors.Grey200,
                                  BlendMode.srcIn,
                                ),
                                width: 20.w,
                                height: 20.w,
                              ),
                            ),
                            suffixIconConstraints: BoxConstraints(
                              minWidth: 20.w,
                              minHeight: 20.w,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                              final newText = newValue.text.replaceAll(',', '');

                              if (newValue.text.isEmpty) {
                                setState(() {
                                  _hasValue = false;
                                });
                                return newValue;
                              }

                              if (int.parse(newText) == 0) {
                                return oldValue;
                              }

                              setState(() {
                                _hasValue = true;
                              });
                              // 커서 위치를 항상 텍스트 끝에 맞춤
                              final text = newValue.text.replaceAll(',', '');
                              final textWithComma = formatNumberWithComma(text);

                              _checkOver(text);

                              return TextEditingValue(
                                text: textWithComma,
                                selection: TextSelection.collapsed(
                                    offset: textWithComma.length),
                              );
                            }),
                          ],
                          style:
                              getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (_isOver)
                      Container(
                        padding: EdgeInsets.only(left: 24.w, top: 4.w),
                        width: double.infinity,
                        height: 15.w,
                        child: Text(
                          Intl.message('text_need_recharge'),
                          style: getTextStyle(
                              AppTypo.CAPTION10SB, AppColors.StatusError),
                          textAlign: TextAlign.left,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isOver ||
                        myStarCandy <
                            int.parse(_textEditingController.text
                                        .replaceAll(',', '') ==
                                    ''
                                ? '0'
                                : _textEditingController.text
                                    .replaceAll(',', ''))
                    ? null
                    : () async {
                        OverlayLoadingProgress.start(context,
                            color: AppColors.Primary500,
                            barrierDismissible: false);

                        final voteAmount = int.parse(_textEditingController.text
                                    .replaceAll(',', '') ==
                                ''
                            ? '0'
                            : _textEditingController.text.replaceAll(',', ''));

                        if (voteAmount == 0) {
                          OverlayLoadingProgress.stop();
                          showSimpleDialog(
                            context: context,
                            title: Intl.message('dialog_title_vote_fail'),
                            content: Intl.message(
                                'text_dialog_vote_amount_should_not_zero'),
                            onOk: () {},
                          );
                          return;
                        }

                        if (myStarCandy < voteAmount) {
                          OverlayLoadingProgress.stop();
                          showSimpleDialog(
                            context: context,
                            title: Intl.message('dialog_title_vote_fail'),
                            content: Intl.message('text_need_recharge'),
                            onOk: () {},
                          );
                          return;
                        }

                        try {
                          final response = await Supabase
                              .instance.client.functions
                              .invoke('voting', body: {
                            'vote_id': widget.voteModel.id,
                            'vote_item_id': widget.voteItemModel.id,
                            'amount': voteAmount,
                            'user_id': user_id,
                          });

                          logger.i('투표 완료: ${response.data}');
                          logger.i(response.status);

                          ref.read(userInfoProvider.notifier).getUserProfiles();
                          ref
                              .read(asyncVoteItemListProvider(
                                      voteId: widget.voteModel.id)
                                  .notifier)
                              .fetch(voteId: widget.voteModel.id);

                          Navigator.pop(context);
                          showVotingCompleteDialog(
                            context: context,
                            voteModel: widget.voteModel,
                            voteItemModel: widget.voteItemModel,
                            result: response.data,
                          );

                          logger.i('투표 완료');
                        } catch (e, stackTrace) {
                          FunctionException exception = e as FunctionException;
                          logger.e('exception.message: ${exception.details}');
                          logger.e(
                              'exception.message: ${exception.reasonPhrase}');
                          logger.e('투표 실패: $e\n $stackTrace');
                          showSimpleDialog(
                            context: context,
                            title: Intl.message('dialog_title_vote_fail'),
                            onOk: () => Navigator.pop(context),
                          );
                        } finally {
                          OverlayLoadingProgress.stop();
                        }
                      },
                child: Container(
                  width: 172.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: _isOver ||
                            myStarCandy <
                                int.parse(_textEditingController.text
                                            .replaceAll(',', '') ==
                                        ''
                                    ? '0'
                                    : _textEditingController.text
                                        .replaceAll(',', ''))
                        ? AppColors.Grey300
                        : AppColors.Primary500,
                    borderRadius: BorderRadius.circular(24).r,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    Intl.message('label_button_vote'),
                    style: getTextStyle(
                        AppTypo.TITLE18SB,
                        _isOver ||
                                myStarCandy <
                                    int.parse(_textEditingController.text
                                                .replaceAll(',', '') ==
                                            ''
                                        ? '0'
                                        : _textEditingController.text
                                            .replaceAll(',', ''))
                            ? AppColors.Grey00
                            : AppColors.Grey300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatNumberWithComma(String number) {
  if (number.isEmpty) {
    return '';
  }
  final buffer = StringBuffer();
  final characters = number.split('');
  for (int i = 0; i < characters.length; i++) {
    if (i > 0 && (characters.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(characters[i]);
  }
  return buffer.toString();
}
