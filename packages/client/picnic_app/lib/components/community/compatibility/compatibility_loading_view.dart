import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class CompatibilityLoadingView extends ConsumerStatefulWidget {
  const CompatibilityLoadingView({super.key});

  @override
  ConsumerState<CompatibilityLoadingView> createState() =>
      _CompatibilityLoadingViewState();
}

class _CompatibilityLoadingViewState
    extends ConsumerState<CompatibilityLoadingView> {
  int _seconds = 30;
  Timer? _timer;
  final BannerAd _bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-3940256099942544/6300978111', // 테스트 광고 ID
    size: AdSize.largeBanner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    ),
  );
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerAd.dispose();
    super.dispose();
  }

  void _loadAd() {
    _bannerAd.load().then((_) {
      setState(() {
        _isAdLoaded = true;
      });
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_seconds > 0) {
          setState(() {
            _seconds--;
          });
        } else {
          _timer?.cancel();
          // 30초 후 작업
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isAdLoaded)
            Container(
              alignment: Alignment.center,
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
          const SizedBox(height: 32),
          CircularProgressIndicator(
            value: _seconds / 30,
          ),
          const SizedBox(height: 24),
          Text(
            '궁합을 분석하고 있습니다\n($_seconds초)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '잠시만 기다려주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '화면을 나가면 분석을 다시 해야 합니다',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
