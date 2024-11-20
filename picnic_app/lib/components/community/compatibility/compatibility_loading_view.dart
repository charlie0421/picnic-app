import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class CompatibilityLoadingView extends ConsumerStatefulWidget {
  const CompatibilityLoadingView({super.key});

  @override
  ConsumerState<CompatibilityLoadingView> createState() =>
      CompatibilityLoadingViewState();
}

class CompatibilityLoadingViewState
    extends ConsumerState<CompatibilityLoadingView> {
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _isTopBannerLoaded = false;
  bool _isBottomBannerLoaded = false;
  int _remainingSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAds();
    _startTimer();
  }

  @override
  void dispose() {
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _loadAds() {
    _topBannerAd = BannerAd(
      adUnitId: isAndroid()
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isTopBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();

    _bottomBannerAd = BannerAd(
      adUnitId: isAndroid()
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBottomBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        ref.refresh(compatibilityProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          (_isTopBannerLoaded && _topBannerAd != null)
              ? Container(
                  alignment: Alignment.center,
                  width: _topBannerAd!.size.width.toDouble(),
                  height: _topBannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _topBannerAd!),
                )
              : SizedBox(height: AdSize.largeBanner.height.toDouble()),
          const SizedBox(height: 6),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            value: _remainingSeconds / 30,
          ),
          const SizedBox(height: 12),
          Text(
            '궁합을 분석하고 있습니다...\n($_remainingSeconds초)',
            style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요',
            style: getTextStyle(AppTypo.body14M, AppColors.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          (_isBottomBannerLoaded && _bottomBannerAd != null)
              ? Container(
                  alignment: Alignment.center,
                  width: _bottomBannerAd!.size.width.toDouble(),
                  height: _bottomBannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bottomBannerAd!),
                )
              : SizedBox(height: AdSize.largeBanner.height.toDouble()),
        ],
      ),
    );
  }
}
