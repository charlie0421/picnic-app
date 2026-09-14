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
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_widgets.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/common_gradient.dart';

/// 라우트가 아무리 좁아도 팝업 본문을 이 아래로는 줄이지 않는다.
const double _minimumDialogBudget = 200;

/// 고정 헤더·푸터를 유지할 수 있는 최소 본문 예산. 이보다 좁으면 헤더/푸터만으로
/// 예산을 넘겨 스크롤 영역이 0 이 되므로 전체 스크롤로 전환한다.
const double _fixedChromeMinimumBudget = 360;

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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

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
          vertical: isKeyboardVisible ? 20 : 40,
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
              width: defaultLargePopupWidth(),
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
                      (isKeyboardVisible ? 0.85 : 0.75);
                  final fits = math.max(
                    0.0,
                    available - largePopupHiddenChromeHeight(),
                  );
                  final budget = math.min(preferred, fits);
                  // 큰 글자나 아주 낮은 뷰포트에서는 고정 헤더/푸터만으로도
                  // 예산을 넘길 수 있다. 그때만 전체를 한 번에 스크롤하고,
                  // 평소에는 기존 고정 헤더 + 스크롤 본문 + 고정 푸터를 쓴다.
                  final compactChrome =
                      budget < _fixedChromeMinimumBudget ||
                      MediaQuery.textScalerOf(context).scale(14) > 18.2;
                  return LargePopupWidget(
                    showCloseButton: false,
                    content: Container(
                      constraints: BoxConstraints(
                        maxHeight: budget,
                        // 200 은 팝업이 찌부러지지 않게 지키는 하한이지만,
                        // 라우트가 그만큼도 남기지 않았다면(짧은 부모·세이프
                        // 에어리어) 있는 만큼으로 함께 내려야 한다.
                        minHeight: math.min(_minimumDialogBudget, budget),
                        maxWidth: MediaQuery.of(context).size.width - 32.w,
                      ),
                      child: compactChrome
                          ? _buildAllScrollBody(
                              myStarCandy,
                              userId,
                              isKeyboardVisible,
                            )
                          : _buildFixedChromeBody(
                              myStarCandy,
                              userId,
                              isKeyboardVisible,
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

  /// 기존 구성: 고정 헤더 + 스크롤 본문 + 고정 푸터.
  Widget _buildFixedChromeBody(
    int myStarCandy,
    String userId,
    bool isKeyboardVisible,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 고정 헤더 - JMA 제목 + 아티스트 정보
        _buildFixedHeader(isKeyboardVisible),

        // 스크롤 가능한 중간 영역
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _buildScrollableMiddle(myStarCandy, isKeyboardVisible),
          ),
        ),

        // 고정 푸터 - 투표 버튼 + JMA 로고 (키보드 시 로고 숨김)
        _buildFixedFooter(userId, isKeyboardVisible),
      ],
    );
  }

  /// 예산이 헤더/푸터조차 담지 못할 때만 쓰는 구성 — 같은 순서, 같은 조각을
  /// 하나의 스크롤 안에 넣어 무엇도 잘리지 않게 한다.
  Widget _buildAllScrollBody(
    int myStarCandy,
    String userId,
    bool isKeyboardVisible,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFixedHeader(isKeyboardVisible),
          _buildScrollableMiddle(myStarCandy, isKeyboardVisible),
          _buildFixedFooter(userId, isKeyboardVisible),
        ],
      ),
    );
  }

  Widget _buildScrollableMiddle(int myStarCandy, bool isKeyboardVisible) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: PicnicUi.vertical(8)),
          _buildStarCandyInfo(myStarCandy),
          SizedBox(height: PicnicUi.vertical(8)),
          _buildVoteInputSection(isKeyboardVisible),
        ],
      ),
    );
  }

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
          width: 120.w, // 60 → 120으로 복원
          height: 60.w, // 30 → 60으로 복원
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
  Widget _buildArtistInfoRow(bool isKeyboardVisible) {
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
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary500, width: 2),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? PicnicCachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                      placeholder: VoteDetailPortraitCachePlaceholder(
                        imageUrl: imageUrl,
                      ),
                      lazyLoadingStrategy: LazyLoadingStrategy.none,
                      priority: ImagePriority.high,
                    )
                  : Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey200,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 30.w,
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

  Widget _buildCalculationAndErrorSection() {
    final voteAmount = _getVoteAmount();
    if (voteAmount == 0 || _validationMessage.isNotEmpty) {
      // 에러 메시지가 있거나 투표량이 0이면 계산 결과를 보여주지 않음
      if (_validationMessage.isNotEmpty) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(8)),
          padding: EdgeInsets.symmetric(
            horizontal: PicnicUi.horizontal(12),
            vertical: PicnicUi.vertical(8),
          ),
          decoration: BoxDecoration(
            color: AppColors.statusError.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.statusError.withValues(alpha: 0.2),
              width: 1,
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
        );
      }
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

  Widget _buildErrorMessage() {
    if (!_canVote && _hasValue && _validationMessage.isEmpty) {
      // 투표 안내 메시지
      final voteAmount = _getVoteAmount();

      if (voteAmount > 0) {
        return Container(
          padding: EdgeInsets.only(left: PicnicUi.horizontal(24)),
          width: double.infinity,
          child: Text(
            '${formatNumberWithComma(voteAmount)}개의 투표를 진행합니다.',
            style: PicnicUi.text(
              size: 12,
              weight: FontWeight.w600,
              color: PicnicUi.actionColor,
            ),
            textAlign: TextAlign.left,
          ),
        );
      }
    }
    return const SizedBox(height: 0);
  }

  Widget _buildJmaVoteButton(String userId) {
    final isEnabled = _canVote && !_isVoting; // 투표 중이면 버튼 비활성화
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? () => _handleVote(userId) : null,
      child: Container(
        width: 172.w,
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
                      size: 20, // 18 → 20으로 복원
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
  Widget _buildFixedHeader(bool isKeyboardVisible) {
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
          _buildArtistInfoRow(isKeyboardVisible),
        ],
      ),
    );
  }

  // 투표 입력 섹션
  Widget _buildVoteInputSection(bool isKeyboardVisible) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDailyLimitInfo(),
        SizedBox(height: PicnicUi.vertical(4)),
        // 전체 사용/입력/지우기는 각자 48 터치 영역을 품고 있어, 예전 20·36 높이
        // 행을 떼어놓던 간격이 그 안으로 들어갔다.
        _buildCheckAllOption(),
        _buildVoteAmountInput(context, isKeyboardVisible),
        SizedBox(height: PicnicUi.vertical(4)),
        _buildErrorMessage(),
        SizedBox(height: PicnicUi.vertical(8)),
        _buildCalculationAndErrorSection(), // 계산 영역을 여기로 이동
        _buildJmaInformation(), // JMA 안내 영역을 아래로 이동
      ],
    );
  }

  // 고정 푸터 - 투표 버튼 + JMA 로고
  Widget _buildFixedFooter(String userId, bool isKeyboardVisible) {
    return Container(
      padding: EdgeInsets.only(
        left: PicnicUi.horizontal(16),
        right: PicnicUi.horizontal(16),
        bottom: PicnicUi.vertical(16),
        top: PicnicUi.vertical(8),
      ),
      child: Column(
        children: [
          _buildJmaVoteButton(userId),
          SizedBox(height: PicnicUi.vertical(8)),
          if (!isKeyboardVisible) _buildJmaLogoImage(),
        ],
      ),
    );
  }
}
