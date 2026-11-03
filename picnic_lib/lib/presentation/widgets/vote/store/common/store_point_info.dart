import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';

import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

class StorePointInfo extends ConsumerStatefulWidget {
  const StorePointInfo({
    super.key,
    required this.title,
    this.width = 48,
    this.height = 36,
    this.titlePadding,
    this.topMargin = 0,
    this.refreshButton,
    this.onRefresh,
    this.refreshController,
  });

  final double? width;
  final double? height;
  final String title;
  final double? titlePadding;
  final double topMargin;

  /// 파우치 새로고침. 스토어 헤더에 따로 떠 있던 것을 카드 안으로 옮겼다
  /// (오너 스펙). 동작은 그대로 — 프로필과 지갑 요약을 함께 다시 읽는다.
  final Widget? refreshButton;
  final VoidCallback? onRefresh;
  final AnimationController? refreshController;

  @override
  ConsumerState<StorePointInfo> createState() => _StorePointInfoState();
}

class _StorePointInfoState extends ConsumerState<StorePointInfo> {
  /// 헤더(제목·안내·새로고침) 한 줄의 높이. 새로고침·안내 버튼의 탭 영역을
  /// 머티리얼 최소 조작 영역(48)으로 유지한다 — 대신 카드 상단 패딩과
  /// 헤더↔잔액 간격을 줄여 카드를 타이트하게 만든다 (Codex 리뷰 반영).
  static const double kHeaderRowHeight = 48;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // 파우치는 스토어·무료충전소·마이페이지가 공유하는 공통 영역이다. 기기의
    // 글자 크기·화면 확대 설정을 따라가면 기종마다 카드 높이가 달라지므로
    // (PICNIC-2689: S25 에서만 헤더가 2단으로 쌓임) 카드 안에서는 시스템
    // 글자 배율을 적용하지 않는다.
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: widget.width,
        margin: EdgeInsets.only(top: widget.topMargin),
        // 상단 4: 48px 헤더 행 안에서 제목·아이콘이 세로 중앙에 오므로
        // 시각적 여백은 4 + 12 = 16 이다. 하단은 잔액 박스 아래 12.
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF9A7BFA), width: 2),
          borderRadius: BorderRadius.circular(23),
          boxShadow: const [
            BoxShadow(
              color: Color(0x149A7BFA),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(localizations),
            const SizedBox(height: 4),
            if (isSupabaseLoggedSafely) ...[
              const StarCandyInfoText(),
            ] else ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  logger.d('로그인 필요 다이얼로그 표시');
                  showRequireLoginDialog();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: UnderlinedText(
                    text: localizations.label_mypage_should_login,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C58E8),
                    ),
                    underlineColor: const Color(0xFF7C58E8),
                    underlineGap: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    final policy = TextButton(
      onPressed: () {
        logger.d('캔디 이용 정책 안내');
        showUsagePolicyDialog(context);
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(0, kHeaderRowHeight),
        foregroundColor: PicnicUi.actionColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        localizations.expiring_bonus_candy_guide,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: PicnicUi.text(
          size: 12,
          weight: FontWeight.w600,
          color: PicnicUi.actionColor,
        ),
      ),
    );
    final refresh =
        widget.refreshButton ??
        (widget.onRefresh == null ? null : _buildRefreshButton());
    // 헤더는 항상 한 줄이다. 좁은 카드(화면 확대 설정, 긴 번역)에서는 안내
    // 문구를 줄바꿈하거나 아래 줄로 내리지 않고 축소해서 맞춘다 — 2단으로
    // 쌓이면 기종마다 파우치 높이가 달라진다 (PICNIC-2689).
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PicnicUi.text(size: 16, weight: FontWeight.w600),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: policy,
              ),
            ),
            if (refresh != null) ...[const SizedBox(width: 8), refresh],
          ],
        );
      },
    );
  }

  Widget _buildRefreshButton() {
    final icon = SvgPicture.asset(
      package: 'picnic_lib',
      'assets/icons/reset_style=line.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
    );
    final child = widget.refreshController == null
        ? icon
        : RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: widget.refreshController!,
                curve: Curves.easeInOut,
              ),
            ),
            child: icon,
          );

    return IconButton(
      key: const Key('store-point-info-refresh'),
      tooltip: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      onPressed: widget.onRefresh,
      constraints: const BoxConstraints.tightFor(
        width: kHeaderRowHeight,
        height: kHeaderRowHeight,
      ),
      padding: const EdgeInsets.all(12),
      icon: child,
    );
  }
}
