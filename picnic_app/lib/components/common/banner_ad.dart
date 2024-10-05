import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/constants.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final String adUnitId;
  final AdSize adSize;

  const BannerAdWidget({Key? key, required this.adUnitId, required this.adSize})
      : super(key: key);

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int _retryAttempt = 0;
  final int _maxRetryAttempts = 3;
  final int _retryDelay = 1000; // milliseconds

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
          logger.i('Ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          logger.i('Ad failed to load: $error');
          _retryAdLoad();
        },
      ),
    );

    _bannerAd?.load();
  }

  void _retryAdLoad() {
    if (_retryAttempt < _maxRetryAttempts) {
      _retryAttempt++;
      Future.delayed(Duration(milliseconds: _retryDelay * _retryAttempt), () {
        _loadAd();
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.adSize.height.toDouble(),
      child: _isAdLoaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : Container(),
    );
  }
}
