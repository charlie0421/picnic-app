import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/pages/community/compatibility_input_page.dart';
import 'package:picnic_app/pages/community/compatibility_loading_page.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_list_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';

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
            colors: [AppColors.primary500, AppColors.mint500],
          ),
        ),
        child: history.items.isEmpty && !history.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/fortune/no_item_${getLocaleLanguage()}.svg',
                    ),
                    SizedBox(height: 64),
                    ElevatedButton(
                      onPressed: _onNewCompatibilityTap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            S.of(context).compatibility_new_compatibility,
                            style: getTextStyle(AppTypo.body16B, Colors.white),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            : Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                    children: [
                      SvgPicture.asset(
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
                                child: CompatibilityInfo(
                                  artist: item.artist,
                                  ref: ref,
                                  birthDate: item.birthDate,
                                  birthTime: item.birthTime,
                                  gender: item.gender,
                                  compatibility: item,
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
                            color: AppColors.primary500.withOpacity(0.2),
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
                              S.of(context).compatibility_new_compatibility,
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
