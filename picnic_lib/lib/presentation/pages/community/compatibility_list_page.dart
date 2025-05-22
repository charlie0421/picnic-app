import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_input_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_loading_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_result_page.dart';
import 'package:picnic_lib/presentation/providers/community/compatibility_list_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_card.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_score_widget.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilityListPage extends ConsumerStatefulWidget {
  const CompatibilityListPage({super.key, this.artistId});

  final int? artistId;

  @override
  ConsumerState<CompatibilityListPage> createState() =>
      _CompatibilityListPageState();
}

class _CompatibilityListPageState extends ConsumerState<CompatibilityListPage> {
  final _scrollController = ScrollController();

  // 성능 최적화를 위한 const 상수 활용
  static const _scrollThreshold = 0.8;
  static const _padding = EdgeInsets.fromLTRB(16, 24, 16, 80);

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
          pageTitle: t('compatibility_page_title'));
    });
  }

  // 메모리 누수 방지
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 성능 최적화
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * _scrollThreshold) {
      ref
          .read(compatibilityListProvider(artistId: widget.artistId).notifier)
          .loadMore();
    }
  }

  void _onNewCompatibilityTap() {
    final currentArtist = ref.read(communityStateInfoProvider).currentArtist;
    if (currentArtist != null) {
      ref.read(navigationInfoProvider.notifier).setCurrentPage(
            CompatibilityInputPage(artist: currentArtist),
          );
    }
  }

  // 불필요한 리빌드 방지를 위한 메서드 분리
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            package: 'picnic_lib',
            'assets/images/fortune/no_item_${getLocaleLanguage()}.svg',
          ),
          const SizedBox(height: 64),
          _buildNewCompatibilityButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history =
        ref.watch(compatibilityListProvider(artistId: widget.artistId));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary500, AppColors.secondary500],
          ),
        ),
        child: history.items.isEmpty && !history.isLoading
            ? _buildEmptyState()
            : Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    padding: _padding,
                    children: [
                      SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/images/fortune/title_${getLocaleLanguage()}.svg',
                        fit: BoxFit.fitHeight,
                        height: 48,
                      ),
                      SizedBox(height: 24),
                      ...List.generate(
                        history.items.length + (history.isLoading ? 1 : 0),
                        (index) {
                          if (index == history.items.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final item = history.items[index];

                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  item.status ==
                                              CompatibilityStatus.completed &&
                                          item.isAds == true
                                      ? ref
                                          .read(navigationInfoProvider.notifier)
                                          .setCurrentPage(
                                              CompatibilityResultPage(
                                                  compatibility: item))
                                      : ref
                                          .read(navigationInfoProvider.notifier)
                                          .setCurrentPage(
                                            CompatibilityLoadingPage(
                                                compatibility: item),
                                          );
                                },
                                child: Column(
                                  children: [
                                    CompatibilityCard(
                                      artist: item.artist,
                                      ref: ref,
                                      birthDate: item.birthDate,
                                      birthTime: item.birthTime,
                                      gender: item.gender,
                                      compatibility: item,
                                    ),
                                    SizedBox(height: 8),
                                    CompatibilityScoreWidget(
                                        compatibility: item),
                                  ],
                                ),
                              ),
                              if (index < history.items.length - 1)
                                Center(
                                  child: Container(
                                    height: 3,
                                    width: 48,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: AppColors.primary500,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onNewCompatibilityTap,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              t('compatibility_new_compatibility'),
                              style:
                                  getTextStyle(AppTypo.body16B, Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget _buildNewCompatibilityButton() {
    return ElevatedButton(
      onPressed: _onNewCompatibilityTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t('compatibility_new_compatibility'),
            style: getTextStyle(AppTypo.body16B, Colors.white),
          ),
        ],
      ),
    );
  }
}
