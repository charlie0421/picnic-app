import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/config_service.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class CompatibilityLoadingView extends ConsumerStatefulWidget {
  const CompatibilityLoadingView({super.key});

  @override
  ConsumerState<CompatibilityLoadingView> createState() =>
      _CompatibilityLoadingViewState();
}

class _CompatibilityLoadingViewState
    extends ConsumerState<CompatibilityLoadingView> {
  static const int _totalSeconds = 30;
  int _seconds = _totalSeconds;
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _isTopBannerLoaded = false;
  bool _isBottomBannerLoaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAds();
    _startTimer();
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

    _topBannerAd = BannerAd(
      adUnitId: adTopUnitId!,
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

    _bottomBannerAd = BannerAd(
      adUnitId: adBottomUnitId!,
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

  @override
  void dispose() {
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _timer?.cancel();
    super.dispose();
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
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i('CompatibilityLoadingView build');

    final isLoading = ref.watch(compatibilityLoadingProvider);

    // 로딩이 끝났으면 빈 위젯 반환
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isTopBannerLoaded && _topBannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _topBannerAd!.size.width.toDouble(),
              height: _topBannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _topBannerAd!),
            )
          else
            SizedBox(height: AdSize.largeBanner.height.toDouble()),
          const SizedBox(height: 24),
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: _seconds / _totalSeconds,
              strokeWidth: 4,
              backgroundColor: AppColors.grey200,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${S.of(context).compatibility_analyzing}\n($_seconds${S.of(context).seconds})',
            textAlign: TextAlign.center,
            style: getTextStyle(
              AppTypo.title18B,
              AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            S.of(context).compatibility_waiting_message,
            textAlign: TextAlign.center,
            style: getTextStyle(
              AppTypo.body14R,
              AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).compatibility_warning_exit,
            textAlign: TextAlign.center,
            style: getTextStyle(
              AppTypo.body14M,
              AppColors.point900,
            ),
          ),
          const SizedBox(height: 24),
          if (_isBottomBannerLoaded && _bottomBannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bottomBannerAd!.size.width.toDouble(),
              height: _bottomBannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bottomBannerAd!),
            )
          else
            SizedBox(height: AdSize.largeBanner.height.toDouble()),
        ],
      ),
    );
  }
}
