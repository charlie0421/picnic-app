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

class StorePointInfo extends ConsumerStatefulWidget {
  const StorePointInfo({
    super.key,
    required this.title,
    this.width = 48,
    this.height = 36,
    this.titlePadding,
    this.topMargin = 20,
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
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      width: widget.width,
      margin: EdgeInsets.only(top: widget.topMargin),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF27222B),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  logger.d('캔디 이용 정책 안내');
                  showUsagePolicyDialog(context);
                },
                child: UnderlinedText(
                  text: localizations.expiring_bonus_candy_guide,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C58E8),
                  ),
                  underlineColor: const Color(0xFF7C58E8),
                  underlineGap: 0,
                ),
              ),
              if (widget.refreshButton case final refresh?) ...[
                const SizedBox(width: 10),
                refresh,
              ] else if (widget.onRefresh != null) ...[
                const SizedBox(width: 10),
                _buildRefreshButton(),
              ],
            ],
          ),
          const SizedBox(height: 12),
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

    return GestureDetector(
      key: const Key('store-point-info-refresh'),
      onTap: widget.onRefresh,
      child: child,
    );
  }
}
