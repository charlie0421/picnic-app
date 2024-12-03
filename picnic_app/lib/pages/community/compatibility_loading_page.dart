import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_error.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/config_service.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/vote_share_util.dart';

class CompatibilityLoadingPage extends ConsumerStatefulWidget {
  const CompatibilityLoadingPage({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  ConsumerState<CompatibilityLoadingPage> createState() =>
      _CompatibilityLoadingPageState();
}

class _CompatibilityLoadingPageState
    extends ConsumerState<CompatibilityLoadingPage> {
  // Constants
  static const int _totalSeconds = 30;

  // Keys and state variables
  final GlobalKey _printKey = GlobalKey();

  // Loading view state
  int _seconds = _totalSeconds;
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _isTopBannerLoaded = false;
  bool _isBottomBannerLoaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      await ref
          .read(compatibilityProvider.notifier)
          .setCompatibility(widget.compatibility);

      if (widget.compatibility.isPending ||
          widget.compatibility.isAds == false) {
        ref.read(compatibilityLoadingProvider.notifier).state = true;
        _loadAds();
        _startTimer();
      }
    } catch (e, stack) {
      logger.e('Error initializing data', error: e, stackTrace: stack);
    }
  }

  void _loadAds() async {
    final configService = ref.read(configServiceProvider);

    final adTopUnitId = isAndroid()
        ? await configService
            .getConfig('ADMOB_ANDROID_COMPATIBILITY_LOADING_TOP')
        : await configService.getConfig('ADMOB_IOS_COMPATIBILITY_LOADING_TOP');
    final adBottomUnitId = isAndroid()
        ? await configService
            .getConfig('ADMOB_ANDROID_COMPATIBILITY_LOADING_BOTTOM')
        : await configService
            .getConfig('ADMOB_IOS_COMPATIBILITY_LOADING_BOTTOM');

    if (adTopUnitId != null) {
      _topBannerAd = BannerAd(
        adUnitId: adTopUnitId,
        size: AdSize.largeBanner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() {
                _isTopBannerLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      )..load();
    }

    if (adBottomUnitId != null) {
      _bottomBannerAd = BannerAd(
        adUnitId: adBottomUnitId,
        size: AdSize.largeBanner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() {
                _isBottomBannerLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      )..load();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          if (_seconds > 0) {
            _seconds--;
          } else {
            timer.cancel();

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await supabase.from('compatibility_results').update({
                'id': widget.compatibility.id,
                'is_ads': true,
              }).eq('id', widget.compatibility.id);

              ref.read(navigationInfoProvider.notifier).goBack();
              ref
                  .read(navigationInfoProvider.notifier)
                  .setCurrentPage(CompatibilityResultPage(
                    compatibility: widget.compatibility,
                  ));
            });
          }
        });
      },
    );
  }

  void _updateNavigation() {
    Future(() {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.board,
            showBottomNavigation: false,
            pageTitle: Intl.message('compatibility_page_title'),
          );
    });
  }

  Future<Future<bool>> _handleSave(CompatibilityModel compatibility) async {
    return ShareUtils.captureAndSaveImage(
      _printKey,
      onStart: () {
        if (!mounted) return;
      },
      onComplete: () {
        if (!mounted) return;
      },
    );
  }

  Future<Future<bool>> _handleShare(CompatibilityModel compatibility) async {
    logger.i('Share to Twitter');
    return ShareUtils.shareToTwitter(
      _printKey,
      message: getLocaleTextFromJson(compatibility.artist.name),
      hashtag:
          '#Picnic #Vote #PicnicApp #${S.of(context).compatibility_page_title}',
      context,
      onStart: () {
        if (!mounted) return;
      },
      onComplete: () {
        if (!mounted) return;
      },
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: [
        SizedBox(height: 24),
        Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.mint500, AppColors.primary500],
            ),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Text(
            '${S.of(context).compatibility_analyzing}($_seconds${S.of(context).seconds})',
            style: getTextStyle(
              AppTypo.body14B,
              AppColors.grey00,
            ),
          ),
        ),
        SizedBox(height: 24),
        if (_isTopBannerLoaded && _topBannerAd != null)
          Container(
            alignment: Alignment.center,
            width: _topBannerAd!.size.width.toDouble(),
            height: _topBannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _topBannerAd!),
          )
        else
          SizedBox(height: AdSize.largeBanner.height.toDouble()),
        const SizedBox(height: 16),
        Text(
          S.of(context).compatibility_waiting_message,
          textAlign: TextAlign.center,
          style: getTextStyle(
            AppTypo.caption12R,
            AppColors.grey900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.of(context).compatibility_warning_exit,
          textAlign: TextAlign.center,
          style: getTextStyle(
            AppTypo.caption12R,
            AppColors.grey900,
          ),
        ),
        const SizedBox(height: 16),
        if (_isBottomBannerLoaded && _bottomBannerAd != null)
          Container(
            alignment: Alignment.center,
            width: _bottomBannerAd!.size.width.toDouble(),
            height: _bottomBannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bottomBannerAd!),
          )
        else
          SizedBox(height: AdSize.largeBanner.height.toDouble()),
        SizedBox(height: 100),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary500, AppColors.mint500],
          ),
        ),
        child: Column(
          children: [
            RepaintBoundary(
              key: _printKey,
              child: Column(
                children: [
                  CompatibilityInfo(
                    artist: widget.compatibility.artist,
                    ref: ref,
                    birthDate: widget.compatibility.birthDate,
                    birthTime: widget.compatibility.birthTime,
                    compatibility: widget.compatibility,
                  ),
                  if (widget.compatibility.isPending ||
                      widget.compatibility.isAds == false)
                    _buildLoadingView()
                  else if (widget.compatibility.hasError)
                    CompatibilityErrorView(
                      error: widget.compatibility.errorMessage ??
                          S.of(context).error_unknown,
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
