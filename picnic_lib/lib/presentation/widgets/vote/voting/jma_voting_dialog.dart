import 'dart:async';

import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
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
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_complete.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/common_gradient.dart';

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
  String _validationMessage = '';
  int _dailyVoteCount = 0; // 오늘 보너스 별사탕 사용량
  static const int _maxDailyVotes = 5; // 일일 최대 보너스 별사탕 사용량 (5개)

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    _focusNode.addListener(_onFocusChange);
    _loadDailyVoteCount();
  }

  // 오늘 보너스 별사탕 사용량 조회 (vote_pick 기반)
  Future<void> _loadDailyVoteCount() async {
    try {
      final userId = ref.read(userInfoProvider).value?.id ?? '';
      if (userId.isEmpty) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // 오늘 보너스 별사탕 사용량 총합 조회
      final response = await supabase
          .from('vote_pick')
          .select('star_candy_bonus_usage')
          .eq('user_id', userId)
          .eq('vote_id', widget.voteModel.id)
          .gt('star_candy_bonus_usage', 0) // 보너스 별사탕을 사용한 투표만
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      if (mounted) {
        setState(() {
          // 보너스 별사탕 사용량 총합 계산
          _dailyVoteCount = response.fold<int>(
              0,
              (sum, record) =>
                  sum + (record['star_candy_bonus_usage'] as int? ?? 0));
        });
      }
    } catch (e) {
      logger.e('Failed to load daily vote count', error: e);
      if (mounted) {
        setState(() {
          _dailyVoteCount = 0; // 기본값으로 설정
        });
      }
    }
  }

  void _onFocusChange() {
    _validateVote();
  }

  void _validateVote() {
    final starCandyAmount = _getStarCandyAmount();
    final totalStarCandy = _getTotalStarCandy();

    String validationMessage = '';
    bool canVote = false;

    if (starCandyAmount > 0) {
      // 총 별사탕(보너스 포함) 부족 검증
      if (starCandyAmount > totalStarCandy) {
        canVote = false;
        final shortfall = starCandyAmount - totalStarCandy;
        validationMessage = AppLocalizations.of(context)
            .jma_voting_star_candy_shortage(formatNumberWithComma(shortfall));
      } else {
        // 3의 배수 검증 (보너스 사용 후 남은 별사탕이 있을 때)
        final bonusStarCandy = _getMyBonusStarCandy();
        final remainingBonusUsage =
            _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
        final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
            ? remainingBonusUsage
            : bonusStarCandy;

        if (starCandyAmount > usableBonusStarCandy) {
          // 보너스로 충당되지 않는 부분이 있을 때
          final remainingStarCandy = starCandyAmount - usableBonusStarCandy;
          if (remainingStarCandy % 3 != 0) {
            canVote = false;
            final needed = (3 - (remainingStarCandy % 3));
            validationMessage = AppLocalizations.of(context)
                .jma_voting_star_candy_multiple_of_three(
                    remainingStarCandy % 3, needed);
          } else {
            canVote = true;
            validationMessage = '';
          }
        } else {
          // 보너스만 사용하는 경우
          canVote = true;
          validationMessage = '';
        }
      }
    }

    if (mounted) {
      setState(() {
        _canVote = canVote;
        _hasValue = starCandyAmount > 0;
        _validationMessage = validationMessage;
      });
    }
  }

  int _getRequiredStarCandyAmount() {
    final voteAmount = _getVoteAmount();
    final bonusStarCandy = _getMyBonusStarCandy();
    final remainingBonusUsage =
        _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
    final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
        ? remainingBonusUsage
        : bonusStarCandy;

    // 전체 투표량을 별사탕으로 계산
    // 보너스로 사용할 수 있는 양과 일반 별사탕으로 사야 할 양을 합쳐서 반환
    int totalStarCandyNeeded = 0;

    if (voteAmount <= usableBonusStarCandy) {
      // 보너스 별사탕만으로 충분한 경우 - 보너스 사용량만큼 별사탕 필요
      totalStarCandyNeeded = voteAmount;
    } else {
      // 보너스 + 일반 별사탕 모두 사용하는 경우
      // 보너스로 사용할 양 + 일반 별사탕으로 사야 할 양(투표 수 * 3)
      totalStarCandyNeeded =
          usableBonusStarCandy + ((voteAmount - usableBonusStarCandy) * 3);
    }

    return totalStarCandyNeeded;
  }

  int _getStarCandyAmount() =>
      int.tryParse(_textEditingController.text.replaceAll(',', '')) ?? 0;

  int _getVoteAmount() {
    final starCandyAmount = _getStarCandyAmount();

    // 보너스 우선 사용하여 투표 수 계산
    final bonusStarCandy = _getMyBonusStarCandy();
    final remainingBonusUsage =
        _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
    final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
        ? remainingBonusUsage
        : bonusStarCandy;

    if (starCandyAmount <= usableBonusStarCandy) {
      // 보너스만으로 충분한 경우 (1:1)
      return starCandyAmount;
    } else {
      // 보너스 + 일반 별사탕 조합
      final remainingStarCandy = starCandyAmount - usableBonusStarCandy;
      final regularVotes = remainingStarCandy ~/ 3; // 일반 별사탕은 3:1
      return usableBonusStarCandy + regularVotes;
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

  // 사용 가능한 스타캔디 (일반 별사탕만 3:1 비율로 변환)
  int _getUsableStarCandy() {
    final regularStarCandy = _getMyStarCandy(); // 일반 별사탕만

    // 일반 별사탕만 3으로 나누고 나머지 버림 (보너스는 별도 계산)
    return regularStarCandy ~/ 3;
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

    // 키보드 높이 감지
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    // 사용 가능한 화면 높이 계산 (키보드 고려)
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - keyboardHeight;

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
            horizontal: 16.w, vertical: isKeyboardVisible ? 20 : 40),
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
            child: LargePopupWidget(
              showCloseButton: false,
              content: Container(
                constraints: BoxConstraints(
                  maxHeight: isKeyboardVisible
                      ? availableHeight * 0.85
                      : availableHeight * 0.75,
                  minHeight: 200,
                  maxWidth: MediaQuery.of(context).size.width - 32.w,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 고정 헤더 - JMA 제목 + 아티스트 정보
                    _buildFixedHeader(),

                    // 스크롤 가능한 중간 영역
                    Expanded(
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w), // 6 → 20으로 증가
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 8.h),
                              _buildStarCandyInfo(myStarCandy),
                              SizedBox(height: 8.h),
                              _buildVoteInputSection(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 고정 푸터 - 투표 버튼 + JMA 로고 (키보드 시 로고 숨김)
                    _buildFixedFooter(userId, isKeyboardVisible),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJmaHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 16.w, vertical: 8), // 12,6 → 16,8로 복원
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
          SizedBox(width: 8.w), // 6 → 8로 복원
          Text(
            'Jupiter Music Awards',
            style: getTextStyle(
              AppTypo.caption12B,
              Colors.white,
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
      width: 60.w, // 50 → 60으로 복원
      height: 60.w, // 50 → 60으로 복원
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary500,
          width: 3, // 2 → 3으로 복원
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.3),
            blurRadius: 12, // 8 → 12로 복원
            offset: Offset(0, 4), // (0,2) → (0,4)로 복원
          ),
          BoxShadow(
            color: AppColors.secondary500.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? PicnicCachedNetworkImage(
                imageUrl: imageUrl,
                width: 60.w, // 50 → 60으로 복원
                height: 60.w, // 50 → 60으로 복원
                fit: BoxFit.cover,
              )
            : _buildDefaultArtistImage(),
      ),
    );
  }

  Widget _buildDefaultArtistImage() {
    return Container(
      width: 60.w, // 50 → 60으로 복원
      height: 60.w, // 50 → 60으로 복원
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary500.withValues(alpha: 0.2),
            AppColors.secondary500.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 40.w, // 30 → 40으로 복원
        color: AppColors.primary500,
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

  Widget _buildVoteAmountInput(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isInitialRender) {
        _isInitialRender = false;
      }

      // 포커스가 있을 때 텍스트 필드가 보이도록 적절한 위치로 스크롤
      if (_focusNode.hasFocus && isKeyboardVisible) {
        final RenderObject? renderObject =
            _inputFieldKey.currentContext?.findRenderObject();
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

    return Container(
      key: _inputFieldKey,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(
          color: !_canVote && _hasValue
              ? AppColors.statusError
              : AppColors.primary500,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: !_canVote && _hasValue
                ? AppColors.statusError.withValues(alpha: 0.2)
                : AppColors.primary500.withValues(alpha: 0.2),
            blurRadius: 6,
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
                cursorColor: AppColors.primary500,
                focusNode: _focusNode,
                controller: _textEditingController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left,
                enableInteractiveSelection: true,
                showCursor: true,
                keyboardAppearance: Brightness.light,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusColor: AppColors.primary500,
                  fillColor: Colors.white,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
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
                      selection:
                          TextSelection.collapsed(offset: formattedText.length),
                    );
                  }),
                ],
                style: getTextStyle(AppTypo.body16B, AppColors.primary500),
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
          color: AppColors.primary500,
          width: 2,
          style: BubbleBoxBorderStyle.solid,
        ),
        position: const BubblePosition.center(0),
        direction: BubbleDirection.top,
      ),
      backgroundColor: AppColors.primary500.withValues(alpha: 0.1),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          AppLocalizations.of(context).jma_voting_info_text,
          style: getTextStyle(
            AppTypo.caption10SB,
            AppColors.grey700,
          ),
          textAlign: TextAlign.center,
        ),
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
                style: getTextStyle(
                  AppTypo.body16B,
                  AppColors.primary500,
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
                    style: getTextStyle(
                      AppTypo.caption12R,
                      AppColors.grey700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Divider(
            color: AppColors.primary500.withValues(alpha: 0.3),
            thickness: 1,
            height: 20.0.h),
      ],
    );
  }

  // 아티스트 정보 (가로 레이아웃)
  Widget _buildArtistInfoRow() {
    // 키보드 상태 확인
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

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
              border: Border.all(
                color: AppColors.primary500,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? PicnicCachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
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
            crossAxisAlignment: isKeyboardVisible
                ? CrossAxisAlignment.center // 키보드 시 중앙 정렬
                : CrossAxisAlignment.start, // 평상시 왼쪽 정렬
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 메인 아티스트 이름
              Text(
                getLocaleTextFromJson(
                    (widget.voteItemModel.artist?.id ?? 0) != 0
                        ? widget.voteItemModel.artist?.name ?? {}
                        : widget.voteItemModel.artistGroup?.name ?? {}),
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                textAlign: isKeyboardVisible
                    ? TextAlign.center // 키보드 시 중앙 정렬
                    : TextAlign.start, // 평상시 왼쪽 정렬
              ),

              // 그룹 이름 (솔로 아티스트의 경우)
              if ((widget.voteItemModel.artist?.id ?? 0) != 0 &&
                  widget.voteItemModel.artist?.artistGroup?.name != null) ...[
                SizedBox(height: 2),
                Text(
                  getLocaleTextFromJson(
                      widget.voteItemModel.artist!.artistGroup!.name),
                  style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
                  textAlign: isKeyboardVisible
                      ? TextAlign.center // 키보드 시 중앙 정렬
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
    final usableStarCandy = _getUsableStarCandy(); // 기본 별사탕 기준
    final remainingBonusUsage =
        _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
    final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
        ? remainingBonusUsage
        : bonusStarCandy; // 하루 5개 제한

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8), // 6 → 8로 복원
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 나의 별사탕 섹션
          Text(
            AppLocalizations.of(context).jma_voting_my_star_candy,
            style: getTextStyle(
              AppTypo.caption12B,
              AppColors.grey700,
            ),
          ),
          SizedBox(height: 4),

          // 보유량 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  SizedBox(width: 3),
                  Text(
                    formatNumberWithComma(myStarCandy),
                    style: getTextStyle(
                      AppTypo.caption12B,
                      AppColors.grey600,
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
                  SizedBox(width: 3),
                  Text(
                    '${formatNumberWithComma(bonusStarCandy)}개',
                    style: getTextStyle(
                      AppTypo.caption12B,
                      Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 6),

          // 구분선
          Divider(
            color: AppColors.grey300,
            thickness: 0.5,
            height: 1,
          ),

          SizedBox(height: 6),

          // 사용가능 별사탕 섹션
          Text(
            AppLocalizations.of(context).jma_voting_usable_jma_votes,
            style: getTextStyle(
              AppTypo.caption12B,
              AppColors.primary500,
            ),
          ),
          SizedBox(height: 4),

          // 사용 가능량들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 별사탕 (3의 배수)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/jma.png',
                    width: 40,
                    height: 40,
                  ),
                  SizedBox(width: 3),
                  Text(
                    formatNumberWithComma(usableStarCandy),
                    style: getTextStyle(
                      AppTypo.caption12B,
                      AppColors.primary500,
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
                  SizedBox(width: 3),
                  Text(
                    '${formatNumberWithComma(usableBonusStarCandy)}개',
                    style: getTextStyle(
                      AppTypo.caption12B,
                      Colors.orange.shade700,
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4),
      margin: EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: remainingVotes > 0 ? Colors.blue.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color:
                remainingVotes > 0 ? Colors.blue.shade200 : Colors.red.shade200,
            width: 1),
      ),
      child: Row(
        children: [
          Icon(
            remainingVotes > 0 ? Icons.access_time : Icons.warning,
            color:
                remainingVotes > 0 ? Colors.blue.shade600 : Colors.red.shade600,
            size: 14,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              remainingVotes > 0
                  ? AppLocalizations.of(context)
                      .jma_voting_daily_limit_remaining(
                          _maxDailyVotes, remainingVotes)
                  : AppLocalizations.of(context)
                      .jma_voting_daily_limit_exhausted,
              style: getTextStyle(
                AppTypo.caption10SB,
                remainingVotes > 0 ? Colors.blue.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationAndErrorSection() {
    final starCandyAmount = _getStarCandyAmount();
    final voteAmount = _getVoteAmount();

    // 계산 결과나 에러 메시지가 있을 때만 표시
    if (starCandyAmount == 0 && _validationMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _validationMessage.isNotEmpty
            ? AppColors.statusError.withValues(alpha: 0.05)
            : AppColors.primary500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _validationMessage.isNotEmpty
              ? AppColors.statusError.withValues(alpha: 0.2)
              : AppColors.primary500.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 계산 결과 (별사탕 입력이 있고 유효할 때)
          if (starCandyAmount > 0 && _canVote) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: AppColors.primary500,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getCalculationResultMessage(),
                    style: getTextStyle(
                      AppTypo.caption12M,
                      AppColors.primary500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 에러 메시지
          if (_validationMessage.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.statusError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 12,
                    color: AppColors.statusError,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _validationMessage,
                    style: getTextStyle(
                      AppTypo.caption12M,
                      AppColors.statusError,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getMaxExchangeGuideMessage() {
    final myStarCandy = _getMyStarCandy();
    final maxUsableStarCandy = (myStarCandy ~/ 3) * 3;

    return AppLocalizations.of(context)
        .jma_voting_max_usable(formatNumberWithComma(maxUsableStarCandy));
  }

  String _getCalculationResultMessage() {
    final requiredStarCandy = _getRequiredStarCandyAmount();
    final voteAmount = _getVoteAmount();

    // 보너스 사용 여부 계산
    final bonusStarCandy = _getMyBonusStarCandy();
    final remainingBonusUsage =
        _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
    final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
        ? remainingBonusUsage
        : bonusStarCandy;

    if (voteAmount <= usableBonusStarCandy) {
      // 보너스만으로 충분한 경우
      return AppLocalizations.of(context).jma_voting_bonus_only(
          formatNumberWithComma(voteAmount), formatNumberWithComma(voteAmount));
    } else if (usableBonusStarCandy > 0) {
      // 보너스 + 일반 별사탕 조합
      final regularStarCandyNeeded = (voteAmount - usableBonusStarCandy) * 3;
      return AppLocalizations.of(context).jma_voting_bonus_plus_regular(
          formatNumberWithComma(usableBonusStarCandy),
          formatNumberWithComma(regularStarCandyNeeded),
          formatNumberWithComma(voteAmount));
    } else {
      // 일반 별사탕만 사용
      return AppLocalizations.of(context).jma_voting_regular_only(
          formatNumberWithComma(requiredStarCandy),
          formatNumberWithComma(voteAmount));
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
              // 사용 가능한 보너스 + 사용 가능한 별사탕(3의 배수) 합산
              final bonusStarCandy = _getMyBonusStarCandy();
              final remainingBonusUsage =
                  _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
              final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
                  ? remainingBonusUsage
                  : bonusStarCandy;

              final myStarCandy = _getMyStarCandy();
              final usableStarCandy =
                  (myStarCandy ~/ 3) * 3; // 3의 배수로 사용 가능한 별사탕

              // 보너스 개수 + 사용 가능한 별사탕 개수 = 총 입력 가능 개수
              final totalUsableAmount = usableBonusStarCandy + usableStarCandy;
              _textEditingController.text =
                  formatNumberWithComma(totalUsableAmount);
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
              color: _checkAll ? AppColors.primary500 : AppColors.grey400,
              size: 20,
            ),
            SizedBox(width: 4.w),
            Text(
              AppLocalizations.of(context).jma_voting_use_all,
              style: getTextStyle(
                AppTypo.body14M,
                _checkAll ? AppColors.primary500 : AppColors.grey400,
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
        color: _hasValue ? AppColors.primary500 : AppColors.grey400,
        size: 20,
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (!_canVote && _hasValue && _validationMessage.isEmpty) {
      // 투표 안내 메시지
      final voteAmount = _getVoteAmount();

      if (voteAmount > 0) {
        return Container(
          padding: EdgeInsets.only(left: 22.w),
          width: double.infinity,
          child: Text(
            '${formatNumberWithComma(voteAmount)}개의 투표를 진행합니다.',
            style: getTextStyle(
              AppTypo.caption10SB,
              AppColors.primary500,
            ),
            textAlign: TextAlign.left,
          ),
        );
      }
    }
    return const SizedBox(height: 0);
  }

  Widget _buildJmaVoteButton(String userId) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canVote ? () => _handleVote(userId) : null,
      child: Container(
        width: 172.w,
        height: 44, // 44 → 52로 복원
        decoration: BoxDecoration(
          gradient: _canVote ? commonGradient : null,
          color: _canVote ? null : AppColors.grey300,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _canVote
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_canVote) ...[
              Icon(
                Icons.how_to_vote,
                color: Colors.white,
                size: 20, // 18 → 20으로 복원
              ),
              SizedBox(width: 8.w), // 6 → 8로 복원
            ],
            Text(
              AppLocalizations.of(context).label_button_vote,
              style: getTextStyle(
                AppTypo.title18B, // body16B → title18B로 복원
                Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleVote(String userId) {
    final voteAmount = _getVoteAmount();
    final requiredStarCandy = _getRequiredStarCandyAmount();

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
    _loadingKey.currentState?.show();

    // 보너스 사용 계산
    final bonusStarCandy = _getMyBonusStarCandy();
    final remainingBonusUsage =
        _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
    final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
        ? remainingBonusUsage
        : bonusStarCandy;

    final bonusVotesUsed =
        voteAmount <= usableBonusStarCandy ? voteAmount : usableBonusStarCandy;

    // 교환과 투표를 함께 수행
    _performExchangeAndVoting(voteAmount, userId, bonusVotesUsed);
  }

  // 교환과 투표를 함께 수행하는 함수
  Future<void> _performExchangeAndVoting(
      int voteAmount, String userId, int bonusVotesUsed) async {
    try {
      // 투표 수행 (교환 로직이 내장됨)
      await _performVoting(voteAmount, userId, bonusVotesUsed);
    } catch (e) {
      logger.e('Voting error', error: e);
      _loadingKey.currentState?.hide();
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

  /// 보너스 캔디 우선 사용 로직으로 사용량 계산 (실제 별사탕 개수 기준)
  Map<String, int> _calculateUsage(int totalStarCandyAmount) {
    final voteAmount = _getVoteAmount();
    final bonusStarCandy = _getMyBonusStarCandy();
    final remainingBonusUsage =
        _maxDailyVotes - _dailyVoteCount; // 남은 보너스 사용 가능량
    final usableBonusStarCandy = bonusStarCandy > remainingBonusUsage
        ? remainingBonusUsage
        : bonusStarCandy;

    int starCandyUsage = 0; // 일반 별사탕 사용량 (개수)
    int starCandyBonusUsage = 0; // 보너스 별사탕 사용량 (개수)

    if (voteAmount <= usableBonusStarCandy) {
      // 보너스 별사탕만으로 충분한 경우
      starCandyBonusUsage = voteAmount; // 보너스는 1:1 비율
      starCandyUsage = 0;
    } else {
      // 보너스 별사탕을 모두 사용하고 일반 별사탕도 사용
      starCandyBonusUsage = usableBonusStarCandy; // 보너스는 1:1 비율
      final regularVotes = voteAmount - usableBonusStarCandy;
      starCandyUsage = regularVotes * 3; // 일반 별사탕은 3:1 비율
    }

    return {
      'star_candy_usage': starCandyUsage, // 실제 별사탕 개수
      'star_candy_bonus_usage': starCandyBonusUsage, // 실제 보너스 별사탕 개수
    };
  }

  Future<void> _performVoting(
      int voteAmount, String userId, int bonusVotesUsed) async {
    try {
      // PIC에서는 JMA 보팅이 지원되지 않음
      if (widget.portalType == VotePortal.pic) {
        throw Exception('JMA voting is not supported for PIC');
      }

      // 필요한 별사탕 계산
      final requiredStarCandy = _getRequiredStarCandyAmount();
      final usage = _calculateUsage(requiredStarCandy);

      // 새로운 jma-voting-v2 엣지 함수 사용
      final response = await supabase.functions.invoke('jma-voting-v2', body: {
        'vote_id': widget.voteModel.id,
        'vote_item_id': widget.voteItemModel.id,
        'amount': voteAmount, // 투표 수
        'star_candy_usage': usage['star_candy_usage'],
        'star_candy_bonus_usage': usage['star_candy_bonus_usage'],
        'user_id': userId,
        'bonus_votes_used': bonusVotesUsed,
      });

      if (response.status != 200) {
        // Edge function에서 일일 제한 오류 처리
        if (response.status == 429) {
          _loadingKey.currentState?.hide();
          if (mounted) {
            showSimpleDialog(
              type: DialogType.error,
              title: AppLocalizations.of(context).jma_voting_daily_limit_title,
              content:
                  AppLocalizations.of(context).jma_voting_daily_limit_error,
              onOk: () {},
            );
          }
          return;
        }
        throw Exception('Failed to vote');
      }

      await ref.read(userInfoProvider.notifier).getUserProfiles();

      ref
          .read(asyncVoteItemListProvider(voteId: widget.voteModel.id).notifier)
          .fetch(voteId: widget.voteModel.id);

      // 투표 성공 시 일일 카운트 새로고침
      await _loadDailyVoteCount();

      _loadingKey.currentState?.hide();

      if (!mounted) return;

      Navigator.of(context).pop();

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

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

  // 고정 헤더 - JMA 제목 + 아티스트 정보
  Widget _buildFixedHeader() {
    // 키보드 상태 확인
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Container(
      padding: EdgeInsets.only(
        top: isKeyboardVisible ? 12.h : 16.h, // 키보드 시 패딩 줄임
        left: 20.w, // 16 → 20으로 증가
        right: 20.w, // 16 → 20으로 증가
        bottom: isKeyboardVisible ? 4.h : 8.h, // 키보드 시 패딩 줄임
      ),
      child: Column(
        children: [
          _buildJmaHeader(),
          SizedBox(height: isKeyboardVisible ? 4 : 8), // 키보드 시 간격 줄임
          _buildArtistInfoRow(),
        ],
      ),
    );
  }

  // 투표 입력 섹션
  Widget _buildVoteInputSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDailyLimitInfo(),
        const SizedBox(height: 8),
        _buildCheckAllOption(),
        const SizedBox(height: 6),
        _buildVoteAmountInput(context),
        const SizedBox(height: 6),
        _buildErrorMessage(),
        const SizedBox(height: 8),
        _buildCalculationAndErrorSection(), // 계산 영역을 여기로 이동
        _buildJmaBubble(), // JMA 안내 영역을 아래로 이동
      ],
    );
  }

  // 고정 푸터 - 투표 버튼 + JMA 로고
  Widget _buildFixedFooter(String userId, bool isKeyboardVisible) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w, // 16 → 20으로 증가
        right: 20.w, // 16 → 20으로 증가
        bottom: 16.h, // 12 → 16으로 증가
        top: 8.h, // 6 → 8로 증가
      ),
      child: Column(
        children: [
          _buildJmaVoteButton(userId),
          const SizedBox(height: 8), // 6 → 8로 증가
          if (!isKeyboardVisible) _buildJmaLogoImage(),
        ],
      ),
    );
  }
}
