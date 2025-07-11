import 'dart:async';

import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

Future showVotingDialog({
  required BuildContext context,
  required VoteModel voteModel,
  required VoteItemModel voteItemModel,
  VotePortal portalType = VotePortal.vote,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return VotingDialog(
        voteModel: voteModel,
        voteItemModel: voteItemModel,
        portalType: portalType,
      );
    },
  );
}

class VotingDialog extends ConsumerStatefulWidget {
  final VoteModel voteModel;
  final VoteItemModel voteItemModel;
  final VotePortal portalType;

  const VotingDialog({
    super.key,
    required this.voteModel,
    required this.voteItemModel,
    required this.portalType,
  });

  @override
  ConsumerState<VotingDialog> createState() => _VotingDialogState();
}

class _VotingDialogState extends ConsumerState<VotingDialog> {
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  final GlobalKey _inputFieldKey = GlobalKey();
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();
  bool _checkAll = false;
  bool _hasValue = false;
  bool _canVote = false;
  bool _isInitialRender = true;
  bool _isProcessingTap = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    _validateVote();
  }

  void _validateVote() {
    final voteAmount = _getVoteAmount();
    final myStarCandy = _getMyStarCandy();
    if (mounted) {
      setState(() {
        _canVote = voteAmount > 0 && voteAmount <= myStarCandy;
        _hasValue = voteAmount > 0;
      });
    }
  }

  int _getVoteAmount() =>
      int.tryParse(_textEditingController.text.replaceAll(',', '')) ?? 0;

  int _getMyStarCandy() {
    final userInfo = ref.read(userInfoProvider).value;
    return (userInfo?.starCandy ?? 0) + (userInfo?.starCandyBonus ?? 0);
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

    return LoadingOverlayWithIcon(
      key: _loadingKey,
      iconAssetPath: 'assets/app_icon_128.png',
      enableScale: true,
      enableFade: true,
      enableRotation: false,
      minScale: 0.98,
      maxScale: 1.02,
      showProgressIndicator: false,
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24),
        contentPadding: EdgeInsets.zero,
        content: LargePopupWidget(
          showCloseButton: false,
          content: Container(
            padding:
                EdgeInsets.only(top: 32, bottom: 24, left: 24.w, right: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                _buildMemberInfo(),
                _buildStarCandyInfo(myStarCandy),
                const SizedBox(height: 8),
                _buildCheckAllOption(),
                const SizedBox(height: 8),
                _buildVoteAmountInput(context),
                const SizedBox(height: 8),
                _buildErrorMessage(),
                _buildBubble(),
                const SizedBox(height: 9),
                _buildVoteButton(myStarCandy, userId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoteAmountInput(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialRender) {
        _isInitialRender = false;
      }

      // 포커스가 있을 때 텍스트 필드가 보이도록 적절한 위치로 스크롤
      if (_focusNode.hasFocus) {
        final RenderObject? renderObject =
            _inputFieldKey.currentContext?.findRenderObject();
        if (renderObject != null) {
          Scrollable.ensureVisible(
            _inputFieldKey.currentContext!,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    });

    return Container(
      key: _inputFieldKey,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(
          color: !_canVote && _hasValue
              ? AppColors.statusError
              : AppColors.primary500,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.only(right: 16.w),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isProcessingTap) return;

                _isProcessingTap = true;

                Future.delayed(const Duration(milliseconds: 50), () {
                  if (!mounted) return;
                  _focusNode.requestFocus();
                  _isProcessingTap = false;
                });
              },
              child: TextFormField(
                cursorHeight: 16.h,
                cursorColor: AppColors.primary500,
                focusNode: _focusNode,
                controller: _textEditingController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                enableInteractiveSelection: true,
                showCursor: true,
                keyboardAppearance: Brightness.light,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).label_input_input,
                  hintStyle: getTextStyle(AppTypo.body16R, AppColors.grey300),
                  border: InputBorder.none,
                  focusColor: AppColors.primary500,
                  fillColor: AppColors.grey900,
                  isCollapsed: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 5),
                ),
                onChanged: (_) => _validateVote(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    String newText = newValue.text.replaceAll(',', '');

                    // Remove leading zeros
                    newText = newText.replaceFirst(RegExp(r'^0+'), '');

                    if (newText.isEmpty) {
                      if (mounted) {
                        setState(() {
                          _hasValue = false;
                          _checkAll = false;
                        });
                      }
                      return const TextEditingValue(text: '');
                    }

                    final voteAmount = int.parse(newText);
                    if (voteAmount == 0) return oldValue;

                    if (mounted) {
                      setState(() {
                        _hasValue = true;
                        _checkAll = false;
                      });
                    }

                    final formattedText = formatNumberWithComma(newText);
                    return TextEditingValue(
                      text: formattedText,
                      selection:
                          TextSelection.collapsed(offset: formattedText.length),
                    );
                  }),
                ],
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
            ),
          ),
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildBubble() {
    return BubbleBox(
      shape: BubbleShapeBorder(
        border: BubbleBoxBorder(
          color: AppColors.primary500,
          width: 1.5,
          style: BubbleBoxBorderStyle.dashed,
        ),
        position: const BubblePosition.center(0),
        direction: BubbleDirection.top,
      ),
      backgroundColor: AppColors.secondary500,
      child: Column(
        children: [
          Text(
            '· ${AppLocalizations.of(context).voting_share_benefit_text}',
            style: getTextStyle(
              AppTypo.caption10SB,
              AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberInfo() {
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getLocaleTextFromJson(
                    (widget.voteItemModel.artist?.id ?? 0) != 0
                        ? widget.voteItemModel.artist?.name ?? {}
                        : widget.voteItemModel.artistGroup?.name ?? {}),
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
              SizedBox(width: 8.w),
              if ((widget.voteItemModel.artist?.id ?? 0) != 0 &&
                  widget.voteItemModel.artist?.artistGroup?.name != null)
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    getLocaleTextFromJson(
                        widget.voteItemModel.artist!.artistGroup!.name),
                    style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
                  ),
                ),
            ],
          ),
        ),
        Divider(color: AppColors.grey300, thickness: 1, height: 20.0.h),
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
            height: 32,
            alignment: Alignment.centerLeft,
            child: Image.asset(
                package: 'picnic_lib',
                'assets/icons/store/star_100.png',
                width: 32.w,
                height: 32),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Container(
              height: 26,
              alignment: Alignment.topLeft,
              child: Text(
                formatNumberWithComma(myStarCandy),
                style: getTextStyle(AppTypo.body16B, AppColors.primary500),
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
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.secondary500,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primary500, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).label_button_recharge,
              style: getTextStyle(AppTypo.body14B, AppColors.primary500),
            ),
            SizedBox(width: 4.w),
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/plus_style=fill.svg',
              width: 16.w,
              height: 16,
              colorFilter:
                  ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
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
        FocusScope.of(context).unfocus();

        if (mounted) {
          setState(() {
            _checkAll = !_checkAll;
            _hasValue = _checkAll;
            if (_checkAll) {
              final amount = _getMyStarCandy();
              _textEditingController.text = formatNumberWithComma(amount);
            } else {
              _textEditingController.clear();
            }
          });
        }
        _validateVote();
      },
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/check_style=line.svg',
              width: 20.w,
              height: 20,
              colorFilter: ColorFilter.mode(
                _checkAll ? AppColors.primary500 : AppColors.grey300,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              AppLocalizations.of(context).label_checkbox_entire_use,
              style: getTextStyle(
                AppTypo.body14M,
                _checkAll ? AppColors.primary500 : AppColors.grey300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _textEditingController.clear();
        if (mounted) {
          setState(() {
            _hasValue = false;
            _checkAll = false;
          });
        }
        _validateVote();

        _focusNode.requestFocus();
      },
      child: SvgPicture.asset(
        package: 'picnic_lib',
        'assets/icons/cancel_style=fill.svg',
        colorFilter: ColorFilter.mode(
          _hasValue ? AppColors.grey700 : AppColors.grey200,
          BlendMode.srcIn,
        ),
        width: 20.w,
        height: 20,
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (!_canVote && _hasValue) {
      return Container(
        padding: EdgeInsets.only(left: 22.w),
        width: double.infinity,
        child: Text(
          AppLocalizations.of(context).text_need_recharge,
          style: getTextStyle(AppTypo.caption10SB, AppColors.statusError),
          textAlign: TextAlign.left,
        ),
      );
    }
    return const SizedBox(height: 0);
  }

  Widget _buildVoteButton(int myStarCandy, String userId) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canVote ? () => _handleVote(myStarCandy, userId) : null,
      child: Container(
        width: 172.w,
        height: 52,
        decoration: BoxDecoration(
          color: _canVote ? AppColors.primary500 : AppColors.grey300,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context).label_button_vote,
          style: getTextStyle(
            AppTypo.title18SB,
            AppColors.grey00,
          ),
        ),
      ),
    );
  }

  void _handleVote(int myStarCandy, String userId) {
    final voteAmount = _getVoteAmount();
    if (voteAmount == 0 || myStarCandy < voteAmount) {
      showSimpleDialog(
        title: AppLocalizations.of(context).dialog_title_vote_fail,
        content: voteAmount == 0
            ? AppLocalizations.of(context)
                .text_dialog_vote_amount_should_not_zero
            : AppLocalizations.of(context).text_need_recharge,
        onOk: () {},
      );
      return;
    }

    FocusScope.of(context).unfocus();

    _loadingKey.currentState?.show();

    _performVoting(voteAmount, userId);
  }

  Future<void> _performVoting(int voteAmount, String userId) async {
    try {
      final response = await supabase.functions.invoke(
          widget.portalType == VotePortal.vote ? 'voting' : 'pic-voting',
          body: {
            'vote_id': widget.voteModel.id,
            'vote_item_id': widget.voteItemModel.id,
            'amount': voteAmount,
            'user_id': userId,
          });

      if (response.status != 200) {
        throw Exception('Failed to vote');
      }

      await ref.read(userInfoProvider.notifier).getUserProfiles();

      ref
          .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
          .fetch(voteId: widget.voteModel.id);

      _loadingKey.currentState?.hide();

      if (!mounted) return;

      Navigator.of(context).pop();

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final result = Map<String, dynamic>.from(response.data);
      result['votePickId'] = response.data['votePickId'];

      _showVotingCompleteDialog(result);
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      _loadingKey.currentState?.hide();
      Navigator.of(context).pop();

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
      type: DialogType.error,
      content: AppLocalizations.of(context).dialog_title_vote_fail,
      onOk: () {
        final navContext = navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          Navigator.of(navContext).pop();
        }
      },
    );
  }
}
