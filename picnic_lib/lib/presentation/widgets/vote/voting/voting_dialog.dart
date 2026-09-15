import 'dart:async';
import 'dart:math' as math;

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
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/wallet_summary_applier.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/vote_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_usage_helper.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// How much of the voting popup body stays pinned while the middle scrolls.
enum _PinnedChrome {
  /// Portrait and names pinned above, submit (and logo) pinned below.
  full,

  /// Portrait pinned above, submit pinned below; the names scroll.
  compact,

  /// Nothing pinned: the whole body scrolls.
  none,
}

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

  /// The dialog's outer breathing room with the keyboard down.
  static const double _outerInsetVertical = 24;

  /// The same room with the keyboard up, minus the exact extra the top close
  /// strip takes from the body.
  ///
  /// PICNIC-2695 replaced a 24 hidden strip with a 48 close strip, so the body
  /// budget lost 24. With the keyboard up on a 320x568 viewport that was the
  /// whole margin PICNIC-2688's pinned portrait was living on — it dropped to
  /// the all-scroll layout and the portrait scrolled out of the capsule again.
  /// Handing the same 24 back across the two edges leaves the body budget
  /// exactly where it was, which is why this is derived from the two strip
  /// constants rather than picked. With the keyboard down the budget is not
  /// tight, so the original inset stays.
  static const double _keyboardOuterInsetVertical =
      _outerInsetVertical -
      (kLargePopupTopCloseStripHeight - kLargePopupHiddenCloseStripHeight) / 2;

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

    // walletSummaryProvider is keepAlive with no TTL and no refresh on app
    // resume, and "use all" writes its total into the amount field verbatim.
    // The server expires Cotton grants and Bonus buckets at vote time before
    // computing the balance, so an hours-old snapshot asks for more than is
    // spendable and comes back 409 WALLET_INSUFFICIENT_BALANCE even though the
    // client pre-check passed. Re-read it when the dialog opens.
    //
    // Best-effort on purpose: a slow or failing refresh must not delay or block
    // the dialog, which still works off the cached snapshot.
    //
    // Deferred a frame on purpose: when the wallet cache is empty, refresh()
    // writes AsyncLoading before its first await, and doing that from initState
    // is a provider write during build - Riverpod asserts and the refresh is
    // lost entirely, which is exactly the cold-start case that needs it most.
    if (widget.portalType == VotePortal.vote) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          VotingDialogHelper.bestEffortWalletRefresh(
            () => ref.read(walletSummaryProvider.notifier).refresh(),
            onError: (error, stackTrace) => logger.w(
              'voting dialog open wallet refresh failed',
              error: error,
              stackTrace: stackTrace,
            ),
          ),
        );
      });
    }
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

  /// Ends the amount field's editing session.
  ///
  /// The owned node, not `FocusScope.unfocus()`: by the time a terminal path
  /// runs, focus may already have moved to another route, and clearing the
  /// scope there would blur *that* input instead. Idempotent, so every exit
  /// path can call it without checking who called it first.
  void _unfocusVoteInput() => _focusNode.unfocus();

  /// The single user-initiated close.
  ///
  /// Re-reads [_isVoting] instead of trusting the state that was current when
  /// the callback was captured: the close button hands this to the shared
  /// popup, and a handler captured while idle must not become a way around the
  /// in-flight guard. The terminal success/failure pops stay direct — routing
  /// them through here would mean a vote that has already settled could never
  /// close its own dialog.
  void _requestClose() {
    if (!mounted || _isVoting) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _unfocusVoteInput();
    // A direct pop, not `maybePop`: the PopScope above vetoes every route-driven
    // pop, so `maybePop` would come straight back into this method through
    // `onPopInvokedWithResult` and recurse.
    Navigator.of(context).pop();
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
    // Read for the flag only; the height budget below comes from the layout
    // constraints, which already have this inset applied once by the Dialog.
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Closing the dialog does not cancel the vote: the request keeps running
    // against the captured ProviderContainer. Reopening and voting again mints
    // a new request_id, which the server settles as a separate vote — so a
    // mid-flight dismissal is a double-charge window, not a cancel. The loading
    // overlay already swallows barrier taps (it is a full-screen opaque entry
    // above this route); system back is the path that still gets through.
    return PopScope(
      // Veto every route-driven pop and decide in [_requestClose] instead.
      //
      // `canPop: !_isVoting` cannot hold this line. PopScope copies `canPop`
      // into the route's notifier only from `didUpdateWidget`
      // (pop_scope.dart:205-208) and `ModalRoute.popDisposition` reads that
      // notifier (routes.dart:2037-2044), so a back press or barrier tap that
      // arrives in the submit tap's own frame — before the rebuild — still
      // reads the pre-submit `true` and pops. The request is already on its
      // way by then, which is exactly the double-charge window 7fbd2bec8
      // closed. Vetoing unconditionally moves the decision to the moment of
      // the request, where `_isVoting` is whatever `setState` just wrote.
      //
      // The cost is Android's predictive-back animation, which this dialog
      // route does not use.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // An imperative pop (this dialog's own terminal paths, an account
          // switch, host routing) already removed the route. Nothing to
          // decide — just make sure no editing session outlives it.
          _unfocusVoteInput();
          return;
        }
        _requestClose();
      },
      child: LoadingOverlayWithIcon(
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
          insetPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: isKeyboardVisible
                ? _keyboardOuterInsetVertical
                : _outerInsetVertical,
          ),
          contentPadding: EdgeInsets.zero,
          // 캡슐 자체는 뷰포트 안에 남고, 넘치는 것은 캡슐 "안쪽" 이 스크롤한다.
          //
          // 폭을 카드와 같은 값으로 고정해 두는 이유: AlertDialog 는 content 를
          // IntrinsicWidth 로 감싸 intrinsic 폭을 묻는데 LayoutBuilder 는 그
          // 질문에 답할 수 없다. 타이트한 폭 제약이 그 질의를 여기서 끊는다.
          content: SizedBox(
            width: defaultLargePopupWidth(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 이 제약이 곧 "라우트가 실제로 남겨 준 높이"다 — Dialog 가
                // viewInsets 와 insetPadding 을, 라우트가 세이프에어리어를
                // 이미 덜어낸 뒤의 값이라 여기서 MediaQuery 를 다시 읽으면
                // 키보드를 두 번 적용하게 된다. 카드 테두리와 숨김 스트립은
                // 캡슐 자신의 높이이므로 본문 예산에서 빼 준다.
                final available = constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : MediaQuery.of(context).size.height;
                final budget = math.max(
                  0.0,
                  available - largePopupTopCloseChromeHeight(),
                );
                return LargePopupWidget(
                  showCloseButton: true,
                  closeButtonPlacement: LargePopupCloseButtonPlacement.topRight,
                  // Disabled, not removed: the strip keeps its height so the
                  // popup does not jump when the request starts, and the
                  // callback re-checks the flag anyway.
                  closeButtonEnabled: !_isVoting,
                  onClose: _requestClose,
                  content: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: budget),
                    child: switch (_pinnedChromeFor(
                      context,
                      budget: budget,
                      width: constraints.maxWidth,
                      isKeyboardVisible: isKeyboardVisible,
                    )) {
                      _PinnedChrome.none => _buildAllScrollBody(
                        context,
                        displayedBalance: displayedBalance,
                        myStarCandy: myStarCandy,
                        userId: userId,
                        isKeyboardVisible: isKeyboardVisible,
                      ),
                      final pinned => _buildFixedChromeBody(
                        context,
                        displayedBalance: displayedBalance,
                        myStarCandy: myStarCandy,
                        userId: userId,
                        isKeyboardVisible: isKeyboardVisible,
                        pinNames: pinned == _PinnedChrome.full,
                      ),
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Which parts of the body the budget can afford to pin.
  ///
  /// PICNIC-2688: with the keyboard up, a single scroll view centred the amount
  /// input and pushed the artist portrait out of the capsule. Pinning the
  /// portrait and the submit button keeps both in view and lets only the
  /// balance/amount rows scroll. The names pin with the portrait when there is
  /// room ([_PinnedChrome.full]); on a shorter budget they move into the
  /// scrolling window so the portrait can stay pinned ([_PinnedChrome.compact]);
  /// only a budget that cannot hold even portrait + submit + one 48 row (a
  /// 320x568 viewport at 200% text with a 300 keyboard) scrolls the whole
  /// body as before, so nothing overflows ([_PinnedChrome.none]).
  ///
  /// The pinned parts are measured, not assumed: the names wrap, so a fixed
  /// threshold left a long name to overflow the pinned column. The estimate
  /// mirrors each pinned widget's own geometry and carries a small margin so
  /// a rounding difference can never turn into an overflow.
  _PinnedChrome _pinnedChromeFor(
    BuildContext context, {
    required double budget,
    required double width,
    required bool isKeyboardVisible,
  }) {
    final contentWidth =
        width - largePopupCardBorderWidth() * 2 - PicnicUi.horizontal(24) * 2;
    if (contentWidth <= 0) return _PinnedChrome.none;

    final portrait =
        _headerTopPadding(isKeyboardVisible) +
        VotingArtistImage.preferredHeight() +
        _headerGap(isKeyboardVisible);
    final names = VotingMemberInfo.preferredHeight(
      context,
      voteItemModel: widget.voteItemModel,
      maxWidth: contentWidth,
    );
    final footer =
        _footerTopPadding(isKeyboardVisible) +
        VotingSubmitButton.preferredHeight(context) +
        (isKeyboardVisible
            ? 0
            : PicnicUi.vertical(16) +
                  VotingLogoImage.preferredHeight(widget.voteModel)) +
        _footerBottomPadding(isKeyboardVisible);
    // The scrolling window has to show the amount input whole, and at a large
    // text scale the input outgrows its 48 minimum (scaled line plus padding
    // and border), so the window is sized from the input, not the minimum.
    const margin = 8.0;
    final window = _amountInputPreferredHeight(context, contentWidth) + margin;
    if (budget >= portrait + names + footer + window) return _PinnedChrome.full;
    if (budget >= portrait + footer + window) return _PinnedChrome.compact;
    return _PinnedChrome.none;
  }

  /// Mirrors the amount input built in [_buildVoteAmountInput]: the 48
  /// minimum, or the scaled digit line plus the field padding and border.
  double _amountInputPreferredHeight(BuildContext context, double maxWidth) {
    final line = measureVotingTextHeight(
      context,
      '0',
      _amountInputStyle(),
      maxWidth: maxWidth,
    );
    return math.max(
      PicnicUi.minimumTapTarget,
      line + _amountInputVerticalPadding() * 2 + _amountInputBorderWidth * 2,
    );
  }

  static const double _amountInputBorderWidth = 1;
  double _amountInputVerticalPadding() => PicnicUi.vertical(8);
  TextStyle _amountInputStyle() =>
      PicnicUi.text(size: 16, weight: FontWeight.w700);

  EdgeInsets _bodyHorizontalPadding() => EdgeInsets.only(
    left: PicnicUi.horizontal(24),
    right: PicnicUi.horizontal(24),
  );

  /// Pinned header + scrolling middle + pinned footer.
  ///
  /// `Flexible.loose` (not `Expanded`) so the middle takes only the height it
  /// needs while everything fits and the capsule keeps its intrinsic height;
  /// it grows a scroll bar only when the keyboard eats into the budget.
  Widget _buildFixedChromeBody(
    BuildContext context, {
    required BigInt displayedBalance,
    required int myStarCandy,
    required String userId,
    required bool isKeyboardVisible,
    required bool pinNames,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(isKeyboardVisible: isKeyboardVisible, withNames: pinNames),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            child: _buildScrollableMiddle(
              context,
              displayedBalance,
              pinned: true,
              withNames: !pinNames,
            ),
          ),
        ),
        _buildFooter(
          myStarCandy: myStarCandy,
          userId: userId,
          isKeyboardVisible: isKeyboardVisible,
        ),
      ],
    );
  }

  /// The same pieces in the same order inside one scroll view, for a budget
  /// too small to pin anything.
  Widget _buildAllScrollBody(
    BuildContext context, {
    required BigInt displayedBalance,
    required int myStarCandy,
    required String userId,
    required bool isKeyboardVisible,
  }) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(isKeyboardVisible: isKeyboardVisible, withNames: true),
          _buildScrollableMiddle(
            context,
            displayedBalance,
            pinned: false,
            withNames: false,
          ),
          _buildFooter(
            myStarCandy: myStarCandy,
            userId: userId,
            isKeyboardVisible: isKeyboardVisible,
          ),
        ],
      ),
    );
  }

  // With the keyboard up the header and footer give up part of their
  // breathing room (as the JMA dialog does), so the scrolling window between
  // them keeps the bonus bubble whole on a phone instead of a sliver of it.
  double _headerTopPadding(bool isKeyboardVisible) =>
      PicnicUi.vertical(isKeyboardVisible ? 12 : 24);
  double _headerGap(bool isKeyboardVisible) =>
      PicnicUi.vertical(isKeyboardVisible ? 8 : 16);
  double _footerTopPadding(bool isKeyboardVisible) =>
      PicnicUi.vertical(isKeyboardVisible ? 4 : 8);
  double _footerBottomPadding(bool isKeyboardVisible) =>
      PicnicUi.vertical(isKeyboardVisible ? 12 : 16);

  Widget _buildHeader({
    required bool isKeyboardVisible,
    required bool withNames,
  }) {
    return Padding(
      padding: _bodyHorizontalPadding().copyWith(
        top: _headerTopPadding(isKeyboardVisible),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VotingArtistImage(voteItemModel: widget.voteItemModel),
          SizedBox(height: _headerGap(isKeyboardVisible)),
          if (withNames) VotingMemberInfo(voteItemModel: widget.voteItemModel),
        ],
      ),
    );
  }

  // The balance, use-all, amount and clear controls each carry a 48 tap
  // target now, so the gaps that used to separate 20 and 32 high rows moved
  // inside those controls.
  Widget _buildScrollableMiddle(
    BuildContext context,
    BigInt displayedBalance, {
    required bool pinned,
    required bool withNames,
  }) {
    return Padding(
      padding: _bodyHorizontalPadding(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withNames) VotingMemberInfo(voteItemModel: widget.voteItemModel),
          VotingStarCandyInfo(
            myStarCandy: displayedBalance,
            onRecharge: _navigateToStore,
          ),
          VotingCheckAllOption(checkAll: _checkAll, onToggle: _toggleCheckAll),
          _buildVoteAmountInput(context, pinned: pinned),
          SizedBox(height: PicnicUi.vertical(8)),
          VotingErrorMessage(canVote: _canVote, hasValue: _hasValue),
          _buildBubble(),
        ],
      ),
    );
  }

  /// The submit button, and the partner/picnic logo only while the keyboard
  /// is down: with it up the logo's row is better spent on the amount input.
  Widget _buildFooter({
    required int myStarCandy,
    required String userId,
    required bool isKeyboardVisible,
  }) {
    return Padding(
      padding: _bodyHorizontalPadding().copyWith(
        top: _footerTopPadding(isKeyboardVisible),
        bottom: _footerBottomPadding(isKeyboardVisible),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VotingSubmitButton(
            canVote: _canVote,
            isVoting: _isVoting,
            onPressed: () => _handleVote(myStarCandy, userId),
          ),
          if (!isKeyboardVisible) ...[
            SizedBox(height: PicnicUi.vertical(16)),
            VotingLogoImage(voteModel: widget.voteModel),
          ],
        ],
      ),
    );
  }

  void _navigateToStore() {
    // Same guard as the close button, and it runs *before* the provider writes:
    // this path pops the dialog too, so mid-vote it would open the same
    // double-charge window — and a refused close must leave the page underneath
    // untouched as well.
    if (!mounted || _isVoting) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _unfocusVoteInput();
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

  /// [pinned] is true inside the pinned-header body, where the input scrolls
  /// in a short middle window: centring it there dragged the balance row
  /// half under the pinned names even when the input was already in view, so
  /// that window moves only as far as it must. The all-scroll body keeps
  /// centring, which also brings the submit button below into view.
  Widget _buildVoteAmountInput(BuildContext context, {required bool pinned}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialRender) {
        _isInitialRender = false;
      }

      // 포커스가 있을 때 텍스트 필드가 보이도록 적절한 위치로 스크롤
      if (_focusNode.hasFocus) {
        final inputContext = _inputFieldKey.currentContext;
        final RenderObject? renderObject = inputContext?.findRenderObject();
        if (inputContext == null || renderObject == null) return;
        if (pinned) {
          // Each policy is a no-op unless the input is cut off on its side,
          // so at most one of the two moves the window.
          for (final policy in const [
            ScrollPositionAlignmentPolicy.keepVisibleAtStart,
            ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ]) {
            Scrollable.ensureVisible(
              inputContext,
              alignmentPolicy: policy,
              duration: const Duration(milliseconds: 300),
            );
          }
          return;
        }
        Scrollable.ensureVisible(
          inputContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
        );
      }
    });

    return Container(
      key: _inputFieldKey,
      // A 36 high field was below the minimum tap target and cropped its own
      // text at large scales; the field now grows from 48 instead.
      constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
      decoration: BoxDecoration(
        border: Border.all(
          color: !_canVote && _hasValue
              ? AppColors.statusError
              : PicnicUi.actionColor,
          width: _amountInputBorderWidth,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.only(right: PicnicUi.horizontal(4)),
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
                cursorColor: PicnicUi.actionColor,
                focusNode: _focusNode,
                controller: _textEditingController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                enableInteractiveSelection: true,
                showCursor: true,
                keyboardAppearance: Brightness.light,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).label_input_input,
                  hintStyle: PicnicUi.text(size: 16, color: PicnicUi.quietText),
                  border: InputBorder.none,
                  focusColor: PicnicUi.actionColor,
                  fillColor: AppColors.grey900,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: PicnicUi.horizontal(24),
                    vertical: _amountInputVerticalPadding(),
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
                style: _amountInputStyle(),
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
          color: PicnicUi.actionColor,
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
    // 가드는 첫 await 앞에서 세운다. 아래 잔액 조회와 탈퇴 확인은 둘 다 await 이고
    // 탈퇴 확인은 네트워크 왕복이다. 그 구간 동안 버튼이 살아 있으면 두 번째 탭이
    // 이 가드를 그대로 통과하고, 두 실행이 각자 새 request_id 를 발급해 서버
    // 멱등성이 걸리지 않는다 - 한 번의 투표가 아니라 두 번의 차감이 된다.
    // 아래 조기 반환 경로들은 반드시 플래그를 되돌려야 한다.
    setState(() => _isVoting = true);
    // Ahead of the validation branches below, not after them: those branches
    // put an error dialog on top of a *still focused* field, and dismissing
    // that dialog hands focus straight back to it — the keyboard comes back
    // over a popup the user was trying to leave.
    _unfocusVoteInput();

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
      setState(() => _isVoting = false);
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

    if (await showWithdrawalBlockedDialog(context: context, ref: ref)) {
      if (mounted) setState(() => _isVoting = false);
      return;
    }

    if (!mounted) return;

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
    // 같은 자리에서 **이 투표를 하는 계정**도 잡는다(PICNIC-2664). 투표 RPC 는
    // 네트워크만큼 걸리고, 아래 invokeVotingWithAuthRecovery 는 그 사이 세션을
    // 갱신해 재시도까지 한다. 그 창에서 계정이 바뀌면 A 의 정산 잔액이 B 화면에
    // 쓰인다. 여기서 잡아야 의미가 있다 - 응답이 온 뒤에 잡으면 그 순간의
    // 계정이라 항상 통과한다.
    final applyWallet = ContainerWalletSummaryApplier.forContainer(container);
    // invoke(2xx) 도달 여부. invoke 자체 실패(=팝업 원인)와, 성공 후 후처리에서
    // throw 된 경우를 텔레메트리에서 구분(vote_fail_phase)하기 위한 플래그.
    bool invokeSucceeded = false;
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
        invokeSucceeded = true; // 2xx 도달 — 서버측 투표는 성공
        // GA4 vote (스펙 §2-10). 2xx 이후에만 — 잔액 부족·마감·실패는 여기에
        // 도달하지 못한다. 소모량은 서버 정산이 돌려준 usage 를 그대로 쓴다.
        unawaited(
          VoteAnalytics.logVote(
            voteModel: widget.voteModel,
            voteItemModel: widget.voteItemModel,
            usage: {
              WalletCurrency.starCandy: result.usage.starCandy,
              WalletCurrency.bonusStarCandy: result.usage.bonusStarCandy,
              WalletCurrency.cottonCandy: result.usage.cottonCandy,
            },
          ),
        );
        applyWallet(result.wallet);
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
        invokeSucceeded = true; // 2xx 도달 — 서버측 투표는 성공
        // pic 포털은 정산 응답에 usage 가 없다. 서버로 **보낸** 분해값이 곧
        // 소모량이므로(엣지 함수가 그 값대로 차감한다) 재계산하지 않고 그대로
        // 쓴다. 코튼캔디는 이 포털의 결제 수단이 아니라 항상 0 이다.
        unawaited(
          VoteAnalytics.logVote(
            voteModel: widget.voteModel,
            voteItemModel: widget.voteItemModel,
            usage: {
              WalletCurrency.starCandy: BigInt.from(usage['star_candy_usage']!),
              WalletCurrency.bonusStarCandy: BigInt.from(
                usage['star_candy_bonus_usage']!,
              ),
            },
          ),
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

      // Idempotent belt-and-braces before the terminal pop: submission already
      // blurred the field, but this is the pop the completion dialog replaces
      // the route with, and it must not hand a live editing session over.
      _unfocusVoteInput();
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

      // 오류 UI 와 로딩 상태 복원을 wallet refresh 보다 먼저 보장한다.
      if (mounted) {
        setState(() => _isVoting = false);
      }

      if (mounted) {
        _unfocusVoteInput();
        Navigator.of(context).pop();
      }

      // 복구(rollback/pop) 이후에 best-effort 텔레메트리. 절대 복구를 막지 않는다.
      _reportVoteFailure(e, afterInvoke: invokeSucceeded);
      _showVotingFailDialog(e);

      // 실패 후 wallet refresh 는 timeout 과 자체 오류 처리를 가진 best-effort.
      // refresh 가 hang/throw 해도 위의 실패 처리와 dialog 종료를 막지 않는다.
      if (widget.portalType == VotePortal.vote) {
        unawaited(
          VotingDialogHelper.bestEffortWalletRefresh(
            () => container.read(walletSummaryProvider.notifier).refresh(),
            onError: (error, stackTrace) => logger.w(
              'post-failure wallet refresh failed',
              error: error,
              stackTrace: stackTrace,
            ),
          ),
        );
      } else {
        container.read(userInfoProvider.notifier).getUserProfiles();
      }
    }
  }

  // [계측] vote 실패 원인 분포(429/403/400/500 등)를 측정하기 위한 텔레메트리.
  // catch 의 logger.e 는 Sentry 로 전송되지 않고, beforeSend 는 FunctionException
  // 을 필터링하므로 그동안 투표 실패가 어디에도 집계되지 않았다. exception 이 없는
  // captureMessage 는 beforeSend(app_initializer)의 exceptionType 기준 필터를
  // 통과하므로, 'vote_failed' 단일 이슈를 status/reason/phase tag 로 group-by 해
  // 분포를 측정한다.
  // 주의: retry(429) 는 catch 도달 전이라 '최종 사용자에게 보인 실패'만 집계된다
  //   (재시도로 회복된 일시적 429 는 미포함 — 팝업 원인 측정에는 정확).
  //   실제 제출 실패만 보려면 vote_fail_phase:invoke 로 필터(post_invoke 는 2xx 후
  //   클라 후처리 throw 로, 서버측 투표는 성공한 케이스).
  static int _voteFailReportCount = 0; // 세션당 상한(단일 클라 이벤트 폭주 방지)

  void _reportVoteFailure(Object? error, {required bool afterInvoke}) {
    // 텔레메트리는 best-effort — 어떤 경우에도 복구 경로를 깨지 않는다.
    try {
      // 세션당 상한. 교차 사용자 스파이크는 Sentry inbound spike-protection 위임.
      if (_voteFailReportCount >= 50) return;
      _voteFailReportCount++;

      String status = 'unknown';
      String reason = 'none';
      if (error is FunctionException) {
        status = error.status.toString();
        final details = error.details;
        if (details is Map) {
          reason = (details['reason'] ?? details['error'] ?? 'none').toString();
        } else if (details is String && details.trim().isNotEmpty) {
          reason = details.trim(); // gateway/HTML/plaintext 등 비-JSON 본문
        }
      } else if (error != null) {
        status = 'exception';
        reason = 'type:${error.runtimeType}';
      }
      // Sentry tag 길이/카디널리티 가드(~200자 제한)
      if (reason.length > 80) reason = reason.substring(0, 80);
      final phase = afterInvoke ? 'post_invoke' : 'invoke';

      unawaited(
        Sentry.captureMessage(
          'vote_failed',
          level: SentryLevel.warning,
          withScope: (scope) {
            scope.fingerprint = ['vote_failed']; // 단일 이슈 고정(분포 측정용)
            scope.setTag('vote_fail_status', status);
            scope.setTag('vote_fail_reason', reason);
            scope.setTag('vote_fail_phase', phase);
            scope.setTag(
              'vote_portal',
              widget.portalType == VotePortal.vote ? 'vote' : 'pic',
            );
            scope.setContexts('vote_fail', {
              'status': status,
              'reason': reason,
              'phase': phase,
              'vote_id': widget.voteModel.id,
              'vote_item_id': widget.voteItemModel.id,
            });
          },
        ),
      );
    } catch (_) {
      // 의도적으로 무시: 계측 실패가 투표 복구 흐름에 영향 주지 않도록.
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
      insufficientBalanceMessage: l10n.text_need_recharge,
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
