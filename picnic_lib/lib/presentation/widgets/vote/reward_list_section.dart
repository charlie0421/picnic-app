import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/grid_two_column.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_section_header.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_feedback.dart';
import 'package:shimmer/shimmer.dart';

/// 홈/투표 화면 공용 리워드 리스트 섹션.
///
/// 2열 그리드로 렌더링한다. 스크롤러블(GridView)이 아니라 순수 레이아웃
/// [GridTwoColumn]을 써서, 홈 세로 [ListView] 안에서 중첩 스크롤로 인한
/// 스크롤 흔들림 없이 여러 줄을 노출한다.
class RewardListSection extends ConsumerStatefulWidget {
  const RewardListSection({super.key});

  @override
  ConsumerState<RewardListSection> createState() => _RewardListSectionState();
}

class _RewardListSectionState extends ConsumerState<RewardListSection> {
  List<RewardModel> _lastRewards = const [];

  @override
  Widget build(BuildContext context) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: PicnicUi.horizontal(16)),
          child: PicnicSectionHeader(
            title: AppLocalizations.of(context).label_vote_reward_list,
          ),
        ),
        SizedBox(height: PicnicUi.vertical(16)),
        asyncRewardListState.when(
          data: (data) {
            _lastRewards = data;
            return _rewardGrid(context, data);
          },
          loading: () => _lastRewards.isNotEmpty
              ? _rewardGrid(context, _lastRewards)
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Shimmer.fromColors(
                    enabled: !MediaQuery.disableAnimationsOf(context),
                    baseColor: AppColors.grey300,
                    highlightColor: AppColors.grey100,
                    child: GridTwoColumn(
                      childAspectRatio: 1.45,
                      children: List.generate(
                        4,
                        (_) => DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          error: (error, stackTrace) {
            logger.e(error, stackTrace: stackTrace);
            Sentry.captureException(error, stackTrace: stackTrace);
            final retry = KeyedSubtree(
              key: const ValueKey('reward-list-retry'),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: PicnicUi.horizontal(16),
                  vertical: PicnicUi.vertical(12),
                ),
                child: PicnicFeedback(
                  message: AppLocalizations.of(context).message_error_occurred,
                  icon: Icons.error_outline,
                  actionLabel: AppLocalizations.of(context).label_retry,
                  onAction: () => ref.invalidate(asyncRewardListProvider),
                  inline: _lastRewards.isNotEmpty,
                ),
              ),
            );
            if (_lastRewards.isEmpty) return retry;
            return Column(
              children: [_rewardGrid(context, _lastRewards), retry],
            );
          },
        ),
      ],
    );
  }

  Widget _rewardGrid(BuildContext context, List<RewardModel> rewards) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: GridTwoColumn(
          childAspectRatio: 1.45,
          children: [
            for (var index = 0; index < rewards.length; index++)
              _rewardCard(context, rewards[index], index),
          ],
        ),
      );

  Widget _rewardCard(BuildContext context, RewardModel reward, int index) {
    // `title` 은 thumbnail 과 같은 순수 nullable 컬럼(`RewardModel.title`)이라
    // 운영자가 비워두면 널이고, 단언하면 리워드 그리드 전체가 에러 박스가
    // 된다. `getLocaleTextFromJson` 은 빈 맵을 '' 로 처리한다.
    final title = getLocaleTextFromJson(reward.title ?? const {});
    final isHighPriority = index < 4;

    return GestureDetector(
      onTap: () => showRewardDialog(context, reward),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PicnicCachedNetworkImage(
              key: ValueKey('reward_${reward.id}'),
              imageUrl: reward.thumbnail ?? '',
              fit: BoxFit.cover,
              priority: isHighPriority
                  ? ImagePriority.high
                  : ImagePriority.normal,
              enableMemoryOptimization: true,
              enableProgressiveLoading: !isHighPriority,
              lazyLoadingStrategy: isHighPriority
                  ? LazyLoadingStrategy.none
                  : LazyLoadingStrategy.viewport,
              timeout: const Duration(seconds: 10),
              maxRetries: 2,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                constraints: const BoxConstraints(minHeight: 30),
                color: AppColors.grey900.withValues(alpha: 0.7),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  title,
                  style: PicnicUi.text(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
