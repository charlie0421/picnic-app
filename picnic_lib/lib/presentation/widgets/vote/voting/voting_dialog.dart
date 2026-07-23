import 'dart:async';

import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/vote_transaction.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_transaction_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_usage_helper.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

Future showVotingDialog({
  required BuildContext context,
  required VoteModel voteModel,
  required VoteItemModel voteItemModel,
  VotePortal portalType = VotePortal.vote,
}) {
  final isPicPortal = portalType == VotePortal.pic;
  if (VotingDialogHelper.shouldUseJmaDialog(
    isPicPortal: isPicPortal,
    partner: voteModel.partner,
  )) {
    return showJmaVotingDialog(
      context: context,
      voteModel: voteModel,
      voteItemModel: voteItemModel,
      portalType: portalType,
    );
  }

  // 그 외의 경우는 일반 투표 다이얼로그 사용
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
  static const int _maxVotingRetries = 2;

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
  bool _isVoting = false; // 투표 중복 클릭 방지

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
    final wallet = widget.portalType == VotePortal.vote
        ? ref.read(walletSummaryProvider).value
        : null;
    final hasBalance = widget.portalType == VotePortal.vote
        ? wallet != null &&
              VotingDialogHelper.hasGeneralVoteBalance(
                wallet,
                BigInt.from(voteAmount),
              )
        : voteAmount <= _getMyStarCandy();
    if (mounted) {
      setState(() {
        _canVote = voteAmount > 0 && hasBalance;
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
    final wallet = widget.portalType == VotePortal.vote
        ? ref.watch(walletSummaryProvider)
        : null;
    if (widget.portalType == VotePortal.vote) {
      ref.listen(walletSummaryProvider, (previous, next) => _validateVote());
    }
    final summary = wallet?.value;
    final displayedBalance = widget.portalType == VotePortal.vote
        ? summary == null
              ? BigInt.zero
              : summary.cotton + summary.bonus + summary.star
        : BigInt.from(myStarCandy);
    final userId = ref.watch(
      userInfoProvider.select((value) => value.value?.id ?? ''),
    );

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
            padding: EdgeInsets.only(
              top: 32,
              bottom: 24,
              left: 24.w,
              right: 24.w,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                VotingArtistImage(voteItemModel: widget.voteItemModel),
                const SizedBox(height: 16),
                VotingMemberInfo(voteItemModel: widget.voteItemModel),
                VotingStarCandyInfo(
                  myStarCandy: displayedBalance,
                  onRecharge: _navigateToStore,
                ),
                const SizedBox(height: 8),
                VotingCheckAllOption(
                  checkAll: _checkAll,
                  onToggle: _toggleCheckAll,
                ),
                const SizedBox(height: 8),
                _buildVoteAmountInput(context),
                const SizedBox(height: 8),
                VotingErrorMessage(canVote: _canVote, hasValue: _hasValue),
                _buildBubble(),
                const SizedBox(height: 9),
                VotingSubmitButton(
                  canVote: _canVote,
                  isVoting: _isVoting,
                  onPressed: () => _handleVote(myStarCandy, userId),
                ),
                const SizedBox(height: 16),
                VotingLogoImage(voteModel: widget.voteModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToStore() {
    ref.read(navigationInfoProvider.notifier).setCurrentPage(const StorePage());
    ref.read(navigationInfoProvider.notifier).setVoteBottomNavigationIndex(3);
    Navigator.pop(context);
  }

  void _toggleCheckAll() {
    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _checkAll = !_checkAll;
        _hasValue = _checkAll;
        if (_checkAll) {
          if (widget.portalType == VotePortal.vote) {
            final wallet = ref.read(walletSummaryProvider).value;
            _textEditingController.text = wallet == null
                ? ''
                : formatWalletAmount(
                    VotingDialogHelper.cappedGeneralVoteBalance(wallet),
                  );
          } else {
            _textEditingController.text = formatNumberWithComma(
              _getMyStarCandy(),
            );
          }
        } else {
          _textEditingController.clear();
        }
      });
    }
    _validateVote();
  }

  Widget _buildVoteAmountInput(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialRender) {
        _isInitialRender = false;
      }

      // 포커스가 있을 때 텍스트 필드가 보이도록 적절한 위치로 스크롤
      if (_focusNode.hasFocus) {
        final RenderObject? renderObject = _inputFieldKey.currentContext
            ?.findRenderObject();
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 5,
                  ),
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

                    final voteAmount = int.tryParse(newText);
                    if (voteAmount == null || voteAmount == 0) return oldValue;

                    if (mounted) {
                      setState(() {
                        _hasValue = true;
                        _checkAll = false;
                      });
                    }

                    final formattedText = formatNumberWithComma(newText);
                    return TextEditingValue(
                      text: formattedText,
                      selection: TextSelection.collapsed(
                        offset: formattedText.length,
                      ),
                    );
                  }),
                ],
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
            ),
          ),
          VotingClearButton(
            hasValue: _hasValue,
            onClear: () {
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
          ),
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
      child: VotingBubbleInfo(voteModel: widget.voteModel),
    );
  }

  Future<void> _handleVote(int myStarCandy, String userId) async {
    // 이미 투표 진행 중이면 무시 (중복 클릭 방지)
    if (_isVoting) return;

    final voteAmount = _getVoteAmount();
    final amount = BigInt.from(voteAmount);
    final hasBalance = widget.portalType == VotePortal.vote
        ? await ref
              .read(walletSummaryProvider.future)
              .then(
                (wallet) =>
                    VotingDialogHelper.hasGeneralVoteBalance(wallet, amount),
              )
        : BigInt.from(myStarCandy) >= amount;
    if (!mounted) return;
    if (voteAmount == 0 || !hasBalance) {
      showSimpleDialog(
        title: AppLocalizations.of(context).dialog_title_vote_fail,
        content: voteAmount == 0
            ? AppLocalizations.of(
                context,
              ).text_dialog_vote_amount_should_not_zero
            : AppLocalizations.of(context).text_need_recharge,
        onOk: () {},
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (await showWithdrawalBlockedDialog(context: context, ref: ref)) {
      return;
    }

    if (!mounted) return;

    // 투표 시작 - 버튼 비활성화
    setState(() => _isVoting = true);

    _loadingKey.currentState?.show();

    await _performVoting(voteAmount, userId);
  }

  Future<FunctionResponse> _invokePicVoting({
    required int voteAmount,
    required String userId,
    required int starCandyUsage,
    required int starCandyBonusUsage,
    int retryCount = 0,
  }) async {
    try {
      return await supabase.functions.invoke(
        VotingDialogHelper.getVotingFunctionName(isPicPortal: true),
        body: {
          'vote_id': widget.voteModel.id,
          'vote_item_id': widget.voteItemModel.id,
          'amount': voteAmount,
          'user_id': userId,
          'star_candy_usage': starCandyUsage,
          'star_candy_bonus_usage': starCandyBonusUsage,
        },
      );
    } on FunctionException catch (e) {
      // 429 는 일시적 경합이므로 짧은 백오프(0.7s, 1.4s) 후 재시도.
      if (e.status == 429 && retryCount < _maxVotingRetries) {
        logger.d(
          'Voting rate limited (429), retry ${retryCount + 1}/$_maxVotingRetries',
        );
        await Future.delayed(Duration(milliseconds: 700 * (retryCount + 1)));

        if (!mounted) rethrow;

        return _invokePicVoting(
          voteAmount: voteAmount,
          userId: userId,
          starCandyUsage: starCandyUsage,
          starCandyBonusUsage: starCandyBonusUsage,
          retryCount: retryCount + 1,
        );
      }
      rethrow;
    }
  }

  // star_candy와 star_candy_bonus 사용량 계산
  Map<String, int> _calculateUsage(int totalAmount) {
    final userInfo = ref.read(userInfoProvider).value;
    final starCandyBonus = userInfo?.starCandyBonus ?? 0;

    return VotingUsageHelper.calculateUsage(
      totalAmount: totalAmount,
      starCandyBonus: starCandyBonus,
    );
  }

  Future<void> _performVoting(int voteAmount, String userId) async {
    // ProviderContainer 캡쳐 — async 작업 도중/이후 dialog 가 unmount 되어도
    // (사용자가 다른 탭으로 이동/뒤로가기) catch 블록의 provider 접근이 안전
    // 하도록 함수 시작 시 container 를 보관 (PICNIC-APP-530).
    final container = ProviderScope.containerOf(context);
    try {
      // 옵티미스틱 업데이트: 즉시 로컬 투표 수 반영
      final itemId = widget.voteItemModel.id;
      final currentTotal = widget.voteItemModel.voteTotal ?? 0;
      container
          .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
          .setVoteItem(id: itemId, voteTotal: currentTotal + voteAmount);

      late final Map<String, dynamic> completionResult;
      if (widget.portalType == VotePortal.vote) {
        final request = VoteTransactionRequest(
          voteId: widget.voteModel.id,
          voteItemId: widget.voteItemModel.id,
          amount: BigInt.from(voteAmount),
          requestId: const Uuid().v4(),
        );
        final result = await VotingDialogHelper.invokeVotingWithAuthRecovery(
          invoke: () => container
              .read(voteTransactionRepositoryProvider)
              .performGeneralVote(request),
          refresh: () async {
            final response = await supabase.auth.refreshSession();
            return response.session != null;
          },
          onRecovery: _recordAuthRecoveryEvent,
        );
        container
            .read(walletSummaryProvider.notifier)
            .setSummary(result.wallet);
        container
            .read(
              asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier,
            )
            .setVoteItem(
              id: widget.voteItemModel.id,
              voteTotal: result.updatedVoteTotal,
            );
        completionResult = result.toLegacyDialogMap();
      } else {
        final usage = _calculateUsage(voteAmount);
        final response = await VotingDialogHelper.invokeVotingWithAuthRecovery(
          invoke: () => _invokePicVoting(
            voteAmount: voteAmount,
            userId: userId,
            starCandyUsage: usage['star_candy_usage']!,
            starCandyBonusUsage: usage['star_candy_bonus_usage']!,
          ),
          refresh: () async {
            final response = await supabase.auth.refreshSession();
            return response.session != null;
          },
          onRecovery: _recordAuthRecoveryEvent,
        );
        container.read(userInfoProvider.notifier).getUserProfiles();
        final responseData = Map<String, dynamic>.from(response.data as Map);
        final serverTotal = responseData['updatedVoteTotal'] as int?;
        if (serverTotal != null) {
          container
              .read(
                asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier,
              )
              .setVoteItem(id: itemId, voteTotal: serverTotal);
        }
        completionResult = responseData;
      }

      if (!mounted) return;

      _loadingKey.currentState?.hide();

      if (!mounted) return;

      // navigatorKey context를 pop 전에 캡처 (dialog dispose 후에도 유효)
      final navContext = navigatorKey.currentContext;

      Navigator.of(context).pop();

      await Future.delayed(const Duration(milliseconds: 100));

      if (navContext == null || !navContext.mounted) return;

      showVotingCompleteDialog(
        context: navContext,
        voteModel: widget.voteModel,
        voteItemModel: widget.voteItemModel,
        result: completionResult,
      );
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      _loadingKey.currentState?.hide();

      // 투표 실패 시 롤백: 서버 데이터로 새로고침.
      // dialog 가 unmount 되어 ref 가 disposed 일 수 있으므로 capture 한
      // container 사용 (PICNIC-APP-530).
      container
          .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
          .fetch(voteId: widget.voteModel.id);
      if (widget.portalType == VotePortal.vote) {
        await container.read(walletSummaryProvider.notifier).refresh();
      } else {
        container.read(userInfoProvider.notifier).getUserProfiles();
      }

      // 투표 실패 시 버튼 다시 활성화
      if (mounted) {
        setState(() => _isVoting = false);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }

      _showVotingFailDialog(e);
    }
  }

  void _recordAuthRecoveryEvent(VotingAuthRecoveryEvent event) {
    final portal = widget.portalType == VotePortal.vote ? 'vote' : 'pic';
    unawaited(
      Sentry.captureEvent(
        SentryEvent(
          message: SentryMessage('vote_auth_recovery'),
          tags: VotingDialogHelper.authRecoveryTags(
            portal: portal,
            event: event,
          ),
          level: SentryLevel.info,
        ),
      ),
    );
  }

  // 실패 원인(FunctionException)에 따라 구체적인 안내 문구를 고른다.
  // 마감/미시작은 로컬라이즈된 문구를, 그 외(잔액 부족·처리 중 등)는 서버가 제공한
  // 사용자용 message 를 우선 노출하고, 없으면 일반 "투표 실패" 문구로 폴백한다.
  String _voteFailMessage(Object? error) {
    // dialog route 가 pop 된 직후라 State.context 는 teardown 중일 수 있으므로,
    // Localizations 가 살아있는 root navigator context 로 문구를 조회한다.
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return '';
    final l10n = AppLocalizations.of(ctx);
    return VotingDialogHelper.resolveVoteFailureMessage(
      error: error,
      reLoginMessage: l10n.error_user_not_authenticated,
      genericMessage: l10n.dialog_title_vote_fail,
      endedMessage: l10n.message_vote_is_ended,
      upcomingMessage: l10n.message_vote_is_upcoming,
    );
  }

  void _showVotingFailDialog([Object? error]) {
    showSimpleDialog(
      type: DialogType.error,
      content: _voteFailMessage(error),
      onOk: () {
        final navContext = navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          Navigator.of(navContext).pop();
        }
      },
    );
  }
}
