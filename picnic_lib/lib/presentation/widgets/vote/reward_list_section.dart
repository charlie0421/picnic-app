import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:picnic_lib/presentation/providers/reward_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

/// 홈/투표 화면 공용 리워드 리스트 섹션.
///
/// `vote_home_page.dart`의 `_buildRewardList`를 재사용 가능한 위젯으로 추출한 것.
class RewardListSection extends ConsumerWidget {
  const RewardListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(left: 16.w),
          alignment: Alignment.centerLeft,
          child: Text(
            AppLocalizations.of(context).label_vote_reward_list,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
        ),
        const SizedBox(height: 16),
        asyncRewardListState.when(
          data: (data) => Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16.w),
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              cacheExtent: 400.0,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
              itemBuilder: (context, index) {
                final title = getLocaleTextFromJson(data[index].title!);
                final isHighPriority = index < 3;

                return GestureDetector(
                  onTap: () => showRewardDialog(context, data[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8).r,
                    ),
                    child: SizedBox(
                      width: 120,
                      height: 100,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PicnicCachedNetworkImage(
                              key: ValueKey('reward_${data[index].id}'),
                              imageUrl: data[index].thumbnail ?? '',
                              width: 120,
                              height: 100,
                              fit: BoxFit.fitWidth,
                              priority: isHighPriority
                                  ? ImagePriority.high
                                  : ImagePriority.normal,
                              enableMemoryOptimization: true,
                              enableProgressiveLoading: !isHighPriority,
                              memCacheWidth: 120,
                              memCacheHeight: 100,
                              lazyLoadingStrategy: isHighPriority
                                  ? LazyLoadingStrategy.none
                                  : LazyLoadingStrategy.viewport,
                              timeout: const Duration(seconds: 10),
                              maxRetries: 2,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: 120,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: const Radius.circular(8),
                                  bottomRight: const Radius.circular(8),
                                ),
                                color: AppColors.grey900.withValues(alpha: 0.7),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: Text(
                                title,
                                style: getTextStyle(
                                  AppTypo.body14R,
                                  Colors.white,
                                ).copyWith(overflow: TextOverflow.ellipsis),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          loading: () => Shimmer.fromColors(
            baseColor: AppColors.grey300,
            highlightColor: AppColors.grey100,
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) => Container(
                  width: 120,
                  height: 100,
                  margin: EdgeInsets.only(
                    left: 16.w,
                    right: index == 4 ? 16.w : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.white,
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
}
