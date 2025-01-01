import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/presentation/providers/config_service.dart';
import 'package:picnic_app/core/utils/logger.dart';
import 'package:picnic_app/core/utils/ui.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final String configKey;
  final AdSize adSize;
  final Duration retryDelay;
  final int maxRetries;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Duration loadingUIDelay; // 로딩 UI 지연 시간

  const BannerAdWidget({
    super.key,
    required this.configKey,
    this.adSize = AdSize.banner,
    this.retryDelay = const Duration(seconds: 5),
    this.maxRetries = 5,
    this.loadingWidget,
    this.errorWidget,
    this.loadingUIDelay = const Duration(milliseconds: 1000),
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoading = true;
  bool _showLoadingUI = false; // 로딩 UI 표시 여부를 제어하는 새로운 상태
  bool _hasError = false;
  int _retryCount = 0;
  bool _isDisposed = false;
  Timer? _loadingUITimer;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _scheduleLoadingUI();
  }

  void _scheduleLoadingUI() {
    _loadingUITimer = Timer(widget.loadingUIDelay, () {
      if (!_isDisposed && _isLoading) {
        setState(() {
          _showLoadingUI = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    _loadingUITimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    if (_isDisposed || _retryCount >= widget.maxRetries) return;

    try {
      await _bannerAd?.dispose();
      _bannerAd = null;

      final configService = ref.read(configServiceProvider);
      final adUnitId = isIOS()
          ? await configService.getConfig('ADMOB_IOS_${widget.configKey}')
          : await configService.getConfig('ADMOB_ANDROID_${widget.configKey}');

      if (adUnitId == null) throw Exception('Ad unit ID is null');
      if (_isDisposed) return;

      final completer = Completer<void>();

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: widget.adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (!_isDisposed) {
              setState(() {
                _isLoading = false;
                _showLoadingUI = false;
                _hasError = false;
                _retryCount = 0;
              });
              completer.complete();
            }
          },
          onAdFailedToLoad: (ad, error) {
            logger.e('Banner ad failed to load: $error');
            ad.dispose();
            if (!_isDisposed) {
              setState(() {
                _hasError = true;
                _isLoading = false;
                _showLoadingUI = false;
              });
              _scheduleRetry();
            }
            completer.complete();
          },
        ),
      );

      await _bannerAd!.load();
      await completer.future;
    } catch (e, s) {
      logger.e('Error loading banner ad', error: e, stackTrace: s);
      if (!_isDisposed) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _showLoadingUI = false;
        });
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    if (_isDisposed || _retryCount >= widget.maxRetries) return;

    _retryCount++;
    Future.delayed(
      Duration(seconds: widget.retryDelay.inSeconds * _retryCount),
      () {
        if (!_isDisposed) {
          setState(() {
            _isLoading = true;
          });
          _loadBannerAd();
          _scheduleLoadingUI();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _showLoadingUI) {
      return Center(
        child: SizedBox(
          width: widget.adSize.width.toDouble(),
          height: widget.adSize.height.toDouble(),
          child: widget.loadingWidget ?? buildLoadingOverlay(),
        ),
      );
    }

    if (_hasError) {
      return Column(
        children: [
          SizedBox(
            width: widget.adSize.width.toDouble(),
            height: widget.adSize.height.toDouble(),
            child: widget.errorWidget ?? const SizedBox.shrink(),
          ),
        ],
      );
    }

    if (_bannerAd == null || (_isLoading && !_showLoadingUI)) {
      return Center(
        child: SizedBox(
          width: widget.adSize.width.toDouble(),
          height: widget.adSize.height.toDouble(),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
