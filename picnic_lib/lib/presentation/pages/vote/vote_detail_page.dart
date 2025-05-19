import 'dart:async';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/common_search_box.dart';
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

class _VoteDetailPageState extends ConsumerState<VoteDetailPage> {
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

  List<int> _getFilteredIndices(List<dynamic> args) {
    final List<VoteItemModel?> data = args[0];
    final String query = args[1];
    if (query.isEmpty) {
      return List<int>.generate(data.length, (index) => index);
    }

    return List<int>.generate(data.length, (index) => index).where((index) {
      final item = data[index]!;
      return item.artist.id != 0 &&
              getLocaleTextFromJson(item.artist.name)
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
          item.artist.id != 0 &&
              getLocaleTextFromJson(item.artistGroup.name)
                  .toLowerCase()
                  .contains(query.toLowerCase());
    }).toList();
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
                            final itemIndex = filteredIndices[index];
                            final item = data[itemIndex]!;
                            final previousVoteCount =
                                _previousVoteCounts[item.id] ?? item.voteTotal;
                            final voteCountDiff =
                                item.voteTotal! - previousVoteCount!;
                            final actualRank = _currentRanks[item.id] ?? 1;
                            final previousRank =
                                _previousRanks[item.id] ?? actualRank;
                            final rankChanged = previousRank != actualRank;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _previousVoteCounts[item.id] = item.voteTotal!;
                              _previousRanks[item.id] = actualRank;
                            });
                            return Padding(
                              padding: EdgeInsets.only(bottom: 36),
                              child: VoteItemWidget(
                                item: item,
                                index: itemIndex,
                                actualRank: actualRank,
                                voteCountDiff: voteCountDiff,
                                rankChanged: rankChanged,
                                rankUp: previousRank > actualRank,
                                isEnded: isEnded,
                                isSaving: _isSaving,
                                onTap: () => _handleVoteItemTap(
                                    context, item, itemIndex),
                                artistImage: _buildArtistImage(item, itemIndex),
                                voteCountContainer: _buildVoteCountContainer(
                                    item, voteCountDiff),
                                rankText: _buildRankText(actualRank, item),
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
          imageUrl: (item.artist.id != 0
                  ? item.artist.image
                  : item.artistGroup.image) ??
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
        child: CommonSearchBox(
          focusNode: _focusNode,
          textEditingController: _textEditingController,
          hintText: t('text_vote_where_is_my_bias'),
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
