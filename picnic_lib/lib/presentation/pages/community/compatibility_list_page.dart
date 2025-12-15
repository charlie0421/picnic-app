import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_artist_select_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_input_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_loading_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_result_page.dart';
import 'package:picnic_lib/presentation/providers/community/compatibility_list_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_card.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_score_widget.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'dart:async';

class CompatibilityListPage extends ConsumerStatefulWidget {
  const CompatibilityListPage({super.key, this.artistId});

  final int? artistId;

  @override
  ConsumerState<CompatibilityListPage> createState() =>
      _CompatibilityListPageState();
}

class _CompatibilityListPageState extends ConsumerState<CompatibilityListPage>
    with RouteAwareStateMixin<CompatibilityListPage> {
  final _scrollController = ScrollController();

  // 성능 최적화를 위한 const 상수 활용
  static const _scrollThreshold = 0.8;
  static const _padding = EdgeInsets.fromLTRB(16, 24, 16, 80);
  static const _headerPadding = EdgeInsets.fromLTRB(16, 24, 16, 16);

  // 🔧 연타 방지만 - 스크롤 관련 복잡한 로직 제거
  DateTime? _lastTapTime;
  static const Duration _tapCooldown = Duration(milliseconds: 300); // 연타 방지용

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref
        .read(compatibilityListProvider(artistId: widget.artistId).notifier)
        .loadInitial());

    _updateNavigation();
  }

  // 메모리 누수 방지
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  // 단순한 스크롤 처리 - 페이지네이션만
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
      // 현재 선택된 아티스트가 있으면 바로 입력 페이지로 이동
      ref.read(navigationInfoProvider.notifier).setCommunityCurrentPage(
            CompatibilityInputPage(artist: currentArtist),
          );
    } else {
      // 아티스트가 없으면 아티스트 선택 페이지로 이동
      ref.read(navigationInfoProvider.notifier).setCommunityCurrentPage(
            const CompatibilityArtistSelectPage(),
          );
    }
  }

  // 🔧 연타 방지만 - 단순화
  void _onCompatibilityCardTap(CompatibilityModel item) {
    // 연타 방지 (300ms)
    if (_lastTapTime != null) {
      final timeSinceTap = DateTime.now().difference(_lastTapTime!);
      if (timeSinceTap < _tapCooldown) {
        return; // 연타 차단
      }
    }

    // 연타 방지 시간 갱신
    _lastTapTime = DateTime.now();

    // 페이지 이동
    if (item.status == CompatibilityStatus.completed && item.isAds == true) {
      ref.read(navigationInfoProvider.notifier).setCommunityCurrentPage(
            CompatibilityResultPage(compatibility: item),
          );
    } else {
      ref.read(navigationInfoProvider.notifier).setCommunityCurrentPage(
            CompatibilityLoadingPage(compatibility: item),
          );
    }
  }

  // 비로그인 상태 UI
  Widget _buildLoginRequiredState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.grey00.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 60,
              color: AppColors.grey00.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.compatibility_login_required_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey00),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.compatibility_login_required_subtitle,
            style: getTextStyle(
                AppTypo.body14R, AppColors.grey00.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: showRequireLoginDialog,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.login, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.compatibility_login_button,
                  style: getTextStyle(AppTypo.body16B, Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 불필요한 리빌드 방지를 위한 메서드 분리
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.grey00.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 60,
              color: AppColors.grey00.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).compatibility_empty_state_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey00),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).compatibility_empty_state_subtitle,
            style: getTextStyle(
                AppTypo.body14R, AppColors.grey00.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildNewCompatibilityButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = supabase.auth.currentUser != null;
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
        child: !isLoggedIn
            ? _buildLoginRequiredState()
            : history.items.isEmpty && !history.isLoading
                ? _buildEmptyState()
                : Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: _padding,
                    itemCount:
                        1 + history.items.length + (history.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildHeader();
                      }

                      final itemIndex = index - 1;

                      if (itemIndex == history.items.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: MediumPulseLoadingIndicator(),
                          ),
                        );
                      }

                      final item = history.items[itemIndex];

                      return _CompatibilityListItem(
                        item: item,
                        isLastItem: itemIndex == history.items.length - 1,
                        onTap: () => _onCompatibilityCardTap(item),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: _headerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 한자 + 제목 Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 한자 宮合 텍스트
              Text(
                '宮合',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey00.withValues(alpha: 0.9),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 16),
              // 제목과 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goong-Hap',
                      style: getTextStyle(AppTypo.title18B, AppColors.grey00),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.compatibility_page_title,
                      style: getTextStyle(AppTypo.body14R, AppColors.grey00.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 새 궁합 계산하기 버튼 (웹처럼 상단에 배치)
          Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.compatibility_new_compatibility,
                    style: getTextStyle(AppTypo.body16B, Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
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
            AppLocalizations.of(context).compatibility_new_compatibility,
            style: getTextStyle(AppTypo.body16B, Colors.white),
          ),
        ],
      ),
    );
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.board,
          showBottomNavigation: false,
          pageTitle: AppLocalizations.of(context).compatibility_page_title);
    });
  }
}

class _CompatibilityListItem extends ConsumerWidget {
  const _CompatibilityListItem({
    required this.item,
    required this.isLastItem,
    required this.onTap,
  });

  final CompatibilityModel item;
  final bool isLastItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Column(
            children: [
              CompatibilityCard(
                artist: item.artist,
                birthDate: item.birthDate,
                birthTime: item.birthTime,
                gender: item.gender,
                compatibility: item,
              ),
              const SizedBox(height: 8),
              CompatibilityScoreWidget(compatibility: item),
            ],
          ),
        ),
        if (!isLastItem)
          Center(
            child: Container(
              height: 3,
              width: 48,
              margin: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary500,
              ),
            ),
          ),
      ],
    );
  }
}
