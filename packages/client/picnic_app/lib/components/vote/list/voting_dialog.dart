import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/list/voting_complete.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/store_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
    super.key,
    required this.voteModel,
    required this.voteItemModel,
  });

  @override
  ConsumerState<VotingDialog> createState() => _VotingDialogState();
}

class _VotingDialogState extends ConsumerState<VotingDialog> {
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _checkAll = false;
  bool _hasValue = false;
  bool _canVote = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    _focusNode.addListener(_validateVote);
  }

  void _validateVote() {
    final voteAmount = _getVoteAmount();
    final myStarCandy = _getMyStarCandy();
    setState(() {
      _canVote = voteAmount > 0 && voteAmount <= myStarCandy;
      _hasValue = voteAmount > 0;
    });
  }

  int _getVoteAmount() =>
      int.tryParse(_textEditingController.text.replaceAll(',', '')) ?? 0;

  int _getMyStarCandy() {
    final userInfo = ref.read(userInfoProvider).value;
    return (userInfo?.star_candy ?? 0) + (userInfo?.star_candy_bonus ?? 0);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myStarCandy = _getMyStarCandy();
    final userId =
        ref.watch(userInfoProvider.select((value) => value.value?.id ?? ''));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.w),
      backgroundColor: Colors.transparent,
      child: LargePopupWidget(
        content: Container(
          padding:
              const EdgeInsets.only(top: 32, bottom: 24, left: 24, right: 24).r,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 8.h),
              _buildMemberInfo(),
              _buildStarCandyInfo(myStarCandy),
              SizedBox(height: 8.h),
              _buildCheckAllOption(),
              SizedBox(height: 8.h),
              _buildVoteAmountInput(),
              _buildErrorMessage(),
              SizedBox(height: 9.h),
              _buildVoteButton(myStarCandy, userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberInfo() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(120),
            border: Border.all(color: AppColors.Primary500, width: 1.5.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(120),
            child: PicnicCachedNetworkImage(
              imageUrl: widget.voteItemModel.artist.image ?? '',
              width: 100,
              height: 100,
              useScreenUtil: false,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 24.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getLocaleTextFromJson(widget.voteItemModel.artist.name),
                style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
              ),
              SizedBox(width: 8.w),
              Align(
                alignment: Alignment.center,
                child: Text(
                  getLocaleTextFromJson(
                      widget.voteItemModel.artist.artist_group.name),
                  style: getTextStyle(AppTypo.CAPTION12R, AppColors.Grey600),
                ),
              ),
            ],
          ),
        ),
        Divider(color: AppColors.Grey300, thickness: 1, height: 20.0.h),
      ],
    );
  }

  Widget _buildStarCandyInfo(int myStarCandy) {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/icons/store/star_100.png',
                width: 32.w, height: 32.w),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Container(
              height: 26.h,
              alignment: Alignment.topLeft,
              child: AnimatedDigitWidget(
                autoSize: false,
                animateAutoSize: false,
                value: myStarCandy,
                duration: const Duration(milliseconds: 500),
                enableSeparator: true,
                curve: Curves.easeInOut,
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.Primary500,
                ),
              ),
            ),
          ),
          _buildRechargeButton(),
        ],
      ),
    );
  }

  Widget _buildRechargeButton() {
    return GestureDetector(
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
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.Mint500,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.Primary500, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context).label_button_recharge,
              style: getTextStyle(AppTypo.BODY14B, AppColors.Primary500),
            ),
            SizedBox(width: 4.w),
            SvgPicture.asset(
              'assets/icons/plus_style=fill.svg',
              width: 16.w,
              height: 16.w,
              colorFilter:
                  const ColorFilter.mode(AppColors.Primary500, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckAllOption() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _checkAll = !_checkAll;
          _hasValue = _checkAll;
          if (_checkAll) {
            _textEditingController.text =
                formatNumberWithComma(_getMyStarCandy().toString());
          } else {
            _textEditingController.clear();
          }
        });
        _validateVote();
      },
      child: SizedBox(
        height: 20.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              S.of(context).label_checkbox_entire_use,
              style: getTextStyle(
                AppTypo.BODY14M,
                _checkAll ? AppColors.Primary500 : AppColors.Grey300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteAmountInput() {
    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: !_canVote && _hasValue
              ? AppColors.StatusError
              : AppColors.Primary500,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(24).r,
      ),
      padding: EdgeInsets.only(right: 16.w),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              cursorHeight: 16.h,
              cursorColor: AppColors.Primary500,
              focusNode: _focusNode,
              controller: _textEditingController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.left, // 왼쪽 정렬
              decoration: InputDecoration(
                hintText: S.of(context).label_input_input,
                hintStyle: getTextStyle(AppTypo.BODY16R, AppColors.Grey300),
                border: InputBorder.none,
                focusColor: AppColors.Primary500,
                fillColor: AppColors.Grey900,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 24.w, vertical: 5.h), // 수직 패딩 조정
              ),
              onChanged: (_) => _validateVote(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  String newText = newValue.text.replaceAll(',', '');

                  // Remove leading zeros
                  newText = newText.replaceFirst(RegExp(r'^0+'), '');

                  if (newText.isEmpty) {
                    setState(() {
                      _hasValue = false;
                      _checkAll = false;
                    });
                    return const TextEditingValue(text: '');
                  }

                  final voteAmount = int.parse(newText);
                  if (voteAmount == 0) return oldValue;

                  setState(() {
                    _hasValue = true;
                    _checkAll = false;
                  });

                  final formattedText = formatNumberWithComma(newText);
                  return TextEditingValue(
                    text: formattedText,
                    selection:
                        TextSelection.collapsed(offset: formattedText.length),
                  );
                }),
              ],
              style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
            ),
          ),
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _textEditingController.clear();
        setState(() {
          _hasValue = false;
          _checkAll = false;
        });
        _validateVote();
      },
      child: SvgPicture.asset(
        'assets/icons/cancle_style=fill.svg',
        colorFilter: ColorFilter.mode(
          _hasValue ? AppColors.Grey700 : AppColors.Grey200,
          BlendMode.srcIn,
        ),
        width: 20.w,
        height: 20.w,
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (!_canVote && _hasValue) {
      return Container(
        padding: EdgeInsets.only(left: 24.w, top: 4.w),
        width: double.infinity,
        height: 15.w,
        child: Text(
          S.of(context).text_need_recharge,
          style: getTextStyle(AppTypo.CAPTION10SB, AppColors.StatusError),
          textAlign: TextAlign.left,
        ),
      );
    }
    return SizedBox(height: 15.w);
  }

  Widget _buildVoteButton(int myStarCandy, String userId) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canVote ? () => _handleVote(myStarCandy, userId) : null,
      child: Container(
        width: 172.w,
        height: 52.w,
        decoration: BoxDecoration(
          color: _canVote ? AppColors.Primary500 : AppColors.Grey300,
          borderRadius: BorderRadius.circular(24).r,
        ),
        alignment: Alignment.center,
        child: Text(
          S.of(context).label_button_vote,
          style: getTextStyle(
            AppTypo.TITLE18SB,
            AppColors.Grey00,
          ),
        ),
      ),
    );
  }

  void _handleVote(int myStarCandy, String userId) {
    final voteAmount = _getVoteAmount();
    if (voteAmount == 0 || myStarCandy < voteAmount) {
      showSimpleDialog(
        context: context,
        title: S.of(context).dialog_title_vote_fail,
        content: voteAmount == 0
            ? S.of(context).text_dialog_vote_amount_should_not_zero
            : S.of(context).text_need_recharge,
        onOk: () {},
      );
      return;
    }

    FocusScope.of(context).unfocus();

    OverlayLoadingProgress.start(context,
        color: AppColors.Primary500, barrierDismissible: false);

    _performVoting(voteAmount, userId);
  }

  Future<void> _performVoting(int voteAmount, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final response = await supabase.functions.invoke('voting', body: {
        'vote_id': widget.voteModel.id,
        'vote_item_id': widget.voteItemModel.id,
        'amount': voteAmount,
        'user_id': userId,
      });

      ref.read(userInfoProvider.notifier).getUserProfiles();
      ref
          .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
          .fetch(voteId: widget.voteModel.id);

      OverlayLoadingProgress.stop();

      if (!mounted) return;

      Navigator.of(context).pop();

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      _showVotingCompleteDialog(response.data);

      logger.i('투표 완료: ${response.data}');
      logger.i(response.status);
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      OverlayLoadingProgress.stop();

      if (!mounted) return;

      _showVotingFailDialog();
    }
  }

  void _showVotingCompleteDialog(dynamic result) {
    showVotingCompleteDialog(
      context: context,
      voteModel: widget.voteModel,
      voteItemModel: widget.voteItemModel,
      result: result,
    );
  }

  void _showVotingFailDialog() {
    showSimpleDialog(
      context: context,
      content: S.of(context).dialog_title_vote_fail,
      onOk: () => Navigator.of(context).pop(),
    );
  }
}

String formatNumberWithComma(String number) {
  if (number.isEmpty) return '';
  final parts = number.split('.');
  parts[0] = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return parts.join('.');
}
