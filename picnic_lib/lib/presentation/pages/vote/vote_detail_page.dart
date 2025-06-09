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
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_widget.dart';

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
  bool _isRedBackground = false; // 배경색 점멸용 변수 추가
  bool _shouldShowAnimation = false; // 애니메이션 표시 조건 변수 추가

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
    _textEditingController.addListener(_onSearchQueryChange);

    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((query) {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = query;
      }
    });
  }

  void _setupUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (!_shouldShowAnimation) return; // 조건이 아닐 때는 점멸하지 않음
      setState(() {
        _isRedBackground = true;
      });
      ref.refresh(asyncVoteItemListProvider(voteId: widget.voteId));
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _isRedBackground = false;
        });
      });
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

  void _onSearchQueryChange() {
    _searchSubject.add(_textEditingController.text);
    if (_hasFocus) {
      _scrollToSearchBox();
    }
  }

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
        setState(() => _isSaving = true);
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() => _isSaving = false);
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
        setState(() => _isSaving = true);
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() => _isSaving = false);
      },
    );
  }

  // 한국어 초성 추출 함수
  String _extractKoreanInitials(String text) {
    const initials = [
      'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
      'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
    ];
    
    String result = '';
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);
      
      // 한글 완성형 문자인지 확인 (가-힣)
      if (code >= 0xAC00 && code <= 0xD7A3) {
        // 초성 추출: (문자코드 - 0xAC00) / (21 * 28)
        final initialIndex = (code - 0xAC00) ~/ (21 * 28);
        result += initials[initialIndex];
      } else {
        // 한글이 아닌 문자는 그대로 추가
        result += char;
      }
    }
    return result;
  }

  // 초성 검색 매칭 함수
  bool _matchesKoreanInitials(String text, String query) {
    if (text.isEmpty || query.isEmpty) return false;
    
    final textInitials = _extractKoreanInitials(text).toLowerCase();
    final queryLower = query.toLowerCase();
    
    // 일반 텍스트 검색도 포함
    if (text.toLowerCase().contains(queryLower)) {
      return true;
    }
    
    // 초성 검색
    if (textInitials.contains(queryLower)) {
      return true;
    }
    
    return false;
  }

  List<int> _getFilteredIndices(List<dynamic> args) {
    final List<VoteItemModel?> data = args[0];
    final String query = args[1];
    if (query.isEmpty) {
      return List<int>.generate(data.length, (index) => index);
    }

    print('🔍 검색어: "$query"');
    
    return List<int>.generate(data.length, (index) => index).where((index) {
      final item = data[index]!;
      final lowerQuery = query.toLowerCase();
      
      // 아티스트 이름 검색 (한국어 + 영어 + 초성)
      if (item.artist?.id != null && (item.artist?.id ?? 0) != 0) {
        // 한국어 아티스트 이름
        final artistNameKo = item.artist?.name?['ko']?.toString() ?? '';
        // 영어 아티스트 이름
        final artistNameEn = item.artist?.name?['en']?.toString() ?? '';
        
        print('👤 아티스트 (한국어): "$artistNameKo"');
        print('👤 아티스트 (영어): "$artistNameEn"');
        print('👤 아티스트 초성: "${_extractKoreanInitials(artistNameKo)}"');
        
        if (_matchesKoreanInitials(artistNameKo, query) || 
            artistNameEn.toLowerCase().contains(lowerQuery)) {
          print('✅ 아티스트 이름 매칭: "$artistNameKo" / "$artistNameEn"');
          return true;
        }
        
        // 아티스트의 그룹명 검색 (한국어 + 영어 + 초성)
        if (item.artist?.artistGroup?.name != null) {
          final artistGroupNameKo = item.artist!.artistGroup!.name['ko']?.toString() ?? '';
          final artistGroupNameEn = item.artist!.artistGroup!.name['en']?.toString() ?? '';
          
          print('🎵 아티스트의 그룹 (한국어): "$artistGroupNameKo"');
          print('🎵 아티스트의 그룹 (영어): "$artistGroupNameEn"');
          print('🎵 아티스트의 그룹 초성: "${_extractKoreanInitials(artistGroupNameKo)}"');
          
          if (_matchesKoreanInitials(artistGroupNameKo, query) ||
              artistGroupNameEn.toLowerCase().contains(lowerQuery)) {
            print('✅ 아티스트의 그룹명 매칭: "$artistGroupNameKo" / "$artistGroupNameEn"');
            return true;
          }
        }
      }
      
      // 직접 그룹 검색 (아티스트가 없고 그룹만 있는 경우) (한국어 + 영어 + 초성)
      if (item.artistGroup?.id != null && (item.artistGroup?.id ?? 0) != 0) {
        final groupNameKo = item.artistGroup?.name['ko']?.toString() ?? '';
        final groupNameEn = item.artistGroup?.name['en']?.toString() ?? '';
        
        print('🎭 직접 그룹 (한국어): "$groupNameKo"');
        print('🎭 직접 그룹 (영어): "$groupNameEn"');
        print('🎭 직접 그룹 초성: "${_extractKoreanInitials(groupNameKo)}"');
        
        if (_matchesKoreanInitials(groupNameKo, query) ||
            groupNameEn.toLowerCase().contains(lowerQuery)) {
          print('✅ 직접 그룹명 매칭: "$groupNameKo" / "$groupNameEn"');
          return true;
        }
      }
      
      return false;
    }).toList();
  }

  // 검색어 하이라이트를 위한 헬퍼 메서드 (한국어/영어/초성 모두 지원)
  List<TextSpan> _buildHighlightedText(String text, String query) {
    if (query.isEmpty || text.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    // 일반 텍스트 검색 시도
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    if (index != -1) {
      // 일반 텍스트 검색 하이라이트
      while (index != -1) {
        // 하이라이트 이전 텍스트 추가
        if (index > start) {
          spans.add(TextSpan(text: text.substring(start, index)));
        }
        
        // 심플한 형광펜 하이라이트 효과
        spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: AppColors.primary500.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ));
        
        start = index + query.length;
        index = lowerText.indexOf(lowerQuery, start);
      }
      
      // 남은 텍스트 추가
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start)));
      }
    } else {
      // 초성 검색인지 확인
      final textInitials = _extractKoreanInitials(text).toLowerCase();
      if (textInitials.contains(lowerQuery)) {
        // 초성 검색의 경우 전체 텍스트를 하이라이트
        spans.add(TextSpan(
          text: text,
          style: TextStyle(
            backgroundColor: AppColors.primary500.withOpacity(0.3),
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ));
      } else {
        // 매칭되지 않는 경우 일반 텍스트
        spans.add(TextSpan(text: text));
      }
    }
    
    return spans;
  }

  // 다국어 텍스트에서 검색어가 포함된 언어의 텍스트를 반환 (초성 검색 포함)
  String _getMatchingText(Map<String, dynamic> nameMap, String query) {
    final lowerQuery = query.toLowerCase();
    
    // 한국어에서 검색어 찾기 (일반 텍스트 + 초성)
    final koText = nameMap['ko']?.toString() ?? '';
    if (_matchesKoreanInitials(koText, query)) {
      return koText;
    }
    
    // 영어에서 검색어 찾기
    final enText = nameMap['en']?.toString() ?? '';
    if (enText.toLowerCase().contains(lowerQuery)) {
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
                  final now = DateTime.now();
                  final stopAt = voteModel.stopAt!;
                  final isOngoing = !isEnded && !isUpcoming;
                  final isLessThan10MinutesLeft =
                      stopAt.difference(now).inMinutes <= 10 &&
                          stopAt.isAfter(now);
                  _shouldShowAnimation = isOngoing && isLessThan10MinutesLeft;

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
                                SizedBox(height: 24),
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
        if (_shouldShowAnimation)
          AnimatedOpacity(
            opacity: _isRedBackground ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: AppColors.primary500.withOpacity(0.18),
              width: double.infinity,
              height: double.infinity,
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
        const SizedBox(height: 36),
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
                              key: ValueKey('vote_item_${item.id}_$searchQuery'),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 36),
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
    // 검색어가 매칭된 언어의 텍스트 가져오기
    final artistName = item.artist?.name != null 
        ? _getMatchingText(item.artist!.name, searchQuery)
        : '';
    final groupName = item.artistGroup?.name != null 
        ? _getMatchingText(item.artistGroup!.name, searchQuery)
        : '';
    
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: rankChanged
              ? (rankUp
                  ? Colors.blue.withOpacity(0.18)
                  : Colors.red.withOpacity(0.18))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleVoteItemTap(context, item, index),
          child: SizedBox(
            height: 45,
            child: Row(
              children: [
                SizedBox(
                  width: 39,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (actualRank <= 3)
                        SvgPicture.asset(
                          package: 'picnic_lib',
                          'assets/icons/vote/crown$actualRank.svg',
                        ),
                      Text(
                        _buildRankText(actualRank, item),
                        style: getTextStyle(
                            AppTypo.caption12B, AppColors.point900),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _buildArtistImage(item, index),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 검색어 하이라이트가 적용된 이름 표시
                      RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                          children: (item.artist?.id ?? 0) != 0
                              ? [
                                  // 아티스트 이름에 하이라이트 적용
                                  ..._buildHighlightedText(
                                    item.artist?.name != null 
                                        ? _getMatchingText(item.artist!.name, searchQuery)
                                        : '',
                                    searchQuery,
                                  ),
                                  const TextSpan(text: ' '),
                                  // 아티스트의 그룹명에도 하이라이트 적용
                                  if (item.artist?.artistGroup?.name != null)
                                    ..._buildHighlightedText(
                                      _getMatchingText(item.artist!.artistGroup!.name, searchQuery),
                                      searchQuery,
                                    ).map((span) => TextSpan(
                                      text: span.text,
                                      style: span.style?.copyWith(
                                        color: AppColors.grey600,
                                        fontSize: getTextStyle(AppTypo.caption10SB, AppColors.grey600).fontSize,
                                      ) ?? getTextStyle(AppTypo.caption10SB, AppColors.grey600),
                                    )),
                                ]
                              : [
                                  // 그룹명에 하이라이트 적용
                                  ..._buildHighlightedText(
                                    item.artistGroup?.name != null 
                                        ? _getMatchingText(item.artistGroup!.name, searchQuery)
                                        : '',
                                    searchQuery,
                                  ),
                                ],
                        ),
                      ),
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
                            padding: EdgeInsets.only(bottom: i < 2 ? 36 : 16),
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
    return Container(
      decoration: BoxDecoration(
        gradient: index < 3
            ? [goldGradient, silverGradient, bronzeGradient][index]
            : null,
        color: index >= 3 ? AppColors.grey200.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(22.5),
      ),
      padding: const EdgeInsets.all(3),
      width: 45,
      height: 45,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: PicnicCachedNetworkImage(
          imageUrl: ((item.artist?.id ?? 0) != 0
                  ? item.artist?.image
                  : item.artistGroup?.image) ??
              '',
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          memCacheWidth: 80,
          memCacheHeight: 80,
        ),
      ),
    );
  }

  Widget _buildVoteCountContainer(VoteItemModel item, int voteCountDiff) {
    final hasChanged = voteCountDiff != 0;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          width: double.infinity,
          height: 20,
          decoration: BoxDecoration(
            gradient: commonGradient,
            borderRadius: BorderRadius.circular(10.r),
          ),
          key: ValueKey(hasChanged ? item.voteTotal : 'static'),
        ),
        Container(
          width: double.infinity,
          height: 20,
          padding: EdgeInsets.only(right: 16.w, bottom: 3),
          alignment: Alignment.centerRight,
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
                  style: getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                ),
        ),
        if (voteCountDiff > 0)
          Positioned(
            right: 16.w,
            top: -15,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(0, -10 * value),
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
    );
  }

  void _handleVoteItemTap(BuildContext context, VoteItemModel item, int index) {
    if (isEnded) {
      showSimpleDialog(content: t('message_vote_is_ended'));
    } else if (isUpcoming) {
      showSimpleDialog(content: t('message_vote_is_upcoming'));
    } else {
      supabase.isLogged
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
            // 안전한 상태 업데이트
            if (mounted) {
              try {
                ref.read(searchQueryProvider.notifier).state = query;
              } catch (e) {
                // 상태 업데이트 실패 시 로그만 남기고 계속 진행
                print('Search state update failed: $e');
              }
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 24,
                width: 250.w,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 16,
                width: 200.w,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 18,
                width: 180.w,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                height: 16,
                width: 150.w,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 280.w,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < 5; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      width: 45.w,
                      height: 45,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: 120.w,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
