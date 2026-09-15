import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/jma_voting_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/vote_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_layout.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/common_gradient.dart';

/// 라우트가 아무리 좁아도 팝업 본문을 이 아래로는 줄이지 않는다.
const double _minimumDialogBudget = 200;

/// 키보드가 없을 때 팝업이 화면에서 차지하는 기본 비율.
const double _preferredHeightRatio = 0.75;

/// 키보드가 올라왔을 때의 기본 비율.
const double _preferredHeightRatioWithKeyboard = 0.85;

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
  bool _isPolicyExpanded = false;
  bool _isVoting = false; // 투표 중복 클릭 방지
  String _validationMessage = '';
  int _dailyVoteCount = 0; // 오늘 보너스 별사탕 사용량
  static const int _maxDailyVotes = 5; // 일일 최대 보너스 별사탕 사용량 (5개)
  bool _isDailyVoteCountLoaded = false; // 일일 사용량 로딩 완료 여부

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    _focusNode.addListener(_onFocusChange);
    _loadDailyVoteCount();
  }

  // 오늘 보너스 별사탕 사용량 조회 (엣지 함수에서 UTC 기준으로 조회)
  Future<void> _loadDailyVoteCount() async {
    try {
      final userId = ref.read(userInfoProvider).value?.id ?? '';
      if (userId.isEmpty) return;

      // 전용 엣지 함수를 통해 일일 사용량 조회 (UTC 기준)
      final response = await supabase.functions.invoke(
        'jma-voting-usage',
        queryParameters: {
          'user_id': userId,
          'vote_id': widget.voteModel.id.toString(),
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _dailyVoteCount = data['dailyVoteCount'] ?? 0;
            _isDailyVoteCountLoaded = true;
          });
        }
      } else {
        logger.e(
          'Failed to load daily vote count from usage function: ${response.status}',
        );
        if (mounted) {
          setState(() {
            _dailyVoteCount = 0; // 기본값으로 설정
            _isDailyVoteCountLoaded = true;
          });
        }
      }
    } catch (e) {
      logger.e('Failed to load daily vote count', error: e);
      if (mounted) {
        setState(() {
          _dailyVoteCount = 0; // 기본값으로 설정
          _isDailyVoteCountLoaded = true;
        });
      }
    }
  }

  void _onFocusChange() {
    _validateVote();
  }

  // 입력받은 투표수 가져오기
  int _getVoteAmount() =>
      int.tryParse(_textEditingController.text.replaceAll(',', '')) ?? 0;

  int _getUsableBonusVotes() {
    final bonusStarCandy = _getMyBonusStarCandy();
    final remainingBonusUsage = _maxDailyVotes - _dailyVoteCount;

    if (remainingBonusUsage <= 0 || bonusStarCandy <= 0) {
      return 0;
    }

    // min(사용가능한 보너스 사탕, 오늘 남은 보너스 사용 한도)
    return bonusStarCandy < remainingBonusUsage
        ? bonusStarCandy
        : remainingBonusUsage;
  }

  // 입력된 투표수에 필요한 별사탕 총량 계산
  int _getRequiredStarCandyAmount() {
    final voteAmount = _getVoteAmount();
    if (voteAmount == 0) return 0;

    // 보너스 우선 사용
    final usableBonusVotes = _getUsableBonusVotes();

    if (voteAmount <= usableBonusVotes) {
      // 보너스만으로 충분한 경우 (1:1)
      return voteAmount;
    } else {
      // 보너스 + 일반 별사탕 조합
      final remainingVotes = voteAmount - usableBonusVotes;
      final regularStarCandyNeeded = remainingVotes * 30; // 일반 별사탕 30:1
      return usableBonusVotes + regularStarCandyNeeded;
    }
  }

  int _getMyStarCandy() {
    final userInfo = ref.read(userInfoProvider).value;
    return userInfo?.starCandy ?? 0;
  }

  int _getMyBonusStarCandy() {
    final userInfo = ref.read(userInfoProvider).value;
    return userInfo?.starCandyBonus ?? 0;
  }

  int _getTotalStarCandy() {
    return _getMyStarCandy() + _getMyBonusStarCandy();
  }

  // 사용 가능한 최대 투표수 계산
  int _getMaxPossibleVotes() {
    final usableBonusVotes = _getUsableBonusVotes();
    final regularStarCandy = _getMyStarCandy();
    final regularVotes = regularStarCandy ~/ 30; // 일반 별사탕은 30:1

    return usableBonusVotes + regularVotes;
  }

  void _validateVote() {
    final voteAmount = _getVoteAmount();
    final requiredStarCandy = _getRequiredStarCandyAmount();
    final totalStarCandy = _getTotalStarCandy();
    final maxPossibleVotes = _getMaxPossibleVotes();
    final usableBonusVotes = _getUsableBonusVotes(); // for logging

    logger.d(
      'JMA Voting Validation:\n'
      '  - Vote Amount: $voteAmount\n'
      '  - Usable Bonus Votes: $usableBonusVotes\n'
      '  - Max Possible Votes: $maxPossibleVotes\n'
      '  - Required Star Candy: $requiredStarCandy\n'
      '  - My Total Star Candy: $totalStarCandy\n'
      '  - Daily Vote Count: $_dailyVoteCount',
    );

    String validationMessage = '';
    bool canVote = false;

    if (voteAmount > 0) {
      // 최대 투표 가능 수량 초과 검증
      if (voteAmount > maxPossibleVotes) {
        canVote = false;
        validationMessage = AppLocalizations.of(
          context,
        ).jma_voting_max_votes_exceeded(maxPossibleVotes);
      }
      // 총 별사탕(보너스 포함) 부족 검증
      else if (requiredStarCandy > totalStarCandy) {
        canVote = false;
        final shortfall = requiredStarCandy - totalStarCandy;
        validationMessage = AppLocalizations.of(
          context,
        ).jma_voting_star_candy_shortage(shortfall);
      } else {
        canVote = true;
        validationMessage = '';
      }
    } else {
      canVote = false;
      validationMessage = '';
    }

    if (mounted) {
      setState(() {
        _canVote = canVote;
        _hasValue = voteAmount > 0;
        _validationMessage = validationMessage;
      });
    }
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
    final userId = ref.watch(
      userInfoProvider.select((value) => value.value?.id ?? ''),
    );

    // 키보드 여백은 "보이는가" 판단과 여백 축소에만 쓰고, 다이얼로그 높이
    // 계산에는 쓰지 않는다. AlertDialog/Dialog 가 viewInsets 와 insetPadding 을
    // 먼저 덜어낸 뒤 content 에 제약을 주므로, 아래 LayoutBuilder 가 받는
    // maxHeight 가 곧 "라우트가 실제로 남겨 준 높이"(세이프에어리어 포함)다.
    // 여기서 viewInsets 를 다시 빼면 키보드를 두 번 적용하게 된다.
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // PICNIC-2694: 이 여백은 "라우트가 조작부를 담을 수 있는 동안"만 디자인
    // 값(40/20)을 지킨다. 280 높이 창에서는 위아래 40 이 화면의 29% 를 빈
    // 여백으로 쓰면서 투표 버튼을 캡슐 밖으로 밀어냈다. 그런 창에서는 버튼이
    // 아니라 여백이 양보한다. 폭은 SizedBox 가 고정하므로 여기서 조작부
    // 높이를 미리 잴 수 있다.
    final routeHeight = math.max(
      0.0,
      mediaQuery.size.height - keyboardHeight - mediaQuery.padding.vertical,
    );
    final verticalInset = resolveVoteDialogVerticalInset(
      preferredInset: isKeyboardVisible ? 20 : 40,
      availableHeight: routeHeight,
      requiredBodyHeight: voteDialogRequiredRouteHeight(
        _essentialHeight(
          context,
          contentWidth: _contentWidth(resolveVoteDialogWidth()),
        ),
      ),
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
        insetPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: verticalInset,
        ),
        contentPadding: EdgeInsets.zero,
        content: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // 스크롤 알림을 처리하여 더 나은 사용자 경험 제공
            return false;
          },
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            // 폭을 카드와 같은 값으로 고정해 둔다. AlertDialog 는 자식을
            // IntrinsicWidth 로 감싸 intrinsic 폭을 묻는데 LayoutBuilder 는 그
            // 질문에 답할 수 없어(디버그 예외) 그대로는 쓸 수 없다. 타이트한
            // 폭 제약이 그 질의를 여기서 끊는다.
            child: SizedBox(
              width: resolveVoteDialogWidth(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final available = constraints.hasBoundedHeight
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height;
                  // 평소 모습(키보드 85% / 기본 75%)은 선호 높이로 그대로 두고,
                  // 라우트가 실제로 남겨 준 높이에서 카드 테두리와 숨김 스트립을
                  // 뺀 값을 상한으로 삼는다. 예전 계산은 카드 안쪽만 비율로
                  // 잘라서 그 두 가지 만큼 통째로 넘쳤다.
                  final preferred =
                      (MediaQuery.of(context).size.height - keyboardHeight) *
                      (isKeyboardVisible
                          ? _preferredHeightRatioWithKeyboard
                          : _preferredHeightRatio);
                  final fits = math.max(
                    0.0,
                    available - largePopupHiddenChromeHeight(),
                  );
                  // PICNIC-2694: 그 비율은 "평소 모습"일 뿐 조작부보다 우선하지
                  // 않는다. 라우트가 조작부를 담을 높이를 남겼다면 비율 때문에
                  // 입력·투표 버튼을 화면 밖으로 밀지 않는다.
                  final contentWidth = _contentWidth(constraints.maxWidth);
                  final essential = _essentialHeight(
                    context,
                    contentWidth: contentWidth,
                  );
                  final budget = math.min(math.max(preferred, essential), fits);
                  // 로고는 가장 먼저 양보한다 — 버튼 아래 자리를 지키는 것은
                  // 위쪽 초상화·잔액이 제 크기를 유지할 수 있을 때뿐이고,
                  // 그렇지 않으면 스크롤되는 상단 영역으로 내려가 접근만
                  // 유지한다.
                  final logoInTail =
                      !isKeyboardVisible &&
                      essential +
                              _tailLogoHeight() +
                              _decorationComfortHeight(
                                context,
                                contentWidth: contentWidth,
                                isKeyboardVisible: isKeyboardVisible,
                              ) <=
                          budget;
                  final shape = resolveVoteDialogShape(
                    bodyHeight: budget,
                    essentialHeight:
                        essential + (logoInTail ? _tailLogoHeight() : 0.0),
                    horizontalContentInset:
                        largePopupCardBorderWidth() + PicnicUi.horizontal(16),
                  );
                  return LargePopupWidget(
                    showCloseButton: false,
                    width: resolveVoteDialogWidth(),
                    cardBorderRadius: shape.cardBorderRadius,
                    content: Container(
                      constraints: BoxConstraints(
                        maxHeight: budget,
                        // 200 은 팝업이 찌부러지지 않게 지키는 하한이지만,
                        // 라우트가 그만큼도 남기지 않았다면(짧은 부모·세이프
                        // 에어리어) 있는 만큼으로 함께 내려야 한다.
                        minHeight: math.min(_minimumDialogBudget, budget),
                        maxWidth: resolveVoteDialogWidth(),
                      ),
                      child: VoteDialogBands(
                        mode: shape.mode,
                        decorationBuilder: (context, availableHeight) =>
                            _buildDecoration(
                              myStarCandy,
                              isKeyboardVisible,
                              availableHeight: availableHeight,
                              contentWidth: contentWidth,
                              withLogo: !isKeyboardVisible && !logoInTail,
                            ),
                        actions: _buildActions(isKeyboardVisible),
                        submit: _buildSubmit(userId),
                        tail: _buildTail(withLogo: logoInTail),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 스크롤로 양보하는 영역 — JMA 배지·아티스트·잔액·일일 한도·계산 안내·정책.
  ///
  /// PICNIC-2694 이전에는 이 내용이 입력보다 먼저 고정 높이를 차지해, 짧은
  /// 뷰포트에서 입력과 투표 버튼을 첫 화면 밖으로 밀어냈다. 이제는 조작부가
  /// 먼저 높이를 가져가고 남은 만큼만 쓴다.
  Widget _buildDecoration(
    int myStarCandy,
    bool isKeyboardVisible, {
    required double availableHeight,
    required double contentWidth,
    required bool withLogo,
  }) {
    final portrait = resolveVoteDialogPortraitSide(
      preferredSide: voteDialogDecorationExtent(_portraitLogicalSize),
      availableHeight: availableHeight,
      reservedHeight: _headerChromeHeight(context, isKeyboardVisible),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFixedHeader(isKeyboardVisible, portraitSide: portrait),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: PicnicUi.vertical(8)),
              _buildStarCandyInfo(myStarCandy),
              SizedBox(height: PicnicUi.vertical(8)),
              _buildDailyLimitInfo(),
              SizedBox(height: PicnicUi.vertical(8)),
              _buildCalculationSection(),
              _buildJmaInformation(),
              if (withLogo) ...[
                SizedBox(height: PicnicUi.vertical(8)),
                _buildJmaLogoImage(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 전체 사용 + 금액 입력 + 입력 바로 아래 안내. 스크롤 밖에 남는다.
  Widget _buildActions(bool isKeyboardVisible) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 전체 사용/입력/지우기는 각자 48 터치 영역을 품고 있어, 예전 20·36
          // 높이 행을 떼어놓던 간격이 그 안으로 들어갔다.
          _buildCheckAllOption(),
          _buildVoteAmountInput(context, isKeyboardVisible),
          SizedBox(height: PicnicUi.vertical(4)),
          _buildInputFeedback(),
        ],
      ),
    );
  }

  Widget _buildSubmit(String userId) {
    return Padding(
      padding: EdgeInsets.only(
        left: PicnicUi.horizontal(16),
        right: PicnicUi.horizontal(16),
        top: PicnicUi.vertical(8),
      ),
      child: _buildJmaVoteButton(userId),
    );
  }

  /// 버튼 아래 JMA 로고와 본문 하단 여백. 공간이 모자랄 때 가장 먼저 양보한다.
  Widget _buildTail({required bool withLogo}) {
    return Padding(
      padding: EdgeInsets.only(
        left: PicnicUi.horizontal(16),
        right: PicnicUi.horizontal(16),
        bottom: PicnicUi.vertical(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withLogo) ...[
            SizedBox(height: PicnicUi.vertical(8)),
            _buildJmaLogoImage(),
          ],
        ],
      ),
    );
  }

  /// 초상화의 기본 한 변.
  static const double _portraitLogicalSize = 60;

  /// 로고가 버튼 아래 자리를 지킬 때 더해지는 높이.
  double _tailLogoHeight() =>
      PicnicUi.vertical(8) + voteDialogDecorationExtent(_portraitLogicalSize);

  /// 헤더에서 초상화를 제외한 고정 요소(배지·여백·이름 두 줄)의 대략 높이.
  double _headerChromeHeight(BuildContext context, bool isKeyboardVisible) {
    final badge =
        measureVotingTextHeight(
          context,
          'Jupiter Music Awards',
          PicnicUi.text(size: 12, weight: FontWeight.w700),
          maxWidth: double.infinity,
        ) +
        PicnicUi.vertical(8) * 2;
    return PicnicUi.vertical(isKeyboardVisible ? 12 : 16) +
        badge +
        PicnicUi.vertical(isKeyboardVisible ? 4 : 8) +
        PicnicUi.vertical(isKeyboardVisible ? 4 : 8);
  }

  /// 압축하고 싶지 않은 상단 영역 — 헤더와 초상화, 그리고 잔액 패널 한 줄.
  ///
  /// 일일 한도·계산·정책은 일부러 뺀다. 계획이 스크롤로 보내도 된다고 한
  /// 부분이 그쪽이다.
  double _decorationComfortHeight(
    BuildContext context, {
    required double contentWidth,
    required bool isKeyboardVisible,
  }) {
    return _headerChromeHeight(context, isKeyboardVisible) +
        voteDialogDecorationExtent(_portraitLogicalSize) +
        PicnicUi.vertical(8) * 2 +
        PicnicUi.minimumTapTarget;
  }

  /// 카드 테두리와 좌우 여백을 뺀 조작부의 실제 폭.
  double _contentWidth(double width) => math.max(
    0.0,
    width - largePopupCardBorderWidth() * 2 - PicnicUi.horizontal(16) * 2,
  );

  /// 스크롤로 밀어낼 수 없는 조작부 높이 — 전체 사용 + 입력 + 안내 + 투표 버튼.
  ///
  /// 실제 자식 기준으로 잰다. 200% 글자에서 입력은 48 하한을, 버튼은 48 하한을
  /// 넘어서고, 입력 테두리 2 와 48 지우기 버튼도 높이에 포함된다.
  double _essentialHeight(
    BuildContext context, {
    required double contentWidth,
  }) {
    final checkAll = math.max(
      PicnicUi.minimumTapTarget,
      measureVotingTextHeight(
        context,
        AppLocalizations.of(context).jma_voting_use_all,
        PicnicUi.text(size: 14, weight: FontWeight.w500),
        maxWidth: math.max(0.0, contentWidth - 20 - PicnicUi.horizontal(4)),
      ),
    );
    final input =
        math.max(
          PicnicUi.minimumTapTarget,
          measureVotingTextHeight(
                context,
                '0',
                PicnicUi.text(size: 16, weight: FontWeight.w700),
                maxWidth: contentWidth,
              ) +
              PicnicUi.vertical(8) * 2,
        ) +
        _amountInputBorderWidth * 2;
    final button = math.max(
      PicnicUi.minimumTapTarget,
      measureVotingTextHeight(
            context,
            AppLocalizations.of(context).label_button_vote,
            PicnicUi.text(size: 18, weight: FontWeight.w700),
            // 활성 상태의 폭으로 잰다. 활성 버튼만 20 아이콘과 그 뒤 간격을
            // 라벨 앞에 두므로 라벨에 남는 폭이 더 좁고, 그래서 같은 문구가
            // 한 줄 더 감긴다 — 태국어·버마어는 393 폭·기본 배율에서도 26~52
            // 만큼 더 높았다. 비활성 폭으로 재면 그 상태를 과소 예산해
            // actionsPinned 를 잘못 골라 RenderFlex 가 넘친다.
            maxWidth: _submitLabelMaxWidth(),
          ) +
          PicnicUi.vertical(4) * 2,
    );
    return checkAll +
        input +
        PicnicUi.vertical(4) +
        _inputFeedbackHeight(context, contentWidth: contentWidth) +
        PicnicUi.vertical(8) +
        button +
        PicnicUi.vertical(16);
  }

  /// 활성 투표 버튼이 라벨에 남겨 주는 폭 — 버튼 안쪽에서 아이콘과 간격을 뺀 값.
  double _submitLabelMaxWidth() => math.max(
    0.0,
    voteDialogCardExtent(172) -
        PicnicUi.horizontal(12) * 2 -
        _submitIconSide -
        PicnicUi.horizontal(8),
  );

  /// 입력 바로 아래 한 줄의 높이 — 유효성 안내 또는 투표 예정 안내.
  ///
  /// 둘 다 조작부 밴드 안에 있어 스크롤로 밀려나지 않으므로, 예산에도 들어가야
  /// 한다. 예전에는 이 줄이 장식 밴드에 있어 예산에서 빠졌고, 짧은 화면에서는
  /// 아예 보이지 않았다.
  double _inputFeedbackHeight(
    BuildContext context, {
    required double contentWidth,
  }) {
    if (_validationMessage.isNotEmpty) {
      final textWidth = math.max(
        0.0,
        contentWidth -
            PicnicUi.horizontal(12) * 2 -
            _validationIconSide -
            PicnicUi.horizontal(8),
      );
      return measureVotingTextHeight(
            context,
            _validationMessage,
            PicnicUi.text(size: 12, weight: FontWeight.w500),
            maxWidth: textWidth,
          ) +
          PicnicUi.vertical(8) * 2 +
          _validationBorderWidth * 2;
    }
    final hint = _voteHintText();
    if (hint == null) return 0;
    return measureVotingTextHeight(
      context,
      hint,
      PicnicUi.text(size: 12, weight: FontWeight.w600),
      maxWidth: math.max(0.0, contentWidth - PicnicUi.horizontal(24)),
    );
  }

  /// 입력 테두리 폭 — 위아래 양쪽에서 높이에 더해진다.
  static const double _amountInputBorderWidth = 2;

  /// 활성 투표 버튼이 라벨 앞에 두는 아이콘의 한 변.
  static const double _submitIconSide = 20;

  /// 유효성 안내 줄의 아이콘 박스 한 변 — 16 글리프에 좌우 2 패딩.
  static const double _validationIconSide = 20;

  /// 유효성 안내 줄의 테두리 폭.
  static const double _validationBorderWidth = 1;

  Widget _buildJmaHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(16),
        vertical: PicnicUi.vertical(8),
      ),
      decoration: BoxDecoration(
        gradient: commonGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20, // 18 → 20으로 복원
            height: 20, // 18 → 20으로 복원
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                package: 'picnic_lib',
                'assets/icons/store/jma.png',
                width: 18, // 16 → 18로 복원
                height: 18, // 16 → 18로 복원
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: PicnicUi.horizontal(8)),
          // 기존 자간(1.5)이 이 한 줄을 좁은 화면에서 넘치게 만들었다. 자간 0
          // 토큰으로 되돌리고, 더 좁은 화면을 위해 줄어들 수 있게 한다.
          //
          // 한 줄 + ellipsis 는 320 폭 / 200% 에서 대회 이름을 잘라냈다. 배지는
          // 고정 높이가 아니므로 자연스럽게 줄바꿈해 전체 이름을 유지한다.
          Flexible(
            child: Text(
              'Jupiter Music Awards',
              softWrap: true,
              style: PicnicUi.text(
                size: 12,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJmaLogoImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/partners/jma.png',
          package: 'picnic_lib',
          width: voteDialogDecorationExtent(120),
          height: voteDialogDecorationExtent(60),
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildVoteAmountInput(BuildContext context, bool isKeyboardVisible) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialRender) {
        _isInitialRender = false;
      }

      // 포커스가 있을 때 텍스트 필드가 보이도록 적절한 위치로 스크롤
      if (_focusNode.hasFocus && isKeyboardVisible) {
        final RenderObject? renderObject = _inputFieldKey.currentContext
            ?.findRenderObject();
        if (renderObject != null) {
          Scrollable.ensureVisible(
            _inputFieldKey.currentContext!,
            alignment: 0.4, // 고정된 정렬 값으로 더 예측 가능한 스크롤
            duration: const Duration(milliseconds: 300), // 더 빠른 애니메이션
            curve: Curves.easeOutCubic, // 더 부드러운 곡선
          );
        }
      }
    });

    final hasError = !_canVote && _hasValue;
    final frameColor = hasError ? AppColors.statusError : PicnicUi.actionColor;

    return Container(
      key: _inputFieldKey,
      // 36 은 최소 터치 영역에 못 미치고 큰 글자에서 입력값을 잘라냈다.
      constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
      decoration: BoxDecoration(
        border: Border.all(color: frameColor, width: 2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: frameColor.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
                  border: InputBorder.none,
                  focusColor: PicnicUi.actionColor,
                  fillColor: Colors.white,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: PicnicUi.horizontal(24),
                    vertical: PicnicUi.vertical(8),
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

                    final starCandyAmount = int.parse(newText);
                    if (starCandyAmount == 0) return oldValue;

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
                style: PicnicUi.text(
                  size: 16,
                  weight: FontWeight.w700,
                  color: PicnicUi.actionColor,
                ),
              ),
            ),
          ),
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildJmaInformation() {
    final policyLineStyle = PicnicUi.text(size: 12, color: PicnicUi.ink);

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _isPolicyExpanded = !_isPolicyExpanded;
            });
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: PicnicUi.minimumTapTarget,
            ),
            child: Center(
              child: Text(
                AppLocalizations.of(context).label_button_view_policy,
                style: PicnicUi.text(
                  size: 12,
                  weight: FontWeight.w500,
                  color: PicnicUi.secondaryText,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
        if (_isPolicyExpanded)
          Padding(
            padding: EdgeInsets.symmetric(vertical: PicnicUi.vertical(8)),
            child: Column(
              children: AppLocalizations.of(context).jma_voting_info_text
                  .split('\n')
                  .map((line) {
                    final text = line.startsWith('-')
                        ? line.substring(1).trim()
                        : line.trim();
                    if (text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.only(bottom: PicnicUi.vertical(4)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: policyLineStyle),
                          Expanded(child: Text(text, style: policyLineStyle)),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
      ],
    );
  }

  // 아티스트 정보 (가로 레이아웃)
  Widget _buildArtistInfoRow(bool isKeyboardVisible, double portraitSide) {
    // 아티스트 이미지 URL을 가져오기
    String? imageUrl;
    if ((widget.voteItemModel.artist?.id ?? 0) != 0) {
      imageUrl = widget.voteItemModel.artist?.image;
    } else {
      imageUrl = widget.voteItemModel.artistGroup?.image;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 아티스트 이미지 - 키보드가 나올 때 숨김
        if (!isKeyboardVisible) ...[
          Container(
            width: portraitSide,
            height: portraitSide,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary500, width: 2),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? PicnicCachedNetworkImage(
                      imageUrl: imageUrl,
                      width: portraitSide,
                      height: portraitSide,
                      fit: BoxFit.cover,
                      placeholder: VoteDetailPortraitCachePlaceholder(
                        imageUrl: imageUrl,
                      ),
                      lazyLoadingStrategy: LazyLoadingStrategy.none,
                      priority: ImagePriority.high,
                    )
                  : Container(
                      width: portraitSide,
                      height: portraitSide,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey200,
                      ),
                      child: Icon(
                        Icons.person,
                        size: portraitSide / 2,
                        color: AppColors.grey500,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12), // 10 → 12로 복원
        ],

        // 아티스트 이름 정보
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: isKeyboardVisible
                ? CrossAxisAlignment
                      .center // 키보드 시 중앙 정렬
                : CrossAxisAlignment.start, // 평상시 왼쪽 정렬
            children: [
              // 메인 아티스트 이름
              Text(
                getLocaleTextFromJson(
                  (widget.voteItemModel.artist?.id ?? 0) != 0
                      ? widget.voteItemModel.artist?.name ?? {}
                      : widget.voteItemModel.artistGroup?.name ?? {},
                ),
                style: PicnicUi.text(size: 14, weight: FontWeight.w700),
                textAlign: isKeyboardVisible
                    ? TextAlign
                          .center // 키보드 시 중앙 정렬
                    : TextAlign.start, // 평상시 왼쪽 정렬
              ),

              // 그룹 이름 (솔로 아티스트의 경우)
              if ((widget.voteItemModel.artist?.id ?? 0) != 0 &&
                  widget.voteItemModel.artist?.artistGroup?.name != null) ...[
                SizedBox(height: 2),
                Text(
                  getLocaleTextFromJson(
                    widget.voteItemModel.artist!.artistGroup!.name,
                  ),
                  style: PicnicUi.text(size: 12, color: PicnicUi.secondaryText),
                  textAlign: isKeyboardVisible
                      ? TextAlign
                            .center // 키보드 시 중앙 정렬
                      : TextAlign.start, // 평상시 왼쪽 정렬
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarCandyInfo(int myStarCandy) {
    final bonusStarCandy = _getMyBonusStarCandy();
    final usableStarCandy = _getMyStarCandy() ~/ 30; // 기본 별사탕 기준
    final usableBonusVotes = _getUsableBonusVotes();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(8),
        vertical: PicnicUi.vertical(4),
      ),
      decoration: PicnicUi.surfaceDecoration(
        radius: 8,
        color: AppColors.grey100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 나의 별사탕 섹션
          Text(
            AppLocalizations.of(context).jma_voting_my_star_candy,
            style: PicnicUi.text(size: 12, weight: FontWeight.w700),
          ),

          // 보유량 표시
          //
          // 320 폭 / 200% 에서는 두 묶음이 한 줄에 들어가지 않아 Row 가 20px
          // 넘쳤다. 자리가 있으면 예전과 같은 한 줄 양끝 정렬이고, 모자라면
          // 다음 줄로 자연스럽게 넘어간다.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: PicnicUi.horizontal(8),
            runSpacing: PicnicUi.vertical(4),
            children: [
              // 기본 별사탕
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/star_100.png',
                    width: 40,
                    height: 40,
                  ),
                  SizedBox(width: PicnicUi.horizontal(4)),
                  Text(
                    formatNumberWithComma(myStarCandy),
                    style: PicnicUi.text(
                      size: 12,
                      weight: FontWeight.w700,
                      color: PicnicUi.secondaryText,
                    ),
                  ),
                ],
              ),

              // 보너스 별사탕
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/bonus.png',
                    width: 18,
                    height: 18,
                  ),
                  SizedBox(width: PicnicUi.horizontal(4)),
                  Text(
                    '${formatNumberWithComma(bonusStarCandy)}개',
                    style: PicnicUi.text(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 화살표와 구분선
          Stack(
            alignment: Alignment.center,
            children: [
              const Divider(color: AppColors.grey300, thickness: 1),
              Container(
                color: AppColors.grey100,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.keyboard_double_arrow_down,
                  color: AppColors.primary500.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
            ],
          ),

          // 사용가능 별사탕 섹션
          Text(
            AppLocalizations.of(context).jma_voting_usable_jma_votes,
            style: PicnicUi.text(
              size: 12,
              weight: FontWeight.w700,
              color: PicnicUi.actionColor,
            ),
          ),
          SizedBox(height: PicnicUi.vertical(4)),

          // 사용 가능량들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 별사탕 (30의 배수)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: PicnicUi.horizontal(8)),
                  Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/jma.png',
                    width: 22,
                    height: 22,
                  ),
                  SizedBox(width: PicnicUi.horizontal(12)),
                  Text(
                    formatNumberWithComma(usableStarCandy),
                    style: PicnicUi.text(
                      size: 12,
                      weight: FontWeight.w700,
                      color: PicnicUi.actionColor,
                    ),
                  ),
                ],
              ),

              // 보너스 (하루 5개 제한)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/bonus.png',
                    width: 18,
                    height: 18,
                  ),
                  SizedBox(width: PicnicUi.horizontal(4)),
                  Text(
                    _isDailyVoteCountLoaded
                        ? '${formatNumberWithComma(usableBonusVotes)}개'
                        : '-',
                    style: PicnicUi.text(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLimitInfo() {
    final remainingVotes = _maxDailyVotes - _dailyVoteCount;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(8),
        vertical: PicnicUi.vertical(4),
      ),
      margin: EdgeInsets.only(top: PicnicUi.vertical(4)),
      decoration: BoxDecoration(
        color: remainingVotes > 0 ? Colors.blue.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: remainingVotes > 0
              ? Colors.blue.shade200
              : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            remainingVotes > 0 ? Icons.access_time : Icons.warning,
            color: remainingVotes > 0
                ? Colors.blue.shade600
                : Colors.red.shade600,
            size: 16,
          ),
          SizedBox(width: PicnicUi.horizontal(8)),
          Expanded(
            child: Text(
              remainingVotes > 0
                  ? AppLocalizations.of(
                      context,
                    ).jma_voting_daily_limit_remaining(
                      _isDailyVoteCountLoaded ? _maxDailyVotes : 0,
                      _isDailyVoteCountLoaded ? remainingVotes : 0,
                    )
                  : AppLocalizations.of(
                      context,
                    ).jma_voting_daily_limit_exhausted,
              style: PicnicUi.text(
                size: 12,
                weight: FontWeight.w600,
                color: remainingVotes > 0
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 30:1 환산 안내. 유효성 안내는 PICNIC-2694 에서 입력 바로 아래 조작부
  /// 밴드로 옮겼으므로 여기 남지 않는다 — 짧은 화면에서 이 패널은 장식과 함께
  /// 스크롤 밖으로 나가고, 그때 입력이 왜 빨간지 설명할 것이 사라졌다.
  Widget _buildCalculationSection() {
    final voteAmount = _getVoteAmount();
    if (voteAmount == 0 || _validationMessage.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final userRole = ref.watch(userInfoProvider).value?.isAdmin;
    final isAdmin = userRole == true;

    // 어드민 포털일 때만 계산 결과 표시
    if (isAdmin) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(8)),
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(12),
          vertical: PicnicUi.vertical(8),
        ),
        decoration: BoxDecoration(
          color: AppColors.primary500.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.calculate_rounded,
                size: 16,
                color: PicnicUi.actionColor,
              ),
            ),
            SizedBox(width: PicnicUi.horizontal(4)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: PicnicUi.horizontal(4),
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: PicnicUi.actionColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Admin',
                style: PicnicUi.text(
                  size: 10,
                  weight: FontWeight.w600,
                  color: PicnicUi.onActionColor,
                ),
              ),
            ),
            SizedBox(width: PicnicUi.horizontal(8)),
            Expanded(
              child: Text(
                _getCalculationResultMessage(),
                style: PicnicUi.text(
                  size: 12,
                  weight: FontWeight.w500,
                  color: PicnicUi.actionColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _getCalculationResultMessage() {
    final voteAmount = _getVoteAmount();
    final usableBonusVotes = _getUsableBonusVotes();

    if (voteAmount <= usableBonusVotes) {
      // 보너스만으로 충분한 경우
      return "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(voteAmount)}개";
    } else if (usableBonusVotes > 0) {
      // 보너스 + 일반 별사탕 조합
      final regularStarCandyNeeded = (voteAmount - usableBonusVotes) * 30;
      return "JMA ${formatNumberWithComma(voteAmount)}투표 = 보너스 ${formatNumberWithComma(usableBonusVotes)}개 + 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
    } else {
      // 일반 별사탕만 사용
      final regularStarCandyNeeded = voteAmount * 30;
      return "JMA ${formatNumberWithComma(voteAmount)}투표 = 별사탕 ${formatNumberWithComma(regularStarCandyNeeded)}개";
    }
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
              // 최대 투표 가능 수량 계산
              final maxVotes = _getMaxPossibleVotes();
              _textEditingController.text = formatNumberWithComma(maxVotes);
            } else {
              _textEditingController.clear();
            }
          });
        }
        _validateVote();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _checkAll ? Icons.check_box : Icons.check_box_outline_blank,
              color: _checkAll ? PicnicUi.actionColor : PicnicUi.secondaryText,
              size: 20,
            ),
            SizedBox(width: PicnicUi.horizontal(4)),
            Flexible(
              child: Text(
                AppLocalizations.of(context).jma_voting_use_all,
                style: PicnicUi.text(
                  size: 14,
                  weight: FontWeight.w500,
                  color: _checkAll
                      ? PicnicUi.actionColor
                      : PicnicUi.secondaryText,
                ),
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
      // 글리프는 20 그대로 두고, 감싸는 영역만 최소 터치 크기로 키운다.
      child: SizedBox(
        width: PicnicUi.minimumTapTarget,
        height: PicnicUi.minimumTapTarget,
        child: Center(
          child: Icon(
            Icons.clear,
            color: _hasValue ? PicnicUi.actionColor : PicnicUi.secondaryText,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// 입력값이 왜 투표로 이어지지 않는지 — 입력 바로 아래, 조작부 밴드 안.
  ///
  /// PICNIC-2694 이전에는 이 문구가 초상화·잔액·일일 한도 뒤의 장식 스크롤
  /// 안에 있었다. 851x393 처럼 짧은 화면에서는 그 스크롤이 첫 화면 밖으로
  /// 나가, 사용자는 빨간 테두리와 비활성 버튼만 보고 이유는 볼 수 없었다.
  /// 입력의 [Scrollable.ensureVisible] 도 그 스크롤은 움직이지 못했다.
  Widget _buildInputFeedback() {
    if (_validationMessage.isNotEmpty) return _buildValidationMessage();
    return _buildErrorMessage();
  }

  /// 유효성 안내 줄.
  ///
  /// [Semantics.liveRegion] 으로 스크린 리더가 값이 바뀔 때 읽게 한다.
  /// [InputDecoration.errorText] 를 쓰지 않는 이유는 이 입력이
  /// `isCollapsed` + `InputBorder.none` 커스텀 프레임이라, errorText 가
  /// 머티리얼 자체 에러 UI 를 필드 안에 하나 더 그려 높이 계산과 프레임 색이
  /// 이중으로 갈리기 때문이다.
  Widget _buildValidationMessage() {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(12),
          vertical: PicnicUi.vertical(8),
        ),
        decoration: BoxDecoration(
          color: AppColors.statusError.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.statusError.withValues(alpha: 0.2),
            width: _validationBorderWidth,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.statusError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 16,
                color: AppColors.statusError,
              ),
            ),
            SizedBox(width: PicnicUi.horizontal(8)),
            Expanded(
              child: Text(
                _validationMessage,
                style: PicnicUi.text(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.statusError,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 투표 예정 안내 문구. 측정과 렌더가 같은 문자열을 쓰도록 한곳에 둔다.
  String? _voteHintText() {
    if (_canVote || !_hasValue || _validationMessage.isNotEmpty) return null;
    final voteAmount = _getVoteAmount();
    if (voteAmount <= 0) return null;
    return '${formatNumberWithComma(voteAmount)}개의 투표를 진행합니다.';
  }

  Widget _buildErrorMessage() {
    final hint = _voteHintText();
    if (hint == null) return const SizedBox(height: 0);
    return Container(
      padding: EdgeInsets.only(left: PicnicUi.horizontal(24)),
      width: double.infinity,
      child: Text(
        hint,
        style: PicnicUi.text(
          size: 12,
          weight: FontWeight.w600,
          color: PicnicUi.actionColor,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildJmaVoteButton(String userId) {
    final isEnabled = _canVote && !_isVoting; // 투표 중이면 버튼 비활성화
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? () => _handleVote(userId) : null,
      child: Container(
        width: voteDialogCardExtent(172),
        // 44 는 최소 터치 크기 미만이었다.
        constraints: const BoxConstraints(minHeight: PicnicUi.minimumTapTarget),
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(12),
          vertical: PicnicUi.vertical(4),
        ),
        decoration: BoxDecoration(
          gradient: (_isVoting || isEnabled) ? commonGradient : null,
          color: (_isVoting || isEnabled) ? null : AppColors.grey300,
          borderRadius: BorderRadius.circular(24),
          boxShadow: (_isVoting || isEnabled)
              ? [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.secondary500.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: _isVoting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: SmallPulseLoadingIndicator(),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isEnabled) ...[
                    Icon(
                      Icons.how_to_vote,
                      color: Colors.white,
                      // _submitLabelMaxWidth 가 빼는 폭과 같은 값이어야 한다.
                      size: _submitIconSide,
                    ),
                    SizedBox(width: PicnicUi.horizontal(8)),
                  ],
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context).label_button_vote,
                      textAlign: TextAlign.center,
                      style: PicnicUi.text(
                        size: 18,
                        weight: FontWeight.w700,
                        color: (_isVoting || isEnabled)
                            ? Colors.white
                            : PicnicUi.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleVote(String userId) async {
    // 이미 투표 진행 중이면 무시 (중복 클릭 방지)
    if (_isVoting) return;

    final voteAmount = _getVoteAmount();

    if (voteAmount == 0) {
      showSimpleDialog(
        title: AppLocalizations.of(context).dialog_title_vote_fail,
        content: AppLocalizations.of(context).jma_voting_input_amount,
        onOk: () {},
      );
      return;
    }

    // 유효성 검증은 이미 _validateVote()에서 완료됨
    if (!_canVote) {
      showSimpleDialog(
        title: AppLocalizations.of(context).dialog_title_vote_fail,
        content: _validationMessage,
        onOk: () {},
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (await showWithdrawalBlockedDialog(context: context, ref: ref)) {
      return;
    }

    // 투표 시작 - 버튼 비활성화
    setState(() => _isVoting = true);

    _loadingKey.currentState?.show();

    // 보너스 사용 계산
    final usableBonusVotes = _getUsableBonusVotes();

    final bonusVotesUsed = voteAmount <= usableBonusVotes
        ? voteAmount
        : usableBonusVotes;

    // 교환과 투표를 함께 수행
    await _performExchangeAndVoting(voteAmount, userId, bonusVotesUsed);
  }

  // 교환과 투표를 함께 수행하는 함수
  Future<void> _performExchangeAndVoting(
    int voteAmount,
    String userId,
    int bonusVotesUsed,
  ) async {
    try {
      // 투표 수행 (교환 로직이 내장됨)
      await _performVoting(voteAmount, userId, bonusVotesUsed);
    } catch (e) {
      logger.e('Voting error', error: e);
      _loadingKey.currentState?.hide();

      // 투표 실패 시 버튼 다시 활성화
      if (mounted) {
        setState(() => _isVoting = false);
      }

      if (mounted) {
        showSimpleDialog(
          type: DialogType.error,
          title: AppLocalizations.of(context).jma_voting_exchange_failed_title,
          content: AppLocalizations.of(context).jma_voting_exchange_failed,
          onOk: () {},
        );
      }
    }
  }

  // 429 응답 시 자동 재시도하는 JMA 투표 API 호출
  Future<dynamic> _invokeJmaVotingWithRetry({
    required int voteAmount,
    required String userId,
    required int starCandyUsage,
    required int starCandyBonusUsage,
    int retryCount = 0,
  }) async {
    return JmaVotingHelper.invokeJmaVotingWithRetry(
      voteId: widget.voteModel.id,
      voteItemId: widget.voteItemModel.id,
      amount: voteAmount,
      userId: userId,
      starCandyUsage: starCandyUsage,
      starCandyBonusUsage: starCandyBonusUsage,
      retryCount: retryCount,
      isMounted: () => mounted,
    );
  }

  /// 보너스 캔디 우선 사용 로직으로 사용량 계산 (실제 별사탕 개수 기준)
  Map<String, int> _calculateUsage(int totalStarCandyAmount) {
    final voteAmount = _getVoteAmount();
    final usableBonusVotes = _getUsableBonusVotes();

    int starCandyUsage = 0; // 일반 별사탕 사용량 (개수)
    int starCandyBonusUsage = 0; // 보너스 별사탕 사용량 (개수)

    if (voteAmount <= usableBonusVotes) {
      // 보너스 별사탕만으로 충분한 경우
      starCandyBonusUsage = voteAmount; // 보너스는 1:1 비율
      starCandyUsage = 0;
    } else {
      // 보너스 별사탕을 모두 사용하고 일반 별사탕도 사용
      starCandyBonusUsage = usableBonusVotes; // 보너스는 1:1 비율
      final regularVotes = voteAmount - usableBonusVotes;
      starCandyUsage = regularVotes * 30; // 일반 별사탕은 30:1 비율
    }

    logger.d(
      'JMA Voting Usage Calculation:\n'
      '  - Vote Amount: $voteAmount\n'
      '  - Usable Bonus Votes: $usableBonusVotes\n'
      '  - Star Candy Usage: $starCandyUsage\n'
      '  - Bonus Star Candy Usage: $starCandyBonusUsage',
    );

    return {
      'star_candy_usage': starCandyUsage, // 실제 별사탕 개수
      'star_candy_bonus_usage': starCandyBonusUsage, // 실제 보너스 별사탕 개수
    };
  }

  Future<void> _performVoting(
    int voteAmount,
    String userId,
    int bonusVotesUsed,
  ) async {
    try {
      // PIC에서는 JMA 보팅이 지원되지 않음
      if (widget.portalType == VotePortal.pic) {
        throw Exception('JMA voting is not supported for PIC');
      }

      // 필요한 별사탕 계산
      final requiredStarCandy = _getRequiredStarCandyAmount();
      final usage = _calculateUsage(requiredStarCandy);

      // 새로운 jma-voting-v2 엣지 함수 사용 (429 시 1회 자동 재시도)
      final response = await _invokeJmaVotingWithRetry(
        voteAmount: voteAmount,
        userId: userId,
        starCandyUsage: usage['star_candy_usage']!,
        starCandyBonusUsage: usage['star_candy_bonus_usage']!,
      );

      if (response.status != 200) {
        // Edge function에서 일일 제한 오류 처리 (retryable이 아닌 429만)
        if (response.status == 429) {
          final data = response.data as Map<String, dynamic>?;
          final isRetryable = data?['retryable'] == true;

          // retryable이 false인 경우에만 일일 제한 에러로 처리
          if (!isRetryable) {
            _loadingKey.currentState?.hide();
            // 투표 실패 시 버튼 다시 활성화
            if (mounted) {
              setState(() => _isVoting = false);
            }
            if (mounted) {
              showSimpleDialog(
                type: DialogType.error,
                title: AppLocalizations.of(
                  context,
                ).jma_voting_daily_limit_title,
                content: AppLocalizations.of(
                  context,
                ).jma_voting_daily_limit_error,
                onOk: () {},
              );
            }
            return;
          }
        }
        throw Exception('Failed to vote');
      }

      // GA4 vote (스펙 §2-10). status==200 을 통과한 뒤에만 — 일일 제한(429)과
      // 그 외 실패는 위에서 반환/throw 되어 여기 도달하지 못한다.
      // JMA 는 보너스가 1:1, 일반 별사탕이 30:1 이라 투표 수와 소모량이 다르다.
      // 스펙의 reward_amount 는 "사용된 재화 수량"이므로 투표 수가 아니라
      // _calculateUsage 가 낸 실제 소모량을 그대로 보낸다.
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

      await ref.read(userInfoProvider.notifier).getUserProfiles();

      ref
          .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
          .fetch(voteId: widget.voteModel.id);

      // 투표 성공 시 일일 카운트 새로고침
      await _loadDailyVoteCount();

      _loadingKey.currentState?.hide();

      if (!mounted) return;

      // navigatorKey context를 pop 전에 캡처 (dialog dispose 후에도 유효)
      final navContext = navigatorKey.currentContext;

      Navigator.of(context).pop();

      await Future.delayed(const Duration(milliseconds: 100));

      if (navContext == null || !navContext.mounted) return;

      // Edge Function 응답 데이터를 안전하게 처리
      final responseData = response.data as Map<String, dynamic>? ?? {};
      final result = Map<String, dynamic>.from(responseData);

      // 필수 필드들이 없으면 기본값 설정
      result['votePickId'] = responseData['votePickId'] ?? '';
      result['updatedAt'] =
          responseData['updatedAt'] ?? DateTime.now().toIso8601String();
      result['existingVoteTotal'] = responseData['existingVoteTotal'] ?? 0;
      result['addedVoteTotal'] = responseData['addedVoteTotal'] ?? 0;
      result['updatedVoteTotal'] = responseData['updatedVoteTotal'] ?? 0;

      showVotingCompleteDialog(
        context: navContext,
        voteModel: widget.voteModel,
        voteItemModel: widget.voteItemModel,
        result: result,
      );
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      _loadingKey.currentState?.hide();

      // 투표 실패 시 버튼 다시 활성화
      if (mounted) {
        setState(() => _isVoting = false);
      }

      Navigator.of(context).pop();

      _showVotingFailDialog();
    }
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

  // 고정 헤더 - JMA 제목 + 아티스트 정보
  Widget _buildFixedHeader(
    bool isKeyboardVisible, {
    required double portraitSide,
  }) {
    return Container(
      padding: EdgeInsets.only(
        top: isKeyboardVisible
            ? PicnicUi.vertical(12)
            : PicnicUi.vertical(16), // 키보드 시 패딩 줄임
        left: PicnicUi.horizontal(16),
        right: PicnicUi.horizontal(16),
        bottom: isKeyboardVisible
            ? PicnicUi.vertical(4)
            : PicnicUi.vertical(8), // 키보드 시 패딩 줄임
      ),
      child: Column(
        children: [
          _buildJmaHeader(),
          SizedBox(
            height: isKeyboardVisible
                ? PicnicUi.vertical(4)
                : PicnicUi.vertical(8),
          ), // 키보드 시 간격 줄임
          _buildArtistInfoRow(isKeyboardVisible, portraitSide),
        ],
      ),
    );
  }
}
