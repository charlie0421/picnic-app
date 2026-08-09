import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/grid_two_column.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

/// 홈/투표 화면 공용 리워드 리스트 섹션.
///
/// 2열 그리드로 렌더링한다. 스크롤러블(GridView)이 아니라 순수 레이아웃
/// [GridTwoColumn]을 써서, 홈 세로 [ListView] 안에서 중첩 스크롤로 인한
/// 스크롤 흔들림 없이 여러 줄을 노출한다.
class RewardListSection extends ConsumerWidget {
  const RewardListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Text(
            AppLocalizations.of(context).label_vote_reward_list,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
        ),
        const SizedBox(height: 16),
        asyncRewardListState.when(
          data: (data) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GridTwoColumn(
              childAspectRatio: 1.45,
              children: [
                for (var index = 0; index < data.length; index++)
                  _rewardCard(context, data[index], index),
              ],
            ),
          ),
          loading: () => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Shimmer.fromColors(
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
          error: (error, stackTrace) => buildErrorView(
            context,
            error: error.toString(),
            stackTrace: stackTrace,
          ),
        ),
      ],
    );
  }

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
              priority:
                  isHighPriority ? ImagePriority.high : ImagePriority.normal,
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
                height: 30,
                color: AppColors.grey900.withValues(alpha: 0.7),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  title,
                  style: getTextStyle(AppTypo.body14R, Colors.white)
                      .copyWith(overflow: TextOverflow.ellipsis),
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
