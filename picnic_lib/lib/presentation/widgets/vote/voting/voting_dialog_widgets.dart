import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/ui/style.dart';

/// 아티스트 프로필 이미지
class VotingArtistImage extends StatelessWidget {
  final VoteItemModel voteItemModel;

  const VotingArtistImage({super.key, required this.voteItemModel});

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if ((voteItemModel.artist?.id ?? 0) != 0) {
      imageUrl = voteItemModel.artist?.image;
    } else {
      imageUrl = voteItemModel.artistGroup?.image;
    }

    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary500, width: 2),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? PicnicCachedNetworkImage(
                imageUrl: imageUrl,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
              )
            : Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey200,
                ),
                child: Icon(Icons.person, size: 40.w, color: AppColors.grey500),
              ),
      ),
    );
  }
}

/// 아티스트/그룹 이름 정보
class VotingMemberInfo extends StatelessWidget {
  final VoteItemModel voteItemModel;

  const VotingMemberInfo({super.key, required this.voteItemModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getLocaleTextFromJson(
                    (voteItemModel.artist?.id ?? 0) != 0
                        ? voteItemModel.artist?.name ?? {}
                        : voteItemModel.artistGroup?.name ?? {}),
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
              SizedBox(width: 8.w),
              if ((voteItemModel.artist?.id ?? 0) != 0 &&
                  voteItemModel.artist?.artistGroup?.name != null)
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    getLocaleTextFromJson(
                        voteItemModel.artist!.artistGroup!.name),
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
}

/// 파트너/기본 로고 이미지
class VotingLogoImage extends StatelessWidget {
  final VoteModel voteModel;

  const VotingLogoImage({super.key, required this.voteModel});

  @override
  Widget build(BuildContext context) {
    final isPartnership = voteModel.isPartnership ?? false;
    final partner = voteModel.partner;

    if (isPartnership && partner != null && partner.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            package: 'picnic_lib',
            'assets/images/partners/$partner.png',
            width: 100.w,
            height: 100.w,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    partner.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return SizedBox(
      width: 60.w,
      height: 60.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            package: 'picnic_lib',
            'assets/images/logo.png',
            width: 40.w,
            height: 40.w,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

/// 파트너십 혜택 버블
class VotingBubbleInfo extends StatelessWidget {
  final VoteModel voteModel;

  const VotingBubbleInfo({super.key, required this.voteModel});

  @override
  Widget build(BuildContext context) {
    final isPartnership = voteModel.isPartnership ?? false;
    final partner = voteModel.partner;

    // BubbleBox import를 피하기 위해 간단한 Container로 대체하지 않음
    // 이 위젯은 voting_dialog.dart에서 BubbleBox와 함께 사용됨
    // → 호출부에서 BubbleBox 래핑 유지
    return Column(
      children: [
        isPartnership && partner != null && partner.isNotEmpty
            ? Text(
                '· ${AppLocalizations.of(context).voting_share_benefit_text}\n· ${partner.toUpperCase()} 파트너십 혜택',
                style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
                textAlign: TextAlign.center,
              )
            : Text(
                '· ${AppLocalizations.of(context).voting_share_benefit_text}',
                style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
              ),
      ],
    );
  }
}

/// 스타캔디 잔액 + 충전 버튼
class VotingStarCandyInfo extends StatelessWidget {
  final int myStarCandy;
  final VoidCallback onRecharge;

  const VotingStarCandyInfo({
    super.key,
    required this.myStarCandy,
    required this.onRecharge,
  });

  @override
  Widget build(BuildContext context) {
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
          _RechargeButton(onPressed: onRecharge),
        ],
      ),
    );
  }
}

class _RechargeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RechargeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
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
}

/// 투표 제출 버튼
class VotingSubmitButton extends StatelessWidget {
  final bool canVote;
  final bool isVoting;
  final VoidCallback? onPressed;

  const VotingSubmitButton({
    super.key,
    required this.canVote,
    required this.isVoting,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = canVote && !isVoting;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: 172.w,
        height: 52,
        decoration: BoxDecoration(
          color: isVoting
              ? AppColors.primary500
              : (isEnabled ? AppColors.primary500 : AppColors.grey300),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: isVoting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                AppLocalizations.of(context).label_button_vote,
                style: getTextStyle(AppTypo.title18SB, AppColors.grey00),
              ),
      ),
    );
  }
}

/// 전체 사용 체크박스
class VotingCheckAllOption extends StatelessWidget {
  final bool checkAll;
  final VoidCallback onToggle;

  const VotingCheckAllOption({
    super.key,
    required this.checkAll,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
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
                checkAll ? AppColors.primary500 : AppColors.grey300,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              AppLocalizations.of(context).label_checkbox_entire_use,
              style: getTextStyle(
                AppTypo.body14M,
                checkAll ? AppColors.primary500 : AppColors.grey300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 충전 필요 에러 메시지
class VotingErrorMessage extends StatelessWidget {
  final bool canVote;
  final bool hasValue;

  const VotingErrorMessage({
    super.key,
    required this.canVote,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    if (!canVote && hasValue) {
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
}

/// 입력 필드 클리어 버튼
class VotingClearButton extends StatelessWidget {
  final bool hasValue;
  final VoidCallback onClear;

  const VotingClearButton({
    super.key,
    required this.hasValue,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClear,
      child: SvgPicture.asset(
        package: 'picnic_lib',
        'assets/icons/cancel_style=fill.svg',
        colorFilter: ColorFilter.mode(
          hasValue ? AppColors.grey700 : AppColors.grey200,
          BlendMode.srcIn,
        ),
        width: 20.w,
        height: 20,
      ),
    );
  }
}
