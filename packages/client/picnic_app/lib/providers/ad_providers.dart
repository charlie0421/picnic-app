import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'ad_providers.freezed.dart';
part 'ad_providers.g.dart';

@freezed
class AdInfo with _$AdInfo {
  const factory AdInfo({
    RewardedAd? ad,
    @Default(false) bool isShowing,
    @Default(false) bool isLoading,
  }) = _AdInfo;
}

@freezed
class AdState with _$AdState {
  const factory AdState({
    required List<AdInfo> ads,
  }) = _AdState;

  factory AdState.initial() =>
      AdState(ads: List.generate(2, (_) => const AdInfo()));
}

@Riverpod(keepAlive: true)
class RewardedAds extends _$RewardedAds {
  final List<String> _adUnitIds = [
    Platform.isAndroid
        ? 'ca-app-pub-1539304887624918/3864525446'
        : 'ca-app-pub-1539304887624918/9821126370',
    Platform.isAndroid
        ? 'ca-app-pub-1539304887624918/7505348989'
        : 'ca-app-pub-1539304887624918/4571289807',
  ];

  @override
  AdState build() => AdState.initial();
  void _handleAdResult(AdResult result, BuildContext context) {
    switch (result) {
      case AdResult.completed:
        Future.delayed(const Duration(seconds: 2),
            () => ref.read(userInfoProvider.notifier).getUserProfiles());
        showSimpleDialog(
          context: context,
          content: S.of(context).text_dialog_star_candy_received,
          onOk: () {
            Navigator.of(context).pop();
            ref.read(userInfoProvider.notifier).getUserProfiles();
          },
        );
        break;
      case AdResult.dismissed:
        showSimpleDialog(
          context: context,
          content: S.of(context).text_dialog_ad_dismissed,
          onOk: () => Navigator.of(context).pop(),
        );
        break;
      case AdResult.error:
        showSimpleDialog(
          context: context,
          content: S.of(context).text_dialog_ad_failed_to_show,
          onOk: () => Navigator.of(context).pop(),
        );
        break;
    }
  }

  Future<AdResult?> showAdIfReady(int index, BuildContext context) async {
    if (isAdReady(index)) {
      final ad = state.ads[index].ad!;
      final result = await _showAd(ad, index);
      _handleAdResult(result, context);
      // 광고를 보여준 후 즉시 새 광고를 로드
      loadAd(index);
      return result;
    } else {
      // 광고가 준비되지 않았다면 로드를 시도
      await loadAd(index, showWhenLoaded: true, context: context);
      return null;
    }
  }

  Future<void> loadAd(int index,
      {bool showWhenLoaded = false, BuildContext? context}) async {
    if (state.ads[index].isLoading) return;

    _updateAdState(index, isLoading: true, ad: null);

    try {
      await RewardedAd.load(
        adUnitId: _adUnitIds[index],
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) async {
            _onAdLoaded(index, ad);
            if (showWhenLoaded && context != null) {
              final result = await _showAd(ad, index);
              _handleAdResult(result, context);
            }
          },
          onAdFailedToLoad: (error) => _onAdFailedToLoad(index, error),
        ),
      );
    } catch (e) {
      _onAdLoadError(index, e);
    }
  }

  Future<AdResult> _showAd(RewardedAd ad, int index) async {
    final resultCompleter = Completer<AdResult>();

    logger.i('showAd: $index, adId: ${ad.adUnitId}');

    _updateAdState(index, isShowing: true);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        _updateAdState(index, isShowing: false, ad: null);
        resultCompleter.complete(AdResult.dismissed);
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        _updateAdState(index, isShowing: false, ad: null);
        resultCompleter.complete(AdResult.error);
        logger.e('onAdFailedToShowFullScreenContent: $error');
      },
    );

    ad.setServerSideOptions(ServerSideVerificationOptions(
      userId: ref.read(userInfoProvider).value?.id.toString(),
      customData: '{"reward_type":"free_charge_station"}',
    ));

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          _updateAdState(index, isShowing: false, ad: null);
          resultCompleter.complete(AdResult.completed);
        },
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );

      _updateAdState(index, isShowing: false, ad: null);
      resultCompleter.complete(AdResult.error);
    }

    final result = await resultCompleter.future;

    // 광고 객체 폐기
    ad.dispose();

    return result;
  }

  void _onAdLoaded(int index, RewardedAd ad) {
    _updateAdState(index, ad: ad, isLoading: false);
  }

  void _onAdFailedToLoad(int index, LoadAdError error) {
    // logger.e('onAdFailedToLoad: $index, $error');
    _updateAdState(index, isLoading: false);
    _scheduleRetry(index);
  }

  void _onAdLoadError(int index, dynamic error) {
    logger.e('onAdLoadError: $index, $error');
    _updateAdState(index, isLoading: false);
    _scheduleRetry(index);
  }

  void _scheduleRetry(int index) {
    logger.i('scheduleRetry: $index');
    Future.delayed(const Duration(seconds: 5), () => loadAd(index));
  }

  void _updateAdState(int index,
      {RewardedAd? ad, bool? isShowing, bool? isLoading}) {
    state = state.copyWith(
      ads: state.ads
          .asMap()
          .map((i, adInfo) {
            if (i == index) {
              return MapEntry(
                  i,
                  adInfo.copyWith(
                    ad: ad,
                    isShowing: isShowing ?? adInfo.isShowing,
                    isLoading: isLoading ?? adInfo.isLoading,
                  ));
            }
            return MapEntry(i, adInfo);
          })
          .values
          .toList(),
    );
  }

  bool isAdReady(int index) {
    final adInfo = state.ads[index];
    return adInfo.ad != null && !adInfo.isLoading && !adInfo.isShowing;
  }
}

enum AdResult { completed, dismissed, error }
