import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_result_card.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/community_navigation.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/pages/community/compatibility_input_page.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_history_provider.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:timeago/timeago.dart' as timeago;

class CompatibilityHistoryPage extends ConsumerStatefulWidget {
  const CompatibilityHistoryPage({super.key, this.artistId});

  final int? artistId;

  @override
  ConsumerState<CompatibilityHistoryPage> createState() =>
      _CompatibilityHistoryPageState();
}

class _CompatibilityHistoryPageState
    extends ConsumerState<CompatibilityHistoryPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref
        .read(compatibilityListProvider(artistId: widget.artistId).notifier)
        .loadInitial());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.board,
          showBottomNavigation: false,
          pageTitle: S.of(context).compatibility_page_title);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref
          .read(compatibilityListProvider(artistId: widget.artistId).notifier)
          .loadMore();
    }
  }

  void _onNewCompatibilityTap() {
    final currentArtist = ref.read(communityStateInfoProvider).currentArtist;
    ref.read(navigationInfoProvider.notifier).setCurrentPage(
          CompatibilityInputPage(artist: currentArtist!),
        );
  }

  Widget _buildAnalysisTimeInfo(CompatibilityModel item) {
    if (item.hasError) {
      return Text(
        '분석 실패',
        style: getTextStyle(AppTypo.caption12R, AppColors.point900),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.createdAt != null) ...[
          Text(
            '분석: ${formatDateTimeYYYYMMDDHHM(item.createdAt!)}',
            style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
          ),
          const SizedBox(height: 2),
        ],
        if (item.isPending && item.createdAt != null) ...[
          Text(
            '${timeago.format(item.createdAt!, locale: 'ko')}부터 분석 중',
            style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final history =
        ref.watch(compatibilityListProvider(artistId: widget.artistId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F9), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Empty state or List
            history.items.isEmpty && !history.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '첫 궁합을 확인해보세요! 🌟',
                          style:
                              getTextStyle(AppTypo.body16B, AppColors.grey900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '당신과 잘 맞는 아티스트를 찾아보세요',
                          style:
                              getTextStyle(AppTypo.body14R, AppColors.grey600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount:
                        history.items.length + (history.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == history.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final item = history.items[index];
                      return InkWell(
                          onTap: () {
                            ref
                                .read(navigationInfoProvider.notifier)
                                .setCurrentPage(
                                  CompatibilityResultPage(compatibility: item),
                                );
                          },
                          child: CompatibilityResultCard(
                            compatibility: item,
                          ));
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 16);
                    },
                  ),
            if (widget.artistId != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary500.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onNewCompatibilityTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '새로운 궁합 확인하기',
                          style: getTextStyle(AppTypo.body16B, Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
