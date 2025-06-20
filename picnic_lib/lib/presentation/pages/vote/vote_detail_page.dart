import 'dart:async';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';

import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_widget.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class VoteDetailPage extends ConsumerStatefulWidget {
  final int voteId;
  final VotePortal votePortal;

  const VoteDetailPage(
      {super.key, required this.voteId, this.votePortal = VotePortal.vote});

  @override
  ConsumerState<VoteDetailPage> createState() => _VoteDetailPageState();
}

class _VoteDetailPageState extends ConsumerState<VoteDetailPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool isEnded = false;
  bool isUpcoming = false;
  final _searchSubject = BehaviorSubject<String>();
  Timer? _updateTimer;
  final Map<int, int> _previousVoteCounts = {};
  final Map<int, int> _previousRanks = {};
  final Map<int, int> _currentRanks = {};

  final GlobalKey _captureKey = GlobalKey(); // 캡쳐 영역을 위한 새 키
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
    _setupUpdateTimer();
    _initializeRanks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: false,
          showTopMenu: true,
          showBottomNavigation: false,
          pageTitle: t('page_title_vote_detail'));
    });
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
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      final _ = ref.refresh(asyncVoteItemListProvider(voteId: widget.voteId));
    });
  }

  void _initializeRanks() {
    final items = ref
        .read(asyncVoteItemListProvider(
            voteId: widget.voteId, votePortal: widget.votePortal))
        .value;
    if (items != null) {
      _updateRanks(items);
    }
  }

  void _updateRanks(List<VoteItemModel?> items) {
    final sortedItems = items.where((item) => item != null).toList()
      ..sort((a, b) => b!.voteTotal!.compareTo(a!.voteTotal!));

    int currentRank = 1;
    int? previousVoteTotal;

    for (var i = 0; i < sortedItems.length; i++) {
      final item = sortedItems[i]!;

      if (previousVoteTotal != null && item.voteTotal == previousVoteTotal) {
        // 같은 순위 유지
      } else {
        currentRank = i + 1;
      }

      _currentRanks[item.id] = currentRank;
      previousVoteTotal = item.voteTotal;
    }
  }

  @override
  void dispose() {
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
      message: getLocaleTextFromJson(ref
          .read(asyncVoteDetailProvider(
              voteId: widget.voteId, votePortal: widget.votePortal))
          .value!
          .title),
      hashtag:
          '#Picnic #Vote #PicnicApp #${getLocaleTextFromJson(ref.read(asyncVoteDetailProvider(voteId: widget.voteId, votePortal: widget.votePortal)).value!.title).replaceAll(' ', '')}',
      downloadLink: await createBranchLink(
          getLocaleTextFromJson(ref
              .read(asyncVoteDetailProvider(
                  voteId: widget.voteId, votePortal: widget.votePortal))
              .value!
              .title),
          '${Environment.appLinkPrefix}/vote/detail/${widget.voteId}'),
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        if (mounted) {
          setState(() => _isSaving = true);
        }
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        if (mounted) {
          setState(() => _isSaving = false);
        }
      },
    );
  }

  void _handleSave() {
    if (_isSaving) return;
    ShareUtils.saveImage(
      context: context,
      _captureKey,
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        if (mounted) {
          setState(() => _isSaving = true);
        }
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
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

  List<int> _getFilteredIndices(List<dynamic> args) {
    final List<VoteItemModel?> data = args[0];
    final String query = args[1];

    // 캐시된 결과가 있는지 확인
    if (query == _lastQuery &&
        data.length == _lastData.length &&
        _cachedFilteredIndices.isNotEmpty) {
      return _cachedFilteredIndices;
    }

    if (query.isEmpty) {
      final result = List<int>.generate(data.length, (index) => index);
      _updateCache(data, query, result);
      return result;
    }

    logger.d('🔍 검색어: "$query"');

    final result =
        List<int>.generate(data.length, (index) => index).where((index) {
      final item = data[index]!;
      final lowerQuery = query.toLowerCase();

      // 아티스트 이름 검색 (한국어 + 영어 + 초성)
      if (item.artist?.id != null && (item.artist?.id ?? 0) != 0) {
        // 한국어 아티스트 이름
        final artistNameKo = item.artist?.name['ko']?.toString() ?? '';
        // 영어 아티스트 이름
        final artistNameEn = item.artist?.name['en']?.toString() ?? '';

        logger.d('👤 아티스트 (한국어): "$artistNameKo"');
        logger.d('👤 아티스트 (영어): "$artistNameEn"');
        logger.d(
            '👤 아티스트 초성: "${KoreanSearchUtils.extractKoreanInitials(artistNameKo)}"');

        if ((artistNameKo.isNotEmpty &&
                (artistNameKo.toLowerCase().contains(lowerQuery) ||
                    KoreanSearchUtils.matchesKoreanInitials(
                        artistNameKo, query))) ||
            (artistNameEn.isNotEmpty &&
                artistNameEn.toLowerCase().contains(lowerQuery))) {
          logger.d('✅ 아티스트 이름 매칭: "$artistNameKo" / "$artistNameEn"');
          return true;
        }

        // 아티스트의 그룹명 검색 (한국어 + 영어 + 초성)
        if (item.artist?.artistGroup?.name != null) {
          final artistGroupNameKo =
              item.artist!.artistGroup!.name['ko']?.toString() ?? '';
          final artistGroupNameEn =
              item.artist!.artistGroup!.name['en']?.toString() ?? '';

          logger.d('🎵 아티스트의 그룹 (한국어): "$artistGroupNameKo"');
          logger.d('🎵 아티스트의 그룹 (영어): "$artistGroupNameEn"');
          logger.d(
              '🎵 아티스트의 그룹 초성: "${KoreanSearchUtils.extractKoreanInitials(artistGroupNameKo)}"');

          if ((artistGroupNameKo.isNotEmpty &&
                  (artistGroupNameKo.toLowerCase().contains(lowerQuery) ||
                      KoreanSearchUtils.matchesKoreanInitials(
                          artistGroupNameKo, query))) ||
              (artistGroupNameEn.isNotEmpty &&
                  artistGroupNameEn.toLowerCase().contains(lowerQuery))) {
            logger.d(
                '✅ 아티스트의 그룹명 매칭: "$artistGroupNameKo" / "$artistGroupNameEn"');
            return true;
          }
        }
      }

      // 직접 그룹 검색 (아티스트가 없고 그룹만 있는 경우) (한국어 + 영어 + 초성)
      if (item.artistGroup?.id != null && (item.artistGroup?.id ?? 0) != 0) {
        final groupNameKo = item.artistGroup?.name['ko']?.toString() ?? '';
        final groupNameEn = item.artistGroup?.name['en']?.toString() ?? '';

        logger.d('🎭 직접 그룹 (한국어): "$groupNameKo"');
        logger.d('🎭 직접 그룹 (영어): "$groupNameEn"');
        logger.d(
            '🎭 직접 그룹 초성: "${KoreanSearchUtils.extractKoreanInitials(groupNameKo)}"');

        if ((groupNameKo.isNotEmpty &&
                (groupNameKo.toLowerCase().contains(lowerQuery) ||
                    KoreanSearchUtils.matchesKoreanInitials(
                        groupNameKo, query))) ||
            (groupNameEn.isNotEmpty &&
                groupNameEn.toLowerCase().contains(lowerQuery))) {
          logger.d('✅ 직접 그룹명 매칭: "$groupNameKo" / "$groupNameEn"');
          return true;
        }
      }

      return false;
    }).toList();

    _updateCache(data, query, result);
    return result;
  }

  // 다국어 텍스트에서 검색어가 포함된 언어의 텍스트를 반환 (초성 검색 포함)
  String _getMatchingText(Map<String, dynamic> nameMap, String query) {
    final lowerQuery = query.toLowerCase();

    // 한국어에서 검색어 찾기 (일반 텍스트 + 초성)
    final koText = nameMap['ko']?.toString() ?? '';
    if (koText.isNotEmpty &&
        (koText.toLowerCase().contains(lowerQuery) ||
            KoreanSearchUtils.matchesKoreanInitials(koText, query))) {
      return koText;
    }

    // 영어에서 검색어 찾기
    final enText = nameMap['en']?.toString() ?? '';
    if (enText.isNotEmpty && enText.toLowerCase().contains(lowerQuery)) {
      return enText;
    }

    // 검색어가 없으면 기본 로케일 텍스트 반환
    return getLocaleTextFromJson(nameMap);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: AppColors.grey00,
          child: ref
              .watch(asyncVoteDetailProvider(
                  voteId: widget.voteId, votePortal: widget.votePortal))
              .when(
                data: (voteModel) {
                  if (voteModel == null) return const SizedBox.shrink();
                  isEnded = voteModel.isEnded!;
                  isUpcoming = voteModel.isUpcoming!;

                  return GestureDetector(
                    onTap: () => _focusNode.unfocus(),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: RepaintBoundary(
                            key: _captureKey,
                            child: Column(
                              children: [
                                _buildVoteInfo(context, voteModel),
                                SizedBox(height: 12),
                                if (_isSaving) _buildCaptureVoteList(context),
                              ],
                            ),
                          ),
                        ),
                        if (!_isSaving) _buildVoteItemList(context),
                      ],
                    ),
                  );
                },
                loading: () => _buildLoadingShimmer(),
                error: (error, stackTrace) => buildErrorView(context,
                    error: error.toString(), stackTrace: stackTrace),
              ),
        ),
      ],
    );
  }

  Widget _buildVoteInfo(BuildContext context, VoteModel voteModel) {
    final width = getPlatformScreenSize(context).width;
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
        const SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 57.w),
          child: VoteCommonTitle(title: getLocaleTextFromJson(voteModel.title)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 18,
          child: Text(
            '${DateFormat('yyyy.MM.dd HH:mm').format(voteModel.startAt!.toLocal())} ~ '
            '${DateFormat('yyyy.MM.dd HH:mm').format(voteModel.stopAt!.toLocal())} '
            '(${getShortTimeZoneIdentifier()})',
            style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
          ),
        ),
        if (voteModel.reward != null && widget.votePortal == VotePortal.vote)
          Column(
            children: [
              Text(
                t('text_vote_rank_in_reward'),
                style: getTextStyle(AppTypo.body14B, AppColors.primary500),
              ),
              ...voteModel.reward!.map((rewardModel) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showRewardDialog(context, rewardModel),
                    child: UnderlinedText(
                      text: getLocaleTextFromJson(rewardModel.title!),
                      textStyle:
                          getTextStyle(AppTypo.caption12R, AppColors.grey900),
                      underlineColor: AppColors.grey700,
                      underlineHeight: .5,
                      underlineGap: 1,
                    ),
                  ))
            ],
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
                saveButtonText: t('save'),
                shareButtonText: t('share'),
                onSave: _handleSave,
                onShare: _handleShare,
              ),
              const SizedBox(height: 12),
            ],
          ),
      ],
    );
  }

  Widget _buildVoteItemList(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    logger.d('🔍 _buildVoteItemList에서 받은 검색어: "$searchQuery"');
    final dataAsync = ref.watch(asyncVoteItemListProvider(
        voteId: widget.voteId, votePortal: widget.votePortal));

    return dataAsync.when(
      data: (data) {
        _updateRanks(data);
        final filteredIndices = _getFilteredIndices([data, searchQuery]);
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
                  padding: EdgeInsets.only(top: 56, left: 16.w, right: 16.w).r,
                  child: filteredIndices.isEmpty && searchQuery.isNotEmpty
                      ? SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(t('text_no_search_result')),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredIndices.length,
                          itemBuilder: (context, index) {
                            // 안전성 체크 추가
                            if (index >= filteredIndices.length) {
                              return const SizedBox.shrink();
                            }

                            final itemIndex = filteredIndices[index];
                            if (itemIndex >= data.length) {
                              return const SizedBox.shrink();
                            }

                            final item = data[itemIndex];
                            if (item == null) {
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

                            // PostFrameCallback을 더 안전하게 처리
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _previousVoteCounts[item.id] = item.voteTotal!;
                                _previousRanks[item.id] = actualRank;
                              }
                            });

                            return RepaintBoundary(
                              key:
                                  ValueKey('vote_item_${item.id}_$searchQuery'),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: 16), // 24에서 16으로 더 감소
                                child: _buildVoteItemWithHighlight(
                                  item: item,
                                  index: itemIndex,
                                  actualRank: actualRank,
                                  voteCountDiff: voteCountDiff,
                                  rankChanged: rankChanged,
                                  rankUp: previousRank > actualRank,
                                  searchQuery: searchQuery,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              _buildSearchBox(),
            ],
          ),
        );
      },
      loading: () => SliverToBoxAdapter(child: _buildLoadingShimmer()),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: buildErrorView(context,
            error: error.toString(), stackTrace: stackTrace),
      ),
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
      rankChanged: rankChanged,
      rankUp: rankUp,
      isEnded: isEnded,
      isSaving: _isSaving,
      onTap: () => _handleVoteItemTap(context, item, index),
      artistImage: _buildArtistImage(item, index),
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
    try {
      // 검색어가 매칭된 언어의 텍스트 가져오기

      return RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: rankChanged
                ? (rankUp
                    ? Colors.blue.withValues(alpha: 0.18)
                    : Colors.red.withValues(alpha: 0.18))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleVoteItemTap(context, item, index),
            child: Container(
              constraints:
                  BoxConstraints(minHeight: 55), // 45에서 55로 증가하여 오버플로우 해결
              padding: EdgeInsets.symmetric(vertical: 6.h), // 패딩도 약간 증가
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 39,
                    height: 45, // 높이를 다시 줄임 (크라운만 표시하므로)
                    child: Center(
                      child: actualRank <= 3
                          ? SvgPicture.asset(
                              package: 'picnic_lib',
                              'assets/icons/vote/crown$actualRank.svg',
                              height: 24, // 크라운 크기를 더 크게 하여 잘 보이게
                              width: 24,
                            )
                          : Text(
                              actualRank.toString(), // 4위 이하는 숫자만 표시
                              style: getTextStyle(AppTypo.body16B,
                                  AppColors.point900), // 더 큰 폰트
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildArtistImage(item, index),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 검색어 하이라이트가 적용된 이름 표시 (한줄로 표시)
                        RichText(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1, // 2줄에서 1줄로 변경
                          text: TextSpan(
                            style: getTextStyle(
                                AppTypo.body14B, AppColors.grey900),
                            children: (item.artist?.id ?? 0) != 0
                                ? [
                                    // 아티스트 이름에 하이라이트 적용
                                    ...KoreanSearchUtils
                                        .buildHighlightedTextSpans(
                                      item.artist?.name != null
                                          ? _getMatchingText(
                                              item.artist!.name, searchQuery)
                                          : '',
                                      searchQuery,
                                    ),
                                    // 아티스트의 그룹명을 괄호 안에 작게 표시 (그룹명이 실제로 존재할 때만)
                                    if (item.artist?.artistGroup?.name !=
                                            null &&
                                        _getMatchingText(
                                                item.artist!.artistGroup!.name,
                                                searchQuery)
                                            .isNotEmpty)
                                      TextSpan(
                                        text: ' (',
                                        style: getTextStyle(AppTypo.caption10SB,
                                            AppColors.grey600),
                                      ),
                                    if (item.artist?.artistGroup?.name !=
                                            null &&
                                        _getMatchingText(
                                                item.artist!.artistGroup!.name,
                                                searchQuery)
                                            .isNotEmpty)
                                      ...KoreanSearchUtils
                                          .buildHighlightedTextSpans(
                                        _getMatchingText(
                                            item.artist!.artistGroup!.name,
                                            searchQuery),
                                        searchQuery,
                                        baseStyle: getTextStyle(
                                            AppTypo.caption10SB,
                                            AppColors.grey600),
                                      ),
                                    if (item.artist?.artistGroup?.name !=
                                            null &&
                                        _getMatchingText(
                                                item.artist!.artistGroup!.name,
                                                searchQuery)
                                            .isNotEmpty)
                                      TextSpan(
                                        text: ')',
                                        style: getTextStyle(AppTypo.caption10SB,
                                            AppColors.grey600),
                                      ),
                                  ]
                                : [
                                    // 그룹명에 하이라이트 적용
                                    ...KoreanSearchUtils
                                        .buildHighlightedTextSpans(
                                      item.artistGroup?.name != null
                                          ? _getMatchingText(
                                              item.artistGroup!.name,
                                              searchQuery)
                                          : '',
                                      searchQuery,
                                    ),
                                  ],
                          ),
                        ),
                        SizedBox(height: 4.h), // 6.h에서 4.h로 감소
                        _buildVoteCountContainer(item, voteCountDiff),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  if (!isEnded && !_isSaving)
                    SizedBox(
                      width: 24.w,
                      height: 24,
                      child: SvgPicture.asset(
                          package: 'picnic_lib',
                          'assets/icons/star_candy_icon.svg'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      // 커스텀 하이라이트 위젯 빌드 에러 발생 시 기본 위젯으로 폴백
      logger.e('커스텀 하이라이트 위젯 빌드 에러: $e');
      return VoteItemWidget(
        item: item,
        index: index,
        actualRank: actualRank,
        voteCountDiff: voteCountDiff,
        rankChanged: rankChanged,
        rankUp: rankUp,
        isEnded: isEnded,
        isSaving: _isSaving,
        onTap: () => _handleVoteItemTap(context, item, index),
        artistImage: _buildArtistImage(item, index),
        voteCountContainer: _buildVoteCountContainer(item, voteCountDiff),
        rankText: _buildRankText(actualRank, item),
      );
    }
  }

  Widget _buildCaptureVoteList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return ref
            .watch(asyncVoteItemListProvider(
                voteId: widget.voteId, votePortal: widget.votePortal))
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
                                bottom: i < 2 ? 16 : 16), // 36에서 16으로 감소
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
                              artistImage: _buildArtistImage(data[i]!, i),
                              voteCountContainer:
                                  _buildVoteCountContainer(data[i]!, 0),
                              rankText: _buildRankText(
                                  _currentRanks[data[i]!.id] ?? 1, data[i]!),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
      },
    );
  }

  String _buildRankText(int rank, VoteItemModel currentItem) {
    return t('text_vote_rank', {'rank': rank.toString()});
  }

  Widget _buildArtistImage(VoteItemModel item, int index) {
    try {
      // 이미지 URL을 안전하게 가져오기
      final imageUrl = ((item.artist?.id ?? 0) != 0
              ? item.artist?.image
              : item.artistGroup?.image) ??
          '';

      // 빈 URL일 경우 기본 플레이스홀더 표시
      final hasValidImageUrl = imageUrl.isNotEmpty;

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
                  ? RepaintBoundary(
                      child: PicnicCachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: 39,
                        height: 39,
                        memCacheWidth: 39, // 실제 크기와 일치
                        memCacheHeight: 39,
                        placeholder: _buildImagePlaceholder(),
                      ),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
        ),
      );
    } catch (e) {
      // 이미지 빌드 에러 발생 시 안전한 폴백 위젯 반환
      logger.e('아티스트 이미지 빌드 에러: $e');
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
  }

  Widget _buildImagePlaceholder() {
    return SizedBox(
      width: 39,
      height: 39,
      child: Container(
        width: 39,
        height: 39,
        color: AppColors.grey200,
        child: Icon(
          Icons.person,
          size: 20,
          color: AppColors.grey400,
        ),
      ),
    );
  }

  Widget _buildVoteCountContainer(VoteItemModel item, int voteCountDiff) {
    final hasChanged = voteCountDiff != 0;

    return SizedBox(
      width: double.infinity,
      height: voteCountDiff > 0 ? 30 : 20, // 애니메이션이 있을 때 높이를 30으로 적당히 조정
      child: Stack(
        clipBehavior: Clip.hardEdge, // 오버플로우를 방지하여 에러 해결
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
                      textStyle:
                          getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                    )
                  : Text(
                      NumberFormat('#,###').format(item.voteTotal),
                      style:
                          getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                    ),
            ),
          ),
          if (voteCountDiff > 0)
            Positioned(
              right: 16.w,
              bottom: 18, // top: 0 대신 bottom을 사용하여 더 안정적인 위치 지정
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  // opacity 값이 0.0~1.0 범위를 벗어나지 않도록 보장
                  final opacity = (1 - value).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, -5 * value), // -10에서 -5로 줄여서 오버플로우 방지
                      child: Text(
                        '+$voteCountDiff',
                        style: getTextStyle(
                            AppTypo.caption10SB, AppColors.primary500),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _handleVoteItemTap(BuildContext context, VoteItemModel item, int index) {
    if (isEnded) {
      showSimpleDialog(content: t('message_vote_is_ended'));
    } else if (isUpcoming) {
      showSimpleDialog(content: t('message_vote_is_upcoming'));
    } else {
      isSupabaseLoggedSafely
          ? showVotingDialog(
              context: context,
              voteModel: ref
                  .read(asyncVoteDetailProvider(
                      voteId: widget.voteId, votePortal: widget.votePortal))
                  .value!,
              voteItemModel: item,
              portalType: widget.votePortal,
            )
          : showRequireLoginDialog();
    }
  }

  Widget _buildApplicationButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.primary500.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
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
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        logger.d('🔥 투표 신청 버튼 클릭됨!');

                        if (isSupabaseLoggedSafely) {
                          logger.d('🔥 사용자 로그인 상태 확인됨');

                          // 신청 다이얼로그 표시
                          final voteModel = ref
                              .read(asyncVoteDetailProvider(
                                  voteId: widget.voteId,
                                  votePortal: widget.votePortal))
                              .value;

                          logger.d(
                              '🔥 voteModel 상태: ${voteModel != null ? "존재함" : "null"}');

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
                        height: 36,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.how_to_vote_rounded,
                                      color: Colors.white,
                                      size: 16,
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
                                // opacity 값이 0.0~1.0 범위를 벗어나지 않도록 보장
                                final safeOpacity = textOpacity.clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: safeOpacity,
                                  child: Text(
                                    t('vote_item_request_button'),
                                    style: getTextStyle(
                                            AppTypo.body14B, AppColors.grey00)
                                        .copyWith(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
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

  Widget _buildSearchBox() {
    return Positioned(
      top: 0,
      right: 0.w,
      left: 0.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: EnhancedSearchBox(
          hintText: t('text_vote_where_is_my_bias'),
          onSearchChanged: (query) {
            logger.d('🔍 EnhancedSearchBox onSearchChanged 호출됨: "$query"');
            // 직접 searchQueryProvider 업데이트
            if (mounted) {
              ref.read(searchQueryProvider.notifier).state = query;
              logger.d('🔍 searchQueryProvider 직접 업데이트됨: "$query"');
            }
          },
          controller: _textEditingController,
          focusNode: _focusNode,
          debounceTime: const Duration(milliseconds: 300),
          showClearButton: true,
          borderRadius: BorderRadius.circular(24.r),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSkeleton(),
                const SizedBox(height: 20),
                _buildTitleSkeleton(),
                const SizedBox(height: 12),
                _buildDateSkeleton(),
                const SizedBox(height: 12),
                _buildButtonSkeleton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _buildVoteListSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 57.w),
      child: Column(
        children: [
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 24,
            width: 200.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSkeleton() {
    return Center(
      child: Container(
        height: 18,
        width: 250.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

  Widget _buildButtonSkeleton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: Container(
          width: 120.w,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
          ),
        ),
      ),
    );
  }

  Widget _buildVoteListSkeleton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 24, left: 16.w, right: 16.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.r),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70.r),
          topRight: Radius.circular(70.r),
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
        color: Colors.white,
      ),
      child: Padding(
        padding:
            EdgeInsets.only(top: 56, left: 16.w, right: 16.w, bottom: 24).r,
        child: Column(
          children: [
            // 검색박스 스켈레톤
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            const SizedBox(height: 24),
            // 투표 아이템들 스켈레톤
            ...List.generate(5, (index) => _buildVoteItemSkeleton(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteItemSkeleton(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Row(
        children: [
          // 순위 영역
          SizedBox(
            width: 39,
            child: Column(
              children: [
                if (index < 3)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // 아티스트 이미지
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          // 이름과 투표수 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          // 투표 아이콘
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
    );
  }
}
