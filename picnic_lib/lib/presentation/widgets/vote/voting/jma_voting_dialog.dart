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
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
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

Future showJmaVotingDialog({
  required BuildContext context,
  required VoteModel voteModel,
  required VoteItemModel voteItemModel,
  VotePortal portalType = VotePortal.vote,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return JmaVotingDialog(
        voteModel: voteModel,
        voteItemModel: voteItemModel,
        portalType: portalType,
      );
    },
  );
}

class JmaVotingDialog extends ConsumerStatefulWidget {
  final VoteModel voteModel;
  final VoteItemModel voteItemModel;
  final VotePortal portalType;

  const JmaVotingDialog({
    super.key,
    required this.voteModel,
    required this.voteItemModel,
    required this.portalType,
  });

  @override
  ConsumerState<JmaVotingDialog> createState() => _JmaVotingDialogState();
}

class _JmaVotingDialogState extends ConsumerState<JmaVotingDialog> {
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
            decoration: BoxDecoration(
              // JMA 전용 배경 스타일
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                _buildJmaHeader(),
                const SizedBox(height: 16),
                _buildArtistImage(),
                const SizedBox(height: 16),
                _buildMemberInfo(),
                _buildStarCandyInfo(myStarCandy),
                const SizedBox(height: 8),
                _buildCheckAllOption(),
                const SizedBox(height: 8),
                _buildVoteAmountInput(context),
                const SizedBox(height: 8),
                _buildErrorMessage(),
                _buildJmaBubble(),
                const SizedBox(height: 9),
                _buildJmaVoteButton(myStarCandy, userId),
                const SizedBox(height: 16),
                _buildJmaLogoImage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJmaHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'JMA',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'JMA 파트너십 보팅',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistImage() {
    // 아티스트 이미지 URL을 가져오기
    String? imageUrl;
    if ((widget.voteItemModel.artist?.id ?? 0) != 0) {
      imageUrl = widget.voteItemModel.artist?.image;
    } else {
      imageUrl = widget.voteItemModel.artistGroup?.image;
    }

    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blue.shade600,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? PicnicCachedNetworkImage(
                imageUrl: imageUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
              )
            : _buildDefaultArtistImage(),
      ),
    );
  }

  Widget _buildDefaultArtistImage() {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade100,
      ),
      child: Icon(
        Icons.person,
        size: 40.w,
        color: Colors.blue.shade600,
      ),
    );
  }

  Widget _buildJmaLogoImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120.w,
          height: 60.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade300,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'JMA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'PARTNERSHIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'JMA와 함께하는 특별한 보팅',
          style: TextStyle(
            color: Colors.blue.shade600,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              ? Colors.red.shade400
              : Colors.blue.shade600,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
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
                cursorColor: Colors.blue.shade600,
                focusNode: _focusNode,
                controller: _textEditingController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                enableInteractiveSelection: true,
                showCursor: true,
                keyboardAppearance: Brightness.light,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).label_input_input,
                  hintStyle:
                      getTextStyle(AppTypo.body16R, Colors.grey.shade400),
                  border: InputBorder.none,
                  focusColor: Colors.blue.shade600,
                  fillColor: Colors.white,
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
                style: getTextStyle(AppTypo.body16B, Colors.blue.shade700),
              ),
            ),
          ),
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildJmaBubble() {
    return BubbleBox(
      shape: BubbleShapeBorder(
        border: BubbleBoxBorder(
          color: Colors.blue.shade600,
          width: 2,
          style: BubbleBoxBorderStyle.solid,
        ),
        position: const BubblePosition.center(0),
        direction: BubbleDirection.top,
      ),
      backgroundColor: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: Colors.blue.shade600,
                size: 16,
              ),
              SizedBox(width: 4.w),
              Text(
                'JMA 파트너십 혜택',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '· 추가 리워드 혜택 제공\n· 특별 이벤트 참여 기회\n· JMA 독점 컨텐츠 액세스',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
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
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              if ((widget.voteItemModel.artist?.id ?? 0) != 0 &&
                  widget.voteItemModel.artist?.artistGroup?.name != null)
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    getLocaleTextFromJson(
                        widget.voteItemModel.artist!.artistGroup!.name),
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(color: Colors.blue.shade300, thickness: 1, height: 20.0.h),
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
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
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
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.blue.shade600, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).label_button_recharge,
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.add,
              color: Colors.blue.shade600,
              size: 16,
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
            Icon(
              _checkAll ? Icons.check_box : Icons.check_box_outline_blank,
              color: _checkAll ? Colors.blue.shade600 : Colors.grey.shade400,
              size: 20,
            ),
            SizedBox(width: 4.w),
            Text(
              AppLocalizations.of(context).label_checkbox_entire_use,
              style: TextStyle(
                color: _checkAll ? Colors.blue.shade600 : Colors.grey.shade400,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
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
      child: Icon(
        Icons.clear,
        color: _hasValue ? Colors.blue.shade600 : Colors.grey.shade400,
        size: 20,
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
          style: TextStyle(
            color: Colors.red.shade600,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.left,
        ),
      );
    }
    return const SizedBox(height: 0);
  }

  Widget _buildJmaVoteButton(int myStarCandy, String userId) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canVote ? () => _handleVote(myStarCandy, userId) : null,
      child: Container(
        width: 172.w,
        height: 52,
        decoration: BoxDecoration(
          gradient: _canVote
              ? LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                )
              : null,
          color: _canVote ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _canVote
              ? [
                  BoxShadow(
                    color: Colors.blue.shade300,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_canVote) ...[
              Icon(
                Icons.how_to_vote,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              'JMA 보팅',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
