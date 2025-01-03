import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/data/models/ad_info.dart';
import 'package:picnic_lib/presentation/providers/config_service.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../generated/providers/ad_providers.g.dart';

@Riverpod(keepAlive: true)
class RewardedAds extends _$RewardedAds {
  List<String> _adUnitIds = [];
  bool _isDisposed = false;

  @override
  AdState build() {
    ref.onDispose(() {
      _isDisposed = true;
      _cleanupAds();
    });
    return AdState.initial();
  }

  void _cleanupAds() {
    try {
      for (var adInfo in state.ads) {
        adInfo.ad?.dispose();
      }
    } catch (e, s) {
      logger.e('Error cleaning up ads', error: e, stackTrace: s);
    }
  }

  Future<void> _initializeAdUnitIds() async {
    if (_isDisposed) return;

    try {
      final configService = ref.read(configServiceProvider);
      _adUnitIds = isAndroid()
          ? [
              (await configService.getConfig('ADMOB_ANDROID_AD1')).toString(),
              (await configService.getConfig('ADMOB_ANDROID_AD2')).toString(),
            ]
          : [
              (await configService.getConfig('ADMOB_IOS_AD1')).toString(),
              (await configService.getConfig('ADMOB_IOS_AD2')).toString(),
            ];
    } catch (e, s) {
      logger.e('Error initializing ad unit IDs', error: e, stackTrace: s);
      // 설정 실패 시 빈 문자열로 초기화하여 길이 유지
      _adUnitIds = ['', ''];
    }
  }

  void _handleAdResult(AdResult result, BuildContext context) async {
    if (_isDisposed) return;

    try {
      await ref.read(userInfoProvider.notifier).getUserProfiles();

      if (_isDisposed || !context.mounted) return;

      switch (result) {
        case AdResult.completed:
          showSimpleDialog(
            content: Intl.message('text_dialog_star_candy_received'),
            onOk: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ref.read(userInfoProvider.notifier).getUserProfiles();
            },
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (!_isDisposed) {
              ref.read(userInfoProvider.notifier).getUserProfiles();
            }
          });
          break;

        case AdResult.dismissed:
          showSimpleDialog(
            content: Intl.message('text_dialog_ad_dismissed'),
            onOk: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          );
          break;

        case AdResult.error:
          showSimpleDialog(
            content: Intl.message('text_dialog_ad_failed_to_show'),
            onOk: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          );
          break;
      }
    } catch (e, s) {
      logger.e('Error handling ad result', error: e, stackTrace: s);
    }
  }

  Future<AdResult?> showAdIfReady(int index, BuildContext context) async {
    if (_isDisposed) return null;

    final currentContext = context; // 현재 context 저장

    if (index < 0 || index >= state.ads.length) {
      logger.e('Invalid ad index: $index');
      return AdResult.error;
    }

    try {
      if (isAdReady(index)) {
        final ad = state.ads[index].ad!;
        final result = await _showAd(ad, index);
        if (!_isDisposed && currentContext.mounted) {
          // mounted 체크 추가
          _handleAdResult(result, currentContext);
        }
        loadAd(index);
        return result;
      } else {
        if (!_isDisposed && currentContext.mounted) {
          // mounted 체크 추가
          await loadAd(index, showWhenLoaded: true, context: currentContext);
        }
        return null;
      }
    } catch (e, s) {
      logger.e('Error showing ad', error: e, stackTrace: s);
      return AdResult.error;
    }
  }

  Future<void> loadAd(int index,
      {bool showWhenLoaded = false, BuildContext? context}) async {
    if (_isDisposed ||
        index < 0 ||
        index >= state.ads.length ||
        state.ads[index].isLoading) {
      return;
    }

    final currentContext = context; // 현재 context 저장
    _updateAdState(index, isLoading: true, ad: null);

    try {
      if (_adUnitIds.isEmpty) {
        await _initializeAdUnitIds();
      }

      if (index >= _adUnitIds.length || _adUnitIds[index].isEmpty) {
        throw Exception('Invalid or uninitialized ad unit ID for index $index');
      }

      await RewardedAd.load(
        adUnitId: _adUnitIds[index],
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) async {
            if (_isDisposed) {
              ad.dispose();
              return;
            }
            _onAdLoaded(index, ad);
            if (showWhenLoaded &&
                currentContext != null &&
                currentContext.mounted) {
              final result = await _showAd(ad, index);
              if (!_isDisposed && currentContext.mounted) {
                _handleAdResult(result, currentContext);
              }
            }
          },
          onAdFailedToLoad: (error) => _onAdFailedToLoad(index, error),
        ),
      );
    } catch (e, s) {
      logger.e('Error loading ad', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      _onAdLoadError(index, e);
    }
  }

  Future<AdResult> _showAd(RewardedAd ad, int index) async {
    if (_isDisposed) return AdResult.error;

    final resultCompleter = Completer<AdResult>();

    try {
      _updateAdState(index, isShowing: true);

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          if (!_isDisposed) {
            _updateAdState(index, isShowing: false, ad: null);
          }
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(AdResult.dismissed);
          }
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          logger.e('onAdFailedToShowFullScreenContent: $error');
          if (!_isDisposed) {
            _updateAdState(index, isShowing: false, ad: null);
          }
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(AdResult.error);
          }
        },
      );

      ad.setServerSideOptions(ServerSideVerificationOptions(
        userId: ref.read(userInfoProvider).value?.id.toString(),
        customData: '{"reward_type":"free_charge_station"}',
      ));

      await ad.show(
        onUserEarnedReward: (_, reward) {
          if (!_isDisposed) {
            _updateAdState(index, isShowing: false, ad: null);
          }
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(AdResult.completed);
          }
        },
      );

      final result = await resultCompleter.future;
      ad.dispose();
      return result;
    } catch (e, s) {
      logger.e('Error showing ad', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);

      if (!_isDisposed) {
        _updateAdState(index, isShowing: false, ad: null);
      }
      if (!resultCompleter.isCompleted) {
        resultCompleter.complete(AdResult.error);
      }

      ad.dispose();
      return AdResult.error;
    }
  }

  void _onAdLoaded(int index, RewardedAd ad) {
    if (!_isDisposed) {
      _updateAdState(index, ad: ad, isLoading: false);
    }
  }

  void _onAdFailedToLoad(int index, LoadAdError error) {
    logger.e('Ad failed to load: $error');
    if (!_isDisposed) {
      _updateAdState(index, isLoading: false);
    }
  }

  void _onAdLoadError(int index, dynamic error) {
    logger.e('Ad load error: $error');
    if (!_isDisposed) {
      _updateAdState(index, isLoading: false);
    }
  }

  void _updateAdState(int index,
      {RewardedAd? ad, bool? isShowing, bool? isLoading}) {
    if (_isDisposed) return;

    final updatedAds = [...state.ads];
    updatedAds[index] = AdInfo(
      ad: ad ?? state.ads[index].ad,
      isShowing: isShowing ?? state.ads[index].isShowing,
      isLoading: isLoading ?? state.ads[index].isLoading,
    );

    state = AdState(ads: updatedAds);
  }

  bool isAdReady(int index) {
    if (index < 0 || index >= state.ads.length) return false;
    final adInfo = state.ads[index];
    return adInfo.ad != null && !adInfo.isLoading && !adInfo.isShowing;
  }
}

enum AdResult { completed, dismissed, error }
