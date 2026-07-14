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
/// 2열 그리드로 렌더링한다. 홈 세로 [ListView] 안에서 `shrinkWrap`으로
/// 전체 높이를 잡아 여러 줄을 노출하고, 자연히 스크롤 거리를 늘린다.
class RewardListSection extends ConsumerWidget {
  const RewardListSection({super.key});

  /// 2열 그리드 셀 규격.
  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.45,
  );

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
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: _gridDelegate,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final title = getLocaleTextFromJson(data[index].title!);
                final isHighPriority = index < 4;

                return GestureDetector(
                  onTap: () => showRewardDialog(context, data[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PicnicCachedNetworkImage(
                          key: ValueKey('reward_${data[index].id}'),
                          imageUrl: data[index].thumbnail ?? '',
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
                            height: 30,
                            color: AppColors.grey900.withValues(alpha: 0.7),
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
                );
              },
            ),
          ),
          loading: () => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Shimmer.fromColors(
              baseColor: AppColors.grey300,
              highlightColor: AppColors.grey100,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: _gridDelegate,
                itemCount: 4,
                itemBuilder: (context, index) => DecoratedBox(
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
