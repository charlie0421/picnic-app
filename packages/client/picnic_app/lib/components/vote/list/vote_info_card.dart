import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_footer.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_header.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_achieve.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_vertical.dart';
import 'package:picnic_app/providers/config_service.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_app/pages/vote/vote_detail_page.dart';
import 'package:picnic_app/providers/global_media_query.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/vote_share_util.dart';

class VoteInfoCard extends ConsumerStatefulWidget {
  const VoteInfoCard({
    super.key,
    required this.context,
    required this.vote,
    required this.status,
    this.votePortal = VotePortal.vote,
  });

  final BuildContext context;
  final VoteModel vote;
  final VoteStatus status;
  final VotePortal votePortal;

  @override
  ConsumerState<VoteInfoCard> createState() => _VoteInfoCardState();
}

class _VoteInfoCardState extends ConsumerState<VoteInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;
  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isAdLoading = true;
  int _retryCount = 0;
  static const int maxRetries = 5;
  Timer? _retryTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_disposed) {
        _loadAds();
      }
    });
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, .5, curve: Curves.easeOut),
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _loadAds() async {
    if (_disposed || _retryCount >= maxRetries) {
      safeSetState(() {
        _isAdLoading = false;
      });
      return;
    }

    safeSetState(() {
      _isAdLoading = true;
      _isBannerLoaded = false;
    });

    try {
      await _bannerAd?.dispose();
      _bannerAd = null;

      final configService = ref.read(configServiceProvider);
      String? adUnitId = isIOS()
          ? await configService.getConfig('ADMOB_IOS_COMPLETE_VOTE_SHARE')
          : await configService.getConfig('ADMOB_ANDROID_COMPLETE_VOTE_SHARE');

      if (adUnitId == null) {
        throw Exception('Ad unit ID is null');
      }

      final completer = Completer<void>();
      Timer? timeoutTimer;

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.largeBanner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            timeoutTimer?.cancel();
            if (!_disposed) {
              safeSetState(() {
                _isBannerLoaded = true;
                _isAdLoading = false;
                _retryCount = 0;
              });
              completer.complete();
            }
          },
          onAdFailedToLoad: (ad, error) {
            timeoutTimer?.cancel();
            ad.dispose();
            _retryCount++;

            if (!_disposed && _retryCount < maxRetries) {
              final delay = math.min(math.pow(2, _retryCount).toInt(), 16);
              _retryTimer?.cancel();
              _retryTimer = Timer(Duration(seconds: delay), () {
                if (!_disposed) {
                  _loadAds();
                }
              });
            } else {
              safeSetState(() {
                _isAdLoading = false;
              });
            }
            completer.completeError(error);
          },
        ),
      );

      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted && !_disposed) {
          _bannerAd?.dispose();
          _retryCount++;
          if (_retryCount < maxRetries) {
            _loadAds();
          } else {
            safeSetState(() {
              _isAdLoading = false;
            });
          }
          completer.completeError('Ad load timeout');
        }
      });

      await _bannerAd!.load();
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (!_disposed) {
            _loadAds();
          }
        },
      );
    } catch (e) {
      if (!_disposed) {
        _retryCount++;
        if (_retryCount < maxRetries) {
          _retryTimer?.cancel();
          _retryTimer = Timer(
            Duration(seconds: math.min(math.pow(2, _retryCount).toInt(), 16)),
            () {
              if (!_disposed) {
                _loadAds();
              }
            },
          );
        } else {
          safeSetState(() {
            _isAdLoading = false;
          });
        }
      }
    }
  }

  void _restartAnimation() {
    _controller.reset();
    _controller.forward();
  }

  Future<void> _handleRefresh() async {
    await ref.refresh(asyncVoteDetailProvider(
            voteId: widget.vote.id, votePortal: widget.votePortal)
        .future);
    await ref.refresh(asyncVoteItemListProvider(voteId: widget.vote.id).future);
    _restartAnimation();
  }

  void _handleSaveImage() async {
    await VoteShareUtils.captureAndSaveImage(
      _globalKey,
      context,
      onStart: () => setState(() => _isSaving = true),
      onComplete: () => setState(() => _isSaving = false),
    );
  }

  void _handleShareToTwitter() async {
    await VoteShareUtils.shareToTwitter(
      _globalKey,
      context,
      title: getLocaleTextFromJson(widget.vote.title),
      onStart: () => setState(() => _isSaving = true),
      onComplete: () => setState(() => _isSaving = false),
    );
  }

  @override
  void didUpdateWidget(VoteInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vote.id != widget.vote.id) {
      _retryCount = 0;
      _retryTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_disposed) {
          _loadAds();
        }
      });
    }
  }

  void safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncVoteDetail = ref.watch(asyncVoteDetailProvider(
        voteId: widget.vote.id, votePortal: widget.votePortal));
    final asyncVoteItemList = ref.watch(asyncVoteItemListProvider(
        voteId: widget.vote.id, votePortal: widget.votePortal));

    return RepaintBoundary(
      key: _globalKey,
      child: Container(
        color: AppColors.grey00,
        child: asyncVoteDetail.when(
          data: (vote) => _buildCard(context, vote, asyncVoteItemList),
          loading: () => buildLoadingOverlay(),
          error: (error, stack) => Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, VoteModel? vote,
      AsyncValue<List<VoteItemModel?>> asyncVoteItemList) {
    if (vote == null) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navigationInfoNotifier =
            ref.read(navigationInfoProvider.notifier);
        navigationInfoNotifier.setCurrentPage(
          vote.voteCategory == VoteCategory.achieve.name
              ? VoteDetailAchievePage(
                  voteId: widget.vote.id, votePortal: widget.votePortal)
              : VoteDetailPage(
                  voteId: widget.vote.id, votePortal: widget.votePortal),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.cw),
        margin: EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          children: [
            VoteCardInfoHeader(
              title: getLocaleTextFromJson(vote.title),
              stopAt: widget.status == VoteStatus.upcoming
                  ? vote.startAt!
                  : vote.stopAt!,
              onRefresh:
                  widget.status == VoteStatus.active ? _handleRefresh : null,
              status: widget.status,
            ),
            if (widget.status == VoteStatus.active ||
                widget.status == VoteStatus.end)
              if (vote.voteCategory != VoteCategory.achieve.name)
                _buildVoteItemList(asyncVoteItemList),
            if (widget.status == VoteStatus.active ||
                widget.status == VoteStatus.end)
              if (vote.voteCategory == VoteCategory.achieve.name)
                _buildAchieveVoteItemList(asyncVoteItemList),
            if (widget.status == VoteStatus.end) ...[
              if (!_isAdLoading && _isBannerLoaded && _bannerAd != null)
                Stack(
                  children: [
                    if (!_isSaving)
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 24),
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        color: Colors.white,
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    if (_isSaving)
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(top: 24),
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        color: Colors.white,
                        child: Image.asset(
                          'assets/images/vote/banner_complete_bottom_${Intl.getCurrentLocale() == "ko" ? 'ko' : 'en'}.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                )
              else if (_isAdLoading)
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(top: 24),
                  width: AdSize.largeBanner.width.toDouble(),
                  height: AdSize.largeBanner.height.toDouble(),
                  color: Colors.white,
                ),
              if (!_isSaving && (!_isAdLoading || !_isBannerLoaded))
                VoteCardInfoFooter(
                  saveButtonText: S.of(context).vote_result_save_button,
                  shareButtonText: S.of(context).vote_result_share_button,
                  onSave: _handleSaveImage,
                  onShare: _handleShareToTwitter,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoteItemList(
      AsyncValue<List<VoteItemModel?>> asyncVoteItemList) {
    return asyncVoteItemList.when(
      data: (voteItems) {
        if (voteItems.isEmpty) {
          return const Center(child: Text('No vote items available'));
        }

        final paddedItems = [...voteItems];
        while (paddedItems.length < 3) {
          paddedItems.add(null);
        }

        return Container(
          width: ref.watch(globalMediaQueryProvider).size.width,
          height: 260,
          padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
          margin: const EdgeInsets.only(top: 24),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40).r,
            border: Border.all(
              color: AppColors.primary500,
              width: 1.5.cw,
            ),
          ),
          child: SlideTransition(
            position: _offsetAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (paddedItems[1] != null)
                  VoteCardColumnVertical(
                    rank: 2,
                    voteItem: paddedItems[1]!,
                    opacityAnimation: _opacityAnimation,
                    status: widget.status,
                  ),
                if (paddedItems[0] != null)
                  VoteCardColumnVertical(
                    rank: 1,
                    voteItem: paddedItems[0]!,
                    opacityAnimation: _opacityAnimation,
                    status: widget.status,
                  ),
                if (paddedItems[2] != null)
                  VoteCardColumnVertical(
                    rank: 3,
                    voteItem: paddedItems[2]!,
                    opacityAnimation: _opacityAnimation,
                    status: widget.status,
                  ),
              ].where((widget) => widget != null).toList(),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildAchieveVoteItemList(
      AsyncValue<List<VoteItemModel?>> asyncVoteItemList) {
    return asyncVoteItemList.when(
      data: (voteItems) => Container(
        width: ref.watch(globalMediaQueryProvider).size.width,
        height: 260,
        padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
        margin: const EdgeInsets.only(top: 24),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40).r,
          border: Border.all(
            color: AppColors.primary500,
            width: 1.5.cw,
          ),
        ),
        child: FutureBuilder(
          future: fetchVoteAchieve(ref, voteId: widget.vote.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.hasData) {
                final voteAchieves = snapshot.data as List<VoteAchieve>;
                return SlideTransition(
                  position: _offsetAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: snapshot.data!
                        .map<VoteCardColumnAchieve>((voteAchieve) {
                      return VoteCardColumnAchieve(
                          rank: voteAchieve,
                          voteItem: voteItems[0]!,
                          opacityAnimation: _opacityAnimation);
                    }).toList(),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
