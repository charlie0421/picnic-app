import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';
import 'dart:async';

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

  @override
  void dispose() {
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // 기존 타이머가 있다면 취소
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_seconds > 0) {
          setState(() {
            _seconds--;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          (_isTopBannerLoaded && _topBannerAd != null)
              ? Container(
                  alignment: Alignment.center,
                  width: _topBannerAd!.size.width.toDouble(),
                  height: _topBannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _topBannerAd!),
                )
              : SizedBox(height: AdSize.largeBanner.height.toDouble()),
          const SizedBox(height: 8),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: _seconds / _totalSeconds,
              strokeWidth: 8,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${S.of(context).compatibility_analyzing}\n($_seconds${S.of(context).seconds})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).compatibility_waiting_message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context).compatibility_warning_exit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
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
