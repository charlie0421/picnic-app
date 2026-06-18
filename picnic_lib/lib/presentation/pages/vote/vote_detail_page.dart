import 'dart:async';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';

import 'package:picnic_lib/presentation/pages/vote/vote_detail_helper.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:rxdart/rxdart.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_skeleton.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_gain_indicator.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_highlight_widget.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_widget.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart';

/// Maximum time the scroll gate may remain raised before the watchdog
/// self-heals.  Deliberately far longer than any real scroll-settle cycle so
/// it cannot fire during ordinary scrolling and cannot reintroduce mid-scroll
/// jank.
const Duration _kScrollGateMaxHold = Duration(seconds: 8);

class VoteDetailPage extends ConsumerStatefulWidget {
  final int voteId;
  final VotePortal votePortal;

  const VoteDetailPage({
    super.key,
    required this.voteId,
    this.votePortal = VotePortal.vote,
  });

  @override
  ConsumerState<VoteDetailPage> createState() => VoteDetailPageState();
}

// ignore: library_private_types_in_public_api
class VoteDetailPageState extends ConsumerState<VoteDetailPage>
    with
        TickerProviderStateMixin<VoteDetailPage>,
        RouteAwareStateMixin<VoteDetailPage>,
        WidgetsBindingObserver {
  late ScrollController _scrollController;
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool isEnded = false;
  bool isUpcoming = false;
  final _searchSubject = BehaviorSubject<String>();
  Timer? _updateTimer;
  bool _isRefreshingItems = false;
  bool _isScrolling = false;
  DateTime? _scrollGateRaisedAt;

  /// Exposes the scroll-gate state for widget tests only.
  @visibleForTesting
  bool get isScrollingForTest => _isScrolling;

  final Map<int, int> _previousVoteCounts = {};
  final Map<int, int> _previousRanks = {};
  final Map<int, int> _currentRanks = {};
  final Set<int> _highlightedItemIds = {};

  final GlobalKey _captureKey = GlobalKey(); // 캡쳐 영역을 위한 새 키
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>(); // 로딩 오버레이 키
  bool _isSaving = false;

  // 로컬 검색어 상태 - 프로바이더 대신 사용
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _setupListeners();
    _setupUpdateTimer();
    _initializeRanks();

    _updateNavigation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _updateTimer?.cancel();
      _updateTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_updateTimer == null) {
        _setupUpdateTimer();
      }
    }
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

  void _initializeControllers() {
    _scrollController = ScrollController();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
  }

  void _setupListeners() {
    _focusNode.addListener(_onFocusChange);
    // macOS에서 검색이 안 되는 문제로 인해 EnhancedSearchBox의 onSearchChanged만 사용
    // _textEditingController.addListener(_onSearchQueryChange);

    // _searchSubject
    //     .debounceTime(const Duration(milliseconds: 300))
    //     .listen((query) {
    //   print('🔍 _searchSubject 리스너 호출됨: "$query"');
    //   if (mounted) {
    //     ref.read(searchQueryProvider.notifier).state = query;
    //     print('🔍 searchQueryProvider 상태 업데이트됨: "$query"');
    //   }
    // });
  }

  void _setupUpdateTimer() {
    _updateTimer = Timer.periodic(_refreshInterval(), (_) async {
      if (!mounted) return;
      // Suppress polling while the user is actively scrolling; the deferred
      // refresh fires once on settle via _onScrollSettle().
      // Self-healing watchdog: if the gate has been raised longer than
      // _kScrollGateMaxHold, a ScrollEndNotification was likely missed —
      // clear the gate and proceed with the refresh rather than stalling
      // live-vote totals indefinitely.
      if (_isScrolling) {
        final raisedAt = _scrollGateRaisedAt;
        if (raisedAt != null &&
            DateTime.now().difference(raisedAt) > _kScrollGateMaxHold) {
          _isScrolling = false;
          _scrollGateRaisedAt = null;
          // fall through to refresh below
        } else {
          return;
        }
      }
      if (_isRefreshingItems || _isSaving) return;
      _isRefreshingItems = true;
      try {
        await ref
            .read(
              asyncVoteItemListProvider(
                voteId: widget.voteId,
                votePortal: widget.votePortal,
              ).notifier,
            )
            .refreshVoteTotals(
              voteId: widget.voteId,
              votePortal: widget.votePortal,
            );
      } catch (_) {
      } finally {
        _isRefreshingItems = false;
      }
    });
  }

  /// Called once when scrolling settles (ScrollEndNotification).
  /// Performs a single vote-totals refresh that was suppressed while scrolling.
  Future<void> _onScrollSettle() async {
    if (!mounted) return;
    if (_isRefreshingItems || _isSaving) return;
    _isRefreshingItems = true;
    try {
      await ref
          .read(
            asyncVoteItemListProvider(
              voteId: widget.voteId,
              votePortal: widget.votePortal,
            ).notifier,
          )
          .refreshVoteTotals(
            voteId: widget.voteId,
            votePortal: widget.votePortal,
          );
    } catch (_) {
    } finally {
      _isRefreshingItems = false;
    }
  }

  /// Refresh cadence: 1s for live votes; widen to 5s once the vote is
  /// ended/upcoming since totals no longer change meaningfully.
  Duration _refreshInterval() {
    if (isEnded || isUpcoming) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 1);
  }

  void _initializeRanks() {
    final items = ref
        .read(
          asyncVoteItemListProvider(
            voteId: widget.voteId,
            votePortal: widget.votePortal,
          ),
        )
        .value;
    if (items != null) {
      _updateRanks(items);
    }
  }

  Future<void> _handleTimerRefresh() async {
    if (!mounted) return;
    // 상세와 아이템 리스트 모두 새로고침하여 상태 전환을 즉시 반영
    // ignore: unused_result
    await ref.refresh(
      asyncVoteDetailProvider(
        voteId: widget.voteId,
        votePortal: widget.votePortal,
      ).future,
    );
    if (!mounted) return;
    // ignore: unused_result
    await ref.refresh(
      asyncVoteItemListProvider(
        voteId: widget.voteId,
        votePortal: widget.votePortal,
      ).future,
    );
  }

  void _updateRanks(List<VoteItemModel?> items) {
    final ranks = VoteDetailHelper.computeRanks(items);
    _currentRanks
      ..clear()
      ..addAll(ranks);
  }

  void _triggerHighlight(int itemId) {
    if (_highlightedItemIds.contains(itemId)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _highlightedItemIds.add(itemId);
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (_highlightedItemIds.contains(itemId)) {
          setState(() {
            _highlightedItemIds.remove(itemId);
          });
        }
      });
    });
  }


  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(
            showPortal: false,
            showTopMenu: true,
            showBottomNavigation: false,
            pageTitle: AppLocalizations.of(context).page_title_vote_detail,
          );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
    _searchSubject.close();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _onFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
      if (_hasFocus) {
        _scrollToSearchBox();
      }
    }
  }

  // macOS에서 검색이 안 되는 문제로 인해 주석 처리
  // void _onSearchQueryChange() {
  //   final query = _textEditingController.text;
  //   print('🔍 _onSearchQueryChange 호출됨: "$query"');
  //   _searchSubject.add(query);
  //   if (_hasFocus) {
  //     _scrollToSearchBox();
  //   }
  // }

  void _scrollToSearchBox() {
    _scrollController.animateTo(
      210.w,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _handleShare() async {
    if (_isSaving) return;
    ShareUtils.shareToSocial(
      _captureKey,
      message: getLocaleTextFromJson(
        ref
            .read(
              asyncVoteDetailProvider(
                voteId: widget.voteId,
                votePortal: widget.votePortal,
              ),
            )
            .value!
            .title,
      ),
      hashtag:
          '#Picnic #Vote #PicnicApp #${getLocaleTextFromJson(ref.read(asyncVoteDetailProvider(voteId: widget.voteId, votePortal: widget.votePortal)).value!.title).replaceAll(' ', '')}',
      downloadLink: await createBranchLink(
        getLocaleTextFromJson(
          ref
              .read(
                asyncVoteDetailProvider(
                  voteId: widget.voteId,
                  votePortal: widget.votePortal,
                ),
              )
              .value!
              .title,
        ),
        '${Environment.appLinkPrefix}/vote/detail/${widget.voteId}',
      ),
      onStart: () {
        _loadingKey.currentState?.show();
        if (mounted) {
          setState(() => _isSaving = true);
        }
      },
      onComplete: () {
        _loadingKey.currentState?.hide();
        if (mounted) {
          setState(() => _isSaving = false);
        }
      },
    );
  }

  void _handleSave() {
    if (_isSaving) return;
    ShareUtils.saveImage(
      _captureKey,
      onStart: () {
        _loadingKey.currentState?.show();
        if (mounted) {
          setState(() => _isSaving = true);
        }
      },
      onComplete: () {
        _loadingKey.currentState?.hide();
        if (mounted) {
          setState(() => _isSaving = false);
        }
      },
    );
  }

  // 메모이제이션을 위한 캐시
  String _lastQuery = '';
  List<VoteItemModel?> _lastData = [];
  List<int> _cachedFilteredIndices = [];

  void _updateCache(List<VoteItemModel?> data, String query, List<int> result) {
    _lastData = List.from(data);
    _lastQuery = query;
    _cachedFilteredIndices = result;
  }

  bool _areDataListsEqual(
    List<VoteItemModel?> list1,
    List<VoteItemModel?> list2,
  ) {
    return VoteDetailHelper.areDataListsEqual(list1, list2);
  }

  List<int> _getFilteredIndices(List<dynamic> args) {
    final List<VoteItemModel?> data = args[0];
    final String query = args[1];

    // 캐시된 결과가 있는지 확인 (데이터 동일성 검사 강화)
    if (query == _lastQuery &&
        data.length == _lastData.length &&
        _cachedFilteredIndices.isNotEmpty &&
        _areDataListsEqual(data, _lastData)) {
      return _cachedFilteredIndices;
    }

    final result = VoteDetailHelper.getFilteredIndices(data, query);
    _updateCache(data, query, result);
    return result;
  }

  // 다국어 텍스트에서 검색어가 포함된 언어의 텍스트를 반환 (초성 검색 포함)
  String _getMatchingText(Map<String, dynamic> nameMap, String query) {
    return VoteDetailHelper.getMatchingText(
      nameMap,
      query,
      fallbackText: getLocaleTextFromJson(nameMap),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 제거 - PicnicAnimatedSwitcher에서 하단 패딩을 관리함
    // 키보드 처리는 GestureDetector + FocusNode.unfocus()로 대체
    return LoadingOverlayWithIcon(
      key: _loadingKey,
      enableRotation: false, // 회전 비활성화
      enableScale: true, // pulse 효과를 위한 스케일
      enableFade: true, // pulse 효과를 위한 페이드
      loadingMessage: null, // 텍스트 제거
      iconAssetPath: 'assets/app_icon_128.png', // 커스텀 앱 아이콘 사용
      // pulse 효과를 위한 커스텀 설정
      scaleDuration: Duration(milliseconds: 800), // 더 빠른 pulse
      fadeDuration: Duration(milliseconds: 800), // 스케일과 동기화
      minScale: 0.98, // 매우 미묘한 변화
      maxScale: 1.02, // 매우 미묘한 변화
      showProgressIndicator: false, // 하단 로딩바 제거
      child: Container(
        color: AppColors.grey00,
        child: ref
            .watch(
              asyncVoteDetailProvider(
                voteId: widget.voteId,
                votePortal: widget.votePortal,
              ),
            )
            .when(
              data: (voteModel) {
                if (voteModel == null) return const SizedBox.shrink();
                isEnded = voteModel.isEnded!;
                isUpcoming = voteModel.isUpcoming!;

                return GestureDetector(
                  onTap: () => _focusNode.unfocus(),
                  child: RefreshIndicator(
                    color: AppColors.primary500,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      _isRefreshingItems = true;
                      try {
                        await Future.wait([
                          ref
                              .refresh(
                                asyncVoteDetailProvider(
                                  voteId: widget.voteId,
                                  votePortal: widget.votePortal,
                                ).future,
                              )
                              .timeout(
                                const Duration(seconds: 8),
                                onTimeout: () => null,
                              ),
                          ref
                              .refresh(
                                asyncVoteItemListProvider(
                                  voteId: widget.voteId,
                                  votePortal: widget.votePortal,
                                ).future,
                              )
                              .timeout(
                                const Duration(seconds: 8),
                                onTimeout: () => [],
                              ),
                        ]);
                      } finally {
                        _isRefreshingItems = false;
                      }
                    },
                    child: SizedBox.expand(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification) {
                            // All scroll starts (user-initiated and programmatic)
                            // raise the gate. The gate is cleared either on
                            // ScrollEndNotification (normal path) or by the
                            // self-healing watchdog in the timer body if
                            // ScrollEndNotification is ever missed.
                            if (!_isScrolling) {
                              _isScrolling = true;
                              _scrollGateRaisedAt = DateTime.now();
                            }
                          } else if (notification is ScrollEndNotification) {
                            if (_isScrolling) {
                              _isScrolling = false;
                              _scrollGateRaisedAt = null;
                              // Single deferred refresh on settle.
                              _onScrollSettle();
                            }
                          }
                          return false; // allow the notification to keep bubbling
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics:
                              const AlwaysScrollableScrollPhysics(), // 데이터가 적어도 항상 스크롤 가능하게
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          // Tier B1: 뷰포트 밖 ~1 화면만 미리 빌드 (기존 inner cacheExtent:200 대체).
                          // 대량(1500+) 리스트에서 메모리를 한 화면치로 묶는다.
                          cacheExtent: MediaQuery.of(context).size.height,
                          slivers: [
                            SliverToBoxAdapter(
                              child: RepaintBoundary(
                                key: _captureKey,
                                child: Column(
                                  children: [
                                    _buildVoteInfo(context, voteModel),
                                    SizedBox(height: 12),
                                    if (_isSaving)
                                      _buildCaptureVoteList(context),
                                  ],
                                ),
                              ),
                            ),
                            if (!_isSaving) _buildVoteItemList(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => SizedBox.expand(child: _buildLoadingShimmer()),
              error: (error, stackTrace) => buildErrorView(
                context,
                error: error.toString(),
                stackTrace: stackTrace,
              ),
            ),
      ),
    );
  }

  Widget _buildVoteInfo(BuildContext context, VoteModel voteModel) {
    final width = getPlatformScreenSize(context).width;
    final horizontalPadding = 57.w; // 타이틀과 동일 기준 패딩
    final contentMaxWidth = width - (horizontalPadding * 2);
    return Column(
      children: [
        if (voteModel.mainImage != null && voteModel.mainImage!.isNotEmpty)
          SizedBox(
            width: width,
            child: PicnicCachedNetworkImage(
              imageUrl: voteModel.mainImage!,
              width: width,
              memCacheWidth: width.toInt(),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: VoteCommonTitle(title: getLocaleTextFromJson(voteModel.title)),
        ),
        const SizedBox(height: 12),
        // 투표 기간 텍스트: 타이틀 가로 너비를 기준으로 축소/압축 표시
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            height: 18,
            width: contentMaxWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                formatVotePeriod(voteModel.startAt, voteModel.stopAt),
                style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 진행/예정 상태에 따른 카운트다운 타이머 노출
        Builder(
          builder: (_) {
            final VoteStatus status = isEnded
                ? VoteStatus.end
                : (isUpcoming ? VoteStatus.upcoming : VoteStatus.active);
            final DateTime endTime = status == VoteStatus.upcoming
                ? voteModel.startAt!
                : voteModel.stopAt!;
            return CountdownTimer(
              endTime: endTime.toUtc(),
              status: status,
              onRefresh: _handleTimerRefresh,
            );
          },
        ),
        const SizedBox(height: 12),
        if (voteModel.reward != null && widget.votePortal == VotePortal.vote)
          // 리워드 컨테이너: 각 리워드를 개별 테두리로 세로 나열
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                ...voteModel.reward!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final rewardModel = entry.value;
                  final thumbnailUrl = rewardModel.thumbnail ?? '';
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < voteModel.reward!.length - 1 ? 8 : 0,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showRewardDialog(context, rewardModel),
                      child: Container(
                        width: double.infinity,
                        height: 42,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary500,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: thumbnailUrl.isNotEmpty
                                    ? PicnicCachedNetworkImage(
                                        imageUrl: thumbnailUrl,
                                        fit: BoxFit.cover,
                                        width: 28,
                                        height: 28,
                                        memCacheWidth: 56,
                                        memCacheHeight: 56,
                                        placeholder: Container(
                                          width: 28,
                                          height: 28,
                                          color: AppColors.grey200,
                                          child: Icon(
                                            Icons.card_giftcard,
                                            size: 12,
                                            color: AppColors.grey500,
                                          ),
                                        ),
                                        lazyLoadingStrategy:
                                            LazyLoadingStrategy.none,
                                        priority: ImagePriority.high,
                                        timeout: const Duration(seconds: 10),
                                        maxRetries: 1,
                                      )
                                    : Container(
                                        width: 28,
                                        height: 28,
                                        color: AppColors.grey200,
                                        child: Icon(
                                          Icons.card_giftcard,
                                          size: 12,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: UnderlinedText(
                                text: getLocaleTextFromJson(
                                  rewardModel.title ?? {},
                                  context,
                                ),
                                textStyle: getTextStyle(
                                  AppTypo.caption12R,
                                  AppColors.grey900,
                                ),
                                underlineHeight: 1,
                                underlineGap: 1,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        // 신청 버튼 추가 (예정된 투표와 진행 중인 투표에만 표시)
        if (!isEnded && !_isSaving)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(child: _buildApplicationButton(context)),
          ),
        if (isEnded && !_isSaving)
          Column(
            children: [
              ShareSection(
                saveButtonText: AppLocalizations.of(context).save,
                shareButtonText: AppLocalizations.of(context).share,
                onSave: _handleSave,
                onShare: _handleShare,
              ),
              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }

  /// Builds a representative single row for [SliverPrototypeExtentList] to
  /// measure offstage. It mirrors the real list row EXACTLY (RepaintBoundary >
  /// Padding(bottom:16) > _buildVoteItemWithHighlight), so the measured height
  /// — row content + the 16px bottom gap — becomes the per-row extent. Built
  /// from the first available item so the measurement is device-correct
  /// (ScreenUtil applied). The non-empty branch guarantees at least one item;
  /// the SizedBox fallback only guards the theoretically-impossible empty case.
  Widget _buildVoteRowPrototype(
    List<VoteItemModel?> data,
    List<int> filteredIndices,
  ) {
    VoteItemModel? sample;
    for (final i in filteredIndices) {
      if (i >= 0 && i < data.length && data[i] != null) {
        sample = data[i];
        break;
      }
    }
    if (sample == null) {
      // Defensive: no measurable item. Keep the prototype non-null.
      return const SizedBox.shrink();
    }
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: _buildVoteItemWithHighlight(
          item: sample,
          index: 0,
          actualRank: 1,
          voteCountDiff: 0,
          rankChanged: false,
          rankUp: false,
          searchQuery: '',
        ),
      ),
    );
  }

  Widget _buildVoteItemList(BuildContext context) {
    final dataAsync = ref.watch(
      asyncVoteItemListProvider(
        voteId: widget.voteId,
        votePortal: widget.votePortal,
      ),
    );

    return dataAsync.when(
      data: (data) {
        _updateRanks(data);
        final filteredIndices = _getFilteredIndices([data, _searchQuery]);

        // 검색 결과가 없을 때
        if (filteredIndices.isEmpty && _searchQuery.isNotEmpty) {
          return SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 24, left: 16.w, right: 16.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary500, width: 1.r),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(70.r),
                      topRight: Radius.circular(70.r),
                      bottomLeft: Radius.circular(40.r),
                      bottomRight: Radius.circular(40.r),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 56,
                      left: 16.w,
                      right: 16.w,
                      bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
                    ).r,
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).text_no_search_result,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildSearchBox(),
              ],
            ),
          );
        }

        // Tier B1 perf: 실제 슬리버 가상화 리스트.
        // shrinkWrap ListView(전 행 즉시 빌드) 대신 SliverPrototypeExtentList 로
        // 교체 — prototype 행 하나의 실측 높이(ScreenUtil 적용된 device-correct 값)를
        // 모든 행 extent 로 사용해 뷰포트에 보이는 행만 빌드한다(하드코딩 const 없음).
        // 장식 테두리는 DecoratedSliver, 내부/바깥 여백은 SliverPadding 으로 이전.
        //
        // 검색창은 테두리 안 "선두 슬리버"로 배치한다(SliverMainAxisGroup 의
        // 첫 자식). 이렇게 하면:
        //  - 실제 높이를 가진 SliverToBoxAdapter 라 반드시 paint 되고 탭 가능,
        //  - 그룹의 첫 슬리버이므로 리스트와 함께 자연스럽게 스크롤 아웃되며,
        //  - DecoratedSliver 테두리 안쪽에 위치한다.
        // (이전의 0-높이 어댑터 + OverflowBox 오버레이는 paintExtent==0 →
        //  SliverGeometry.visible==false 라 RenderSliverMainAxisGroup 가 paint 를
        //  통째로 스킵 → 검색창이 전혀 안 그려지던 버그를 대체.)
        // 선두 검색창 어댑터가 예전 top:56 예약 밴드를 대신하므로 리스트의
        // 상단 inset 은 작은 간격으로만 둔다.
        return SliverPadding(
          // 바깥 margin(top:24, 좌우 16.w) == 슬리버에서는 바깥 패딩.
          padding: EdgeInsets.only(top: 24, left: 16.w, right: 16.w),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary500, width: 1.r),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(70.r),
                topRight: Radius.circular(70.r),
                bottomLeft: Radius.circular(40.r),
                bottomRight: Radius.circular(40.r),
              ),
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                // 선두 검색창: 예전 top:56 밴드 위치에 들어가며 리스트보다 먼저
                // 배치돼 함께 스크롤 아웃된다. 실제 높이(검색창 48.h + 상하 패딩)를
                // 가지므로 반드시 paint 되고 탭 가능.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8).r,
                    child: _buildSearchBoxContent(),
                  ),
                ),
                // 리스트: 좌우 16.w / 하단 여백. 상단은 검색창 어댑터가 밴드를
                // 차지하므로 작은 간격만 둔다.
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: 8,
                    left: 16.w,
                    right: 16.w,
                    bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
                  ).r,
                  sliver: SliverPrototypeExtentList(
                    // 첫 아이템으로 만든 대표 행을 오프스테이지에서 1회 측정해
                    // 그 높이(행 + bottom-16 gap)를 모든 행 extent 로 사용.
                    prototypeItem: _buildVoteRowPrototype(data, filteredIndices),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // 안전성 체크 (기존 동작 보존)
                        if (index >= filteredIndices.length) {
                          logger.w(
                            '📋 인덱스 초과 - index: $index, filteredLength: ${filteredIndices.length}',
                          );
                          return const SizedBox.shrink();
                        }

                        final itemIndex = filteredIndices[index];
                        if (itemIndex >= data.length) {
                          logger.w(
                            '📋 데이터 인덱스 초과 - itemIndex: $itemIndex, dataLength: ${data.length}',
                          );
                          return const SizedBox.shrink();
                        }

                        final item = data[itemIndex];
                        if (item == null) {
                          logger.w('📋 null 아이템 - itemIndex: $itemIndex');
                          return const SizedBox.shrink();
                        }

                        final previousVoteCount =
                            _previousVoteCounts[item.id] ?? item.voteTotal;
                        final voteCountDiff =
                            item.voteTotal! - previousVoteCount!;
                        final actualRank = _currentRanks[item.id] ?? 1;
                        final previousRank =
                            _previousRanks[item.id] ?? actualRank;
                        final rankChanged = previousRank != actualRank;

                        if (rankChanged) {
                          _triggerHighlight(item.id);
                        }

                        // PostFrameCallback을 더 안전하게 처리
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _previousVoteCounts[item.id] = item.voteTotal!;
                            _previousRanks[item.id] = actualRank;
                          }
                        });

                        return RepaintBoundary(
                          key: ValueKey('vote_item_${item.id}'),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: _buildVoteItemWithHighlight(
                              item: item,
                              index: itemIndex,
                              actualRank: actualRank,
                              voteCountDiff: voteCountDiff,
                              rankChanged: rankChanged,
                              rankUp: previousRank > actualRank,
                              searchQuery: _searchQuery,
                            ),
                          ),
                        );
                      },
                      childCount: filteredIndices.length,
                      addAutomaticKeepAlives: false, // 메모리 최적화 (기존 동작 보존)
                      addRepaintBoundaries: true, // 리페인트 최적화
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        logger.d('⏳ 투표 아이템 로딩 중...');
        // 주의: 부모가 CustomScrollView이므로 내부에 또 다른 CustomScrollView를 넣지 않기 위해
        // 아이템 영역 전용 스켈레톤을 사용한다.
        return SliverToBoxAdapter(child: VoteDetailSkeleton.buildVoteListOnly());
      },
      error: (error, stackTrace) {
        logger.e('❌ 투표 아이템 로딩 실패: $error');
        return SliverToBoxAdapter(
          child: buildErrorView(
            context,
            error: error.toString(),
            stackTrace: stackTrace,
          ),
        );
      },
    );
  }

  Widget _buildVoteItemWithHighlight({
    required VoteItemModel item,
    required int index,
    required int actualRank,
    required int voteCountDiff,
    required bool rankChanged,
    required bool rankUp,
    required String searchQuery,
  }) {
    // 검색어가 있을 때는 커스텀 위젯을 만들어서 하이라이트 적용
    if (searchQuery.isNotEmpty) {
      return _buildCustomVoteItemWithHighlight(
        item: item,
        index: index,
        actualRank: actualRank,
        voteCountDiff: voteCountDiff,
        rankChanged: rankChanged,
        rankUp: rankUp,
        searchQuery: searchQuery,
      );
    }

    // 검색어가 없을 때는 기존 VoteItemWidget 사용
    return VoteItemWidget(
      item: item,
      index: index,
      actualRank: actualRank,
      voteCountDiff: voteCountDiff,
      rankChanged: rankChanged, // 실제 rankChanged 파라미터 사용
      rankUp: rankUp,
      isEnded: isEnded,
      isSaving: _isSaving,
      onTap: () {
        logger.d('🔥 onTap: onTap');
        _handleVoteItemTap(context, item, index);
      },
      artistImage: _buildArtistImage(item, index, actualRank, rankChanged),
      voteCountContainer: _buildVoteCountContainer(item, voteCountDiff),
      rankText: _buildRankText(actualRank, item),
    );
  }

  Widget _buildCustomVoteItemWithHighlight({
    required VoteItemModel item,
    required int index,
    required int actualRank,
    required int voteCountDiff,
    required bool rankChanged,
    required bool rankUp,
    required String searchQuery,
  }) {
    return VoteItemHighlightWidget(
      item: item,
      index: index,
      actualRank: actualRank,
      voteCountDiff: voteCountDiff,
      rankChanged: rankChanged,
      rankUp: rankUp,
      searchQuery: searchQuery,
      isEnded: isEnded,
      isSaving: _isSaving,
      highlightedItemIds: _highlightedItemIds,
      onTap: () => _handleVoteItemTap(context, item, index),
      artistImage: _buildArtistImage(item, index, actualRank, rankChanged),
      voteCountContainer: _buildVoteCountContainer(item, voteCountDiff),
      getMatchingText: _getMatchingText,
      rankText: _buildRankText(actualRank, item),
    );
  }

  Widget _buildCaptureVoteList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return ref
            .watch(
              asyncVoteItemListProvider(
                voteId: widget.voteId,
                votePortal: widget.votePortal,
              ),
            )
            .when(
              data: (data) {
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary500, width: 1.r),
                    borderRadius: BorderRadius.circular(40.r),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      children: [
                        for (int i = 0; i < 3 && i < data.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i < 2 ? 16 : 16,
                            ), // 36에서 16으로 감소
                            child: VoteItemWidget(
                              item: data[i]!,
                              index: i,
                              actualRank: _currentRanks[data[i]!.id] ?? 1,
                              voteCountDiff: 0,
                              rankChanged: false,
                              rankUp: false,
                              isEnded: isEnded,
                              isSaving: _isSaving,
                              onTap: () =>
                                  _handleVoteItemTap(context, data[i]!, i),
                              artistImage: _buildArtistImage(
                                data[i]!,
                                i,
                                _currentRanks[data[i]!.id] ?? 1,
                                false, // 캡처 시에는 순위 변동 없음
                              ),
                              voteCountContainer: _buildVoteCountContainer(
                                data[i]!,
                                0,
                              ),
                              rankText: _buildRankText(
                                _currentRanks[data[i]!.id] ?? 1,
                                data[i]!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            );
      },
    );
  }

  String _buildRankText(int rank, VoteItemModel currentItem) {
    return AppLocalizations.of(context).text_vote_rank(rank);
  }

  /// 상대 경로를 절대 경로로 변환하는 메서드
  String _makeFullImageUrl(String imageUrl) {
    try {
      return VoteDetailHelper.makeFullImageUrl(imageUrl, Environment.cdnUrl);
    } catch (e) {
      logger.e('URL 변환 실패: $e');
      return imageUrl;
    }
  }

  Widget _buildArtistImage(
    VoteItemModel item,
    int index,
    int actualRank,
    bool rankChanged,
  ) {
    try {
      // 이미지 URL을 안전하게 가져오기
      final artistUrl = item.artist?.image ?? '';
      final groupUrl = item.artistGroup?.image ?? '';
      final imageUrl = ((item.artist?.id ?? 0) != 0 ? artistUrl : groupUrl);

      // 상대 경로를 절대 경로로 변환
      final fullImageUrl = _makeFullImageUrl(imageUrl);

      // URL 유효성 검사 강화
      final hasValidImageUrl =
          fullImageUrl.isNotEmpty &&
          (fullImageUrl.startsWith('http://') ||
              fullImageUrl.startsWith('https://'));

      // logger.d('🖼️ URL 유효성 검사 결과: $hasValidImageUrl');

      if (!hasValidImageUrl && imageUrl.isNotEmpty) {
        logger.w(
          '🖼️ 유효하지 않은 이미지 URL - ID: ${item.id}, 원본: "$imageUrl", 전체: "$fullImageUrl"',
        );
      }

      return SizedBox(
        width: 45,
        height: 45,
        child: Container(
          decoration: BoxDecoration(
            gradient: index < 3
                ? [goldGradient, silverGradient, bronzeGradient][index]
                : null,
            color: index >= 3 ? AppColors.grey200.withValues(alpha: 0.5) : null,
            borderRadius: BorderRadius.circular(22.5),
          ),
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19.5),
            child: SizedBox(
              width: 39, // 명시적 크기 지정
              height: 39,
              child: hasValidImageUrl
                  ? _buildNetworkImage(
                      imageUrl,
                      item.id,
                      index,
                      actualRank,
                      rankChanged,
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
        ),
      );
    } catch (e) {
      // 이미지 빌드 에러 발생 시 안전한 폴백 위젯 반환
      logger.e('아티스트 이미지 빌드 에러: $e');
      return _buildErrorFallbackImage();
    }
  }

  Widget _buildNetworkImage(
    String imageUrl,
    int itemId,
    int index,
    int actualRank,
    bool rankChanged,
  ) {
    // 순위 변동 시 이미지 위젯 재생성을 위해 actualRank를 키에 포함
    return RepaintBoundary(
      key: ValueKey('image_${itemId}_rank_$actualRank'),
      child: SizedBox(
        width: 39,
        height: 39,
        child: _buildImageWithFallback(
          imageUrl,
          index: index,
          actualRank: actualRank,
          rankChanged: rankChanged,
        ),
      ),
    );
  }

  Widget _buildImageWithFallback(
    String imageUrl, {
    int? index,
    int? actualRank,
    bool rankChanged = false,
  }) {
    // 대량 아이템(1500개+) 최적화: 뷰포트에 보이는 이미지만 로딩
    // 상위 랭킹(상위 50개)은 높은 우선순위, 나머지는 일반 우선순위
    final isTopRanking = index != null && index < 50;

    // 순위가 변동된 경우 즉시 로딩 (LazyLoadingStrategy.none)
    // 그 외의 경우 뷰포트 기반 지연 로딩 (LazyLoadingStrategy.viewport)
    final lazyLoadingStrategy = rankChanged
        ? LazyLoadingStrategy.none
        : LazyLoadingStrategy.viewport;

    return PicnicCachedNetworkImage(
      key: ValueKey(
        'cached_image_$imageUrl${actualRank != null ? '_rank_$actualRank' : ''}',
      ), // 순위 변동 시 위젯 재생성
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: 39,
      height: 39,
      memCacheWidth: 78, // 2x 해상도로 메모리 캐시 (화면 크기 대비 최적화)
      memCacheHeight: 78,
      placeholder: _buildImagePlaceholder(),
      lazyLoadingStrategy: lazyLoadingStrategy, // 순위 변동 시 즉시 로딩
      visibilityThreshold: 0.1, // 10% 보일 때부터 로딩 시작
      enablePreloading: true, // 뷰포트 근처 200px 전에 미리 로딩
      preloadDistance: 200.0,
      priority: isTopRanking
          ? ImagePriority.high
          : ImagePriority.normal, // 상위 랭킹만 높은 우선순위
      enableMemoryOptimization: true,
      enableProgressiveLoading: true,
      timeout: const Duration(seconds: 15), // 타임아웃을 15초로 증가 (네트워크 상태 고려)
      maxRetries: 2,
    );
  }

  Widget _buildErrorFallbackImage() {
    return SizedBox(
      width: 45,
      height: 45,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey200.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(22.5),
        ),
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19.5),
          child: _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return SizedBox(
      width: 39,
      height: 39,
      child: Container(
        width: 39,
        height: 39,
        color: AppColors.grey200,
        child: Icon(Icons.person, size: 20, color: AppColors.grey400),
      ),
    );
  }

  Widget _buildVoteCountContainer(VoteItemModel item, int voteCountDiff) {
    final hasChanged = voteCountDiff != 0;

    return SizedBox(
      width: double.infinity,
      height: 20,
      child: Stack(
        clipBehavior: Clip.none, // 진행바 위로 배지를 띄워 레이아웃 흔들림 방지
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                gradient: commonGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.only(right: 16.w, bottom: 3),
              alignment: Alignment.centerRight,
              key: ValueKey(hasChanged ? item.voteTotal : 'static'),
              child: hasChanged
                  ? AnimatedDigitWidget(
                      value: item.voteTotal,
                      enableSeparator: true,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      textStyle: getTextStyle(
                        AppTypo.caption10SB,
                        AppColors.grey00,
                      ),
                    )
                  : Text(
                      NumberFormat('#,###').format(item.voteTotal),
                      style: getTextStyle(
                        AppTypo.caption10SB,
                        AppColors.grey00,
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 28,
            child: VoteGainIndicator(diff: voteCountDiff),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoteItemTap(
    BuildContext context,
    VoteItemModel item,
    int index,
  ) async {
    logger.d('🔥 _handleVoteItemTap 호출됨 - index: $index');
    final isAdmin =
        ref.watch(userInfoProvider.select((value) => value.value?.isAdmin)) ??
        false;
    final isJmaVote =
        ref
            .read(
              asyncVoteDetailProvider(
                voteId: widget.voteId,
                votePortal: widget.votePortal,
              ),
            )
            .value!
            .partner
            ?.toLowerCase() ==
        'jma';

    logger.d('🔥 isAdmin: $isAdmin');
    logger.d('🔥 isJmaVote: $isJmaVote');

    if (!isSupabaseLoggedSafely) {
      showRequireLoginDialog();
      return;
    }

    if (await showWithdrawalBlockedDialog(context: context, ref: ref)) {
      return;
    }
    if (!context.mounted) return;

    if (isAdmin && isJmaVote) {
      showVotingDialog(
        context: context,
        voteModel: ref
            .read(
              asyncVoteDetailProvider(
                voteId: widget.voteId,
                votePortal: widget.votePortal,
              ),
            )
            .value!,
        voteItemModel: item,
        portalType: widget.votePortal,
      );
      return;
    }

    if (isEnded) {
      showSimpleDialog(
        content: AppLocalizations.of(context).message_vote_is_ended,
      );
    } else if (isUpcoming) {
      showSimpleDialog(
        content: AppLocalizations.of(context).message_vote_is_upcoming,
      );
    } else {
      showVotingDialog(
        context: context,
        voteModel: ref
            .read(
              asyncVoteDetailProvider(
                voteId: widget.voteId,
                votePortal: widget.votePortal,
              ),
            )
            .value!,
        voteItemModel: item,
        portalType: widget.votePortal,
      );
    }
  }

  Widget _buildApplicationButton(BuildContext context) {
    final voteModel = ref
        .watch(
          asyncVoteDetailProvider(
            voteId: widget.voteId,
            votePortal: widget.votePortal,
          ),
        )
        .value;

    final category = voteModel?.voteCategory?.toLowerCase() ?? '';
    final isWeekly = category.contains('week');

    if (isWeekly) {
      return InkWell(
        onTap: () {
          showSimpleDialog(
            title: AppLocalizations.of(context).weekly_vote_info_title,
            content: AppLocalizations.of(context).weekly_vote_info_body,
            onOk: () => Navigator.of(context, rootNavigator: false).pop(),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_weekly_info.svg',
              package: 'picnic_lib',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 6),
            UnderlinedText(
              text: AppLocalizations.of(context).weekly_vote_info_link,
              textStyle: getTextStyle(AppTypo.body14B, AppColors.primary500),
              underlineColor: AppColors.primary500,
              underlineHeight: 1,
              underlineGap: 1,
            ),
          ],
        ),
      );
    }

    return _buildApplicationGradientButton(context);
  }

  Widget _buildApplicationGradientButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, animationValue, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary500.withValues(alpha: 0.8),
                        AppColors.primary500,
                        AppColors.primary500.withValues(alpha: 0.9),
                        Color.lerp(AppColors.primary500, Colors.black, 0.2)!,
                      ],
                      stops: [
                        0.0 + (animationValue * 0.2),
                        0.3 + (animationValue * 0.2),
                        0.7 + (animationValue * 0.2),
                        1.0,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        logger.d('🔥 투표 신청 버튼 클릭됨!');

                        if (isSupabaseLoggedSafely) {
                          logger.d('🔥 사용자 로그인 상태 확인됨');

                          final voteModel = ref
                              .read(
                                asyncVoteDetailProvider(
                                  voteId: widget.voteId,
                                  votePortal: widget.votePortal,
                                ),
                              )
                              .value;

                          logger.d(
                            '🔥 voteModel 상태: ${voteModel != null ? "존재함" : "null"}',
                          );

                          if (voteModel != null) {
                            logger.d('🔥 showVoteItemRequestDialog 호출 시작');
                            await showVoteItemRequestDialog(
                              context: context,
                              voteModel: voteModel,
                            );
                            logger.d('🔥 showVoteItemRequestDialog 완료');
                          } else {
                            logger.d('🔥 voteModel이 null이어서 다이얼로그를 열 수 없음');
                          }
                        } else {
                          logger.d('🔥 사용자 미로그인 상태 - 로그인 다이얼로그 표시');
                          showRequireLoginDialog();
                        }
                      },
                      child: Container(
                        height: 30,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.bounceOut,
                              builder: (context, iconScale, child) {
                                return Transform.scale(
                                  scale: iconScale,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.how_to_vote_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 8.w),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOutBack,
                              builder: (context, textOpacity, child) {
                                final safeOpacity = textOpacity.clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: safeOpacity,
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).vote_item_request_button,
                                    style:
                                        getTextStyle(
                                          AppTypo.body14B,
                                          AppColors.grey00,
                                        ).copyWith(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.3,
                                              ),
                                              offset: const Offset(0, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Positioned wrapper for the search box, used inside a [Stack] (the
  /// empty-search branch). For the sliver list path the non-positioned
  /// [_buildSearchBoxContent] is hosted directly by a leading
  /// [SliverToBoxAdapter] (a [Positioned] cannot live outside a Stack).
  Widget _buildSearchBox() {
    return Positioned(
      top: 0,
      right: 0.w,
      left: 0.w,
      child: _buildSearchBoxContent(),
    );
  }

  /// The search box content without the [Positioned] wrapper, so it can be
  /// hosted by both a [Stack] (via [_buildSearchBox]) and a leading
  /// [SliverToBoxAdapter] in the non-empty sliver list path.
  Widget _buildSearchBoxContent() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: EnhancedSearchBox(
        hintText: AppLocalizations.of(context).text_vote_where_is_my_bias,
        onSearchChanged: (query) {
          logger.d('🔍 EnhancedSearchBox onSearchChanged 호출됨: "$query"');
          // 로컬 상태 업데이트
          if (mounted) {
            setState(() {
              _searchQuery = query;
            });
            logger.d('🔍 _searchQuery 로컬 상태 업데이트됨: "$query"');
          }
        },
        controller: _textEditingController,
        focusNode: _focusNode,
        debounceTime: const Duration(milliseconds: 300),
        showClearButton: true,
        borderRadius: BorderRadius.circular(24.r),
      ),
    );
  }

  Widget _buildLoadingShimmer() => const VoteDetailSkeleton();
}
