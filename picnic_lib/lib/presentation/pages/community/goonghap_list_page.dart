import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_artist_select_page.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_input_page.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_loading_page.dart';
import 'package:picnic_lib/presentation/pages/community/goonghap_result_page.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_list_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/goong_hap_intro_dialog.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_card.dart';
import 'package:picnic_lib/presentation/widgets/community/goonghap/goonghap_score_widget.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'dart:async';

class GoonghapListPage extends ConsumerStatefulWidget {
  const GoonghapListPage({super.key, this.artistId});

  final int? artistId;

  @override
  ConsumerState<GoonghapListPage> createState() =>
      _GoonghapListPageState();
}

class _GoonghapListPageState extends ConsumerState<GoonghapListPage>
    with RouteAwareStateMixin<GoonghapListPage> {
  final _scrollController = ScrollController();

  // 성능 최적화를 위한 const 상수 활용
  static const _scrollThreshold = 0.8;
  static const _basePadding = EdgeInsets.fromLTRB(16, 24, 16, 80);
  static const _headerPadding = EdgeInsets.fromLTRB(16, 24, 16, 16);

  // 🔧 연타 방지만 - 스크롤 관련 복잡한 로직 제거
  DateTime? _lastTapTime;
  static const Duration _tapCooldown = Duration(milliseconds: 300); // 연타 방지용

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(
      () => ref
          .read(goonghapListProvider(artistId: widget.artistId).notifier)
          .loadInitial(),
    );

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
    // 페이지로 돌아올 때 리스트 새로고침
    ref
        .read(goonghapListProvider(artistId: widget.artistId).notifier)
        .loadInitial();
  }

  // 단순한 스크롤 처리 - 페이지네이션만
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * _scrollThreshold) {
      ref
          .read(goonghapListProvider(artistId: widget.artistId).notifier)
          .loadMore();
    }
  }

  void _onNewGoonghapTap() {
    final currentArtist = ref.read(communityStateInfoProvider).currentArtist;
    if (currentArtist != null) {
      // 현재 선택된 아티스트가 있으면 바로 입력 페이지로 이동
      ref
          .read(navigationInfoProvider.notifier)
          .setCommunityCurrentPage(
            GoonghapInputPage(artist: currentArtist),
          );
    } else {
      // 아티스트가 없으면 아티스트 선택 페이지로 이동
      ref
          .read(navigationInfoProvider.notifier)
          .setCommunityCurrentPage(const GoonghapArtistSelectPage());
    }
  }

  // 🔧 연타 방지만 - 단순화
  void _onGoonghapCardTap(GoonghapModel item) {
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
    if (item.status == GoonghapStatus.completed && item.isAds == true) {
      ref
          .read(navigationInfoProvider.notifier)
          .setCommunityCurrentPage(
            GoonghapResultPage(goonghap: item),
          );
    } else {
      ref
          .read(navigationInfoProvider.notifier)
          .setCommunityCurrentPage(
            GoonghapLoadingPage(goonghap: item),
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
            l10n.goonghap_login_required_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey00),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.goonghap_login_required_subtitle,
            style: getTextStyle(
              AppTypo.body14R,
              AppColors.grey00.withValues(alpha: 0.8),
            ),
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
                  l10n.goonghap_login_button,
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
            AppLocalizations.of(context).goonghap_empty_state_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey00),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).goonghap_empty_state_subtitle,
            style: getTextStyle(
              AppTypo.body14R,
              AppColors.grey00.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildNewGoonghapButton(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final history = ref.watch(
      goonghapListProvider(artistId: widget.artistId),
    );

    // 네비게이션 스택 감지 - 현재 페이지가 top에 있을 때 네비게이션 업데이트
    ref.listen<int?>(
      navigationInfoProvider.select(
        (nav) => nav.voteNavigationStack?.length,
      ),
      (previous, next) {
        final navStack = ref
            .read(navigationInfoProvider)
            .voteNavigationStack;
        final isCurrentPageOnTop = navStack?.peek() is GoonghapListPage;
        if (isCurrentPageOnTop &&
            previous != null &&
            next != null &&
            next < previous) {
          // 스택이 줄어들면서 현재 페이지가 top이 됨 = 뒤로 돌아옴
          _updateNavigation();
          // 페이지로 돌아올 때 리스트 새로고침
          ref
              .read(
                goonghapListProvider(artistId: widget.artistId).notifier,
              )
              .loadInitial();
        }
      },
    );

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
                    padding: _basePadding.copyWith(
                      bottom: _basePadding.bottom + MediaQuery.of(context).padding.bottom,
                    ),
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

                      return _GoonghapListItem(
                        item: item,
                        isLastItem: itemIndex == history.items.length - 1,
                        onTap: () => _onGoonghapCardTap(item),
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
          // 제목: 한글 → 중국어 → 영어 순서
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 한글 궁합 텍스트 (가장 큼)
              Text(
                '궁합',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey00.withValues(alpha: 0.95),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 16),
              // 중국어, 영어, 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 중국어 宮合
                    Text(
                      '宮合',
                      style: getTextStyle(AppTypo.title18B, AppColors.grey00),
                    ),
                    const SizedBox(height: 2),
                    // 영어 Goong-Hap
                    Text(
                      'Goong-Hap',
                      style: getTextStyle(
                        AppTypo.body14R,
                        AppColors.grey00.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 궁합이란? 버튼 (별도 줄) - 작고 팬시하게
          GestureDetector(
            onTap: showGoongHapIntroDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.15),
                    AppColors.secondary500.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.grey00.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.goong_hap_what_is,
                    style: getTextStyle(AppTypo.caption12R, AppColors.grey00),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
              onPressed: _onNewGoonghapTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.goonghap_new,
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

  Widget _buildNewGoonghapButton() {
    return ElevatedButton(
      onPressed: _onNewGoonghapTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).goonghap_new,
            style: getTextStyle(AppTypo.body16B, Colors.white),
          ),
        ],
      ),
    );
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showMyPoint: false,
            topRightMenu: TopRightType.none,
            showBottomNavigation: false,
            pageTitle: AppLocalizations.of(context).goonghap_page_title,
          );
    });
  }
}

class _GoonghapListItem extends ConsumerWidget {
  const _GoonghapListItem({
    required this.item,
    required this.isLastItem,
    required this.onTap,
  });

  final GoonghapModel item;
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
              GoonghapCard(
                artist: item.artist,
                birthDate: item.birthDate,
                birthTime: item.birthTime,
                gender: item.gender,
                goonghap: item,
              ),
              const SizedBox(height: 8),
              GoonghapScoreWidget(goonghap: item),
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
