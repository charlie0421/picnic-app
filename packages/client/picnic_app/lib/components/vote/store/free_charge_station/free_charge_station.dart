// free_charge_station.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/vote/store/common/store_point_info.dart';
import 'package:picnic_app/components/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_app/components/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/ad_info.dart';
import 'package:picnic_app/providers/ad_providers.dart';
import 'package:picnic_app/providers/config_service.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class BannerAdState {
  final bool isLoading;
  final BannerAd? bannerAd;
  final String? error;

  const BannerAdState({
    this.isLoading = true,
    this.bannerAd,
    this.error,
  });

  BannerAdState copyWith({
    bool? isLoading,
    BannerAd? bannerAd,
    String? error,
  }) {
    return BannerAdState(
      isLoading: isLoading ?? this.isLoading,
      bannerAd: bannerAd ?? this.bannerAd,
      error: error ?? this.error,
    );
  }
}

class FreeChargeStation extends ConsumerStatefulWidget {
  const FreeChargeStation({super.key});

  @override
  ConsumerState<FreeChargeStation> createState() => _FreeChargeStationState();
}

class _FreeChargeStationState extends ConsumerState<FreeChargeStation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;
  BannerAd? _bannerAd;
  BannerAdState _bannerAdState = const BannerAdState();
  bool _isPageReady = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializePage();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonScaleAnimation = Tween<double>(begin: .5, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupAd();
    _retryTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _cleanupAd() {
    try {
      _bannerAd?.dispose();
    } catch (e, s) {
      logger.e('Error disposing banner ad', error: e, stackTrace: s);
    } finally {
      _bannerAd = null;
    }
  }

  Future<void> _initializePage() async {
    if (_isDisposed) return;

    try {
      await _loadBannerAd();
      if (!_isDisposed) {
        setState(() {
          _isPageReady = true;
        });
      }
    } catch (e, s) {
      logger.e('Error initializing page', error: e, stackTrace: s);
      if (!_isDisposed) {
        setState(() {
          _isPageReady = true;
        });
      }
    }
  }

  Future<void> _loadBannerAd() async {
    if (_isDisposed || _retryCount >= maxRetries) {
      if (!_isDisposed) {
        setState(() {
          _bannerAdState = BannerAdState(
            isLoading: false,
            error: 'Maximum retry attempts reached',
          );
        });
      }
      return;
    }

    try {
      _cleanupAd();

      final configService = ref.read(configServiceProvider);
      final adUnitId = isIOS()
          ? await configService.getConfig('ADMOB_IOS_FREE_CHARGE_STATION')
          : await configService.getConfig('ADMOB_ANDROID_FREE_CHARGE_STATION');

      if (adUnitId == null) throw Exception('Ad unit ID is null');

      final completer = Completer<void>();
      BannerAd? newBannerAd;

      try {
        newBannerAd = BannerAd(
          adUnitId: adUnitId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (Ad ad) {
              if (_isDisposed) {
                ad.dispose();
                return;
              }
              if (!completer.isCompleted) {
                completer.complete();
              }
              setState(() {
                _bannerAd = ad as BannerAd;
                _bannerAdState = BannerAdState(
                  isLoading: false,
                  bannerAd: _bannerAd,
                );
                _retryCount = 0;
              });
            },
            onAdFailedToLoad: (Ad ad, LoadAdError error) {
              logger.e('Banner ad failed to load: $error');
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(); // 에러 없이 정상적으로 완료
                if (!_isDisposed) {
                  setState(() {
                    _bannerAdState = BannerAdState(
                      isLoading: false,
                      error: 'Failed to load ad',
                    );
                  });
                  _scheduleRetry();
                }
              }
              if (!_isDisposed) {
                _scheduleRetry();
              }
            },
          ),
        );

        if (!_isDisposed) {
          setState(() {
            _bannerAdState = BannerAdState(isLoading: true);
          });
        }

        await newBannerAd.load();
        await completer.future;
      } catch (e) {
        newBannerAd?.dispose();
        rethrow;
      }
    } catch (e, s) {
      logger.e('Error loading banner ad', error: e, stackTrace: s);
      if (!_isDisposed) {
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    if (!_isDisposed && _retryCount < maxRetries) {
      setState(() {
        _retryCount++;
        _bannerAdState = BannerAdState(
          isLoading: false,
          error: 'Failed to load ad. Retrying... ($_retryCount/$maxRetries)',
        );
      });

      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 5), _loadBannerAd);
    }
  }

  void _showErrorDialog(String message) {
    if (_isDisposed) return;
    showSimpleDialog(
      contentWidget: Text(
        message,
        style: getTextStyle(AppTypo.body14M, AppColors.grey900),
      ),
    );
  }

  Future<void> _showRewardedAdmob(int index) async {
    if (_isDisposed) return;

    final userState = ref.read(userInfoProvider);
    if (userState.value == null) {
      if (!_isDisposed) {
        showRequireLoginDialog();
      }
      return;
    }

    try {
      if (!_isDisposed) {
        OverlayLoadingProgress.start(context);
      }

      final response = await supabase.functions.invoke('check-ads-count');

      if (_isDisposed) return;
      OverlayLoadingProgress.stop();

      final allowed = response.data['allowed'] as bool?;
      if (allowed != true) {
        _handleExceededAdsLimit(response.data['nextAvailableTime']);
        return;
      }

      ref
          .read(rewardedAdsProvider.notifier)
          .loadAd(index, showWhenLoaded: true, context: context);
      if (!_isDisposed) {
        _animateButton();
      }
    } catch (e, s) {
      logger.e('Error in _showRewardedAdmob', error: e, stackTrace: s);
      if (!_isDisposed) {
        _showErrorDialog(Intl.message('label_loading_ads_fail'));
      }
    } finally {
      if (!_isDisposed) {
        OverlayLoadingProgress.stop(); // 에러가 발생하더라도 로딩 인디케이터를 멈춤
      }
    }
  }

  void _handleExceededAdsLimit(String? nextAvailableTimeStr) {
    if (_isDisposed || nextAvailableTimeStr == null) return;

    final nextAvailableTime = DateTime.parse(nextAvailableTimeStr).toLocal();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    showSimpleDialog(
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.of(context).label_ads_exceeded,
            style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).ads_available_time,
            style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
            textAlign: TextAlign.center,
          ),
          Text(
            formatter.format(nextAvailableTime),
            style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _animateButton() {
    if (!_isDisposed) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPageReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return FreeChargeContent(
      bannerAdState: _bannerAdState,
      buttonScaleAnimation: _buttonScaleAnimation,
      onPolicyTap: () => showUsagePolicyDialog(context, ref),
      onAdButtonPressed: _showRewardedAdmob,
      onRetryBannerAd: _retryCount < maxRetries ? _loadBannerAd : null,
    );
  }
}

