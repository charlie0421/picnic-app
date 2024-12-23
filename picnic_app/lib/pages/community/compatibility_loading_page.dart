import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/ads/banner_ad_widget.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_error.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';

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
  bool _isLoadingStarted = false;
  Timer? _timer;

  String loadingMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isLoadingStarted = true;
          });
          _startTimer();
        }
      });
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
      }
    } catch (e, stack) {
      logger.e('Error initializing data', error: e, stackTrace: stack);
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

  Widget _buildLoadingView() {
    final progress = _isLoadingStarted ? _seconds / _totalSeconds : 1.0;

    return Column(
      children: [
        SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(32),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.linear,
                        transform: Matrix4.translationValues(
                            -constraints.maxWidth * (1 - progress),
                            // MediaQuery 대신 실제 Container 너비 사용
                            0,
                            0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [AppColors.mint500, AppColors.primary500],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${_isLoadingStarted ? S.of(context).compatibility_analyzing : S.of(context).compatibility_analyzing_prepare} ${_isLoadingStarted ? '($_seconds${S.of(context).seconds})' : ''}',
                        style: getTextStyle(
                          AppTypo.body14B,
                          AppColors.grey00,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 24),
        BannerAdWidget(
          configKey: 'COMPATIBILITY_LOADING_TOP',
          adSize: AdSize.largeBanner,
        ),
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
        BannerAdWidget(
          configKey: 'COMPATIBILITY_LOADING_BOTTOM',
          adSize: AdSize.largeBanner,
        ),
        SizedBox(height: 200),
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
                    gender: widget.compatibility.gender,
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