class FreeChargeContent extends ConsumerWidget {
  final BannerAdState bannerAdState;
  final Animation<double> buttonScaleAnimation;
  final VoidCallback onPolicyTap;
  final Function(int) onAdButtonPressed;
  final VoidCallback? onRetryBannerAd;

  const FreeChargeContent({
    super.key,
    required this.bannerAdState,
    required this.buttonScaleAnimation,
    required this.onPolicyTap,
    required this.onAdButtonPressed,
    this.onRetryBannerAd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(rewardedAdsProvider);
    final isLogged = supabase.isLogged;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.cw),
      child: ListView(
        children: [
          if (isLogged) ...[
            const SizedBox(height: 36),
            StorePointInfo(
              title: S.of(context).label_star_candy_pouch,
              width: double.infinity,
              height: 90,
            ),
          ],
          const SizedBox(height: 18),
          _buildBannerAdSection(),
          const SizedBox(height: 18),
          _buildStoreListTileAdmob(context, 0, adState),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildStoreListTileAdmob(context, 1, adState),
          const Divider(height: 32, thickness: 1, color: AppColors.grey200),
          _buildPolicyGuide(),
        ],
      ),
    );
  }

  Widget _buildBannerAdSection() {
    return SizedBox(
      height: 50,
      child: Builder(
        builder: (context) {
          if (bannerAdState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bannerAdState.error != null && onRetryBannerAd != null) {
            return buildLoadingOverlay();
          }

          if (bannerAdState.bannerAd != null) {
            return AdWidget(ad: bannerAdState.bannerAd!);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStoreListTileAdmob(
    BuildContext context,
    int index,
    AdState adState,
  ) {
    final adInfo = adState.ads[index];
    final isLoading = adInfo.isLoading;

    return StoreListTile(
      index: index,
      icon: Image.asset(
        'assets/icons/store/star_100.png',
        width: 48.cw,
        height: 48.cw,
      ),
      title: Text(
        S.of(context).label_button_watch_and_charge,
        style: getTextStyle(AppTypo.body14B, AppColors.grey900)
            .copyWith(height: 1),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '+${S.of(context).label_bonus} 1',
              style: getTextStyle(AppTypo.caption12B, AppColors.point900),
            ),
          ],
        ),
      ),
      buttonText: isLoading
          ? S.of(context).label_loading_ads
          : S.of(context).label_watch_ads,
      buttonOnPressed: isLoading ? null : () => onAdButtonPressed(index),
      isLoading: isLoading,
      buttonScale: buttonScaleAnimation.value,
    );
  }

  Widget _buildPolicyGuide() {
    return GestureDetector(
      onTap: onPolicyTap,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: Intl.message('candy_usage_policy_guide'),
              style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: Intl.message('candy_usage_policy_guide_button'),
              style: getTextStyle(AppTypo.caption12B, AppColors.grey600)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
}
