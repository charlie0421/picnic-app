import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/presentation/common/ads/banner_ad_widget.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_error.dart';
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_card.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_result_page.dart';
import 'package:picnic_lib/presentation/providers/community/compatibility_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/logger.dart';

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

  // 성능 최적화를 위한 const 상수 활용
  static const _progressBarHeight = 48.0;
  static const _progressBarRadius = 32.0;
  static const _animationDuration = Duration(milliseconds: 1000);

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

  // 성능 최적화를 위한 계산 캐싱
  double get _progress => _isLoadingStarted ? _seconds / _totalSeconds : 1.0;

  // 불필요한 리빌드 방지를 위한 메서드 분리
  Widget _buildProgressBar(BoxConstraints constraints) {
    return Container(
      height: _progressBarHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(_progressBarRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_progressBarRadius),
        child: Stack(
          children: [
            _buildProgressIndicator(constraints),
            _buildProgressText(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BoxConstraints constraints) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.linear,
        transform: Matrix4.translationValues(
            -constraints.maxWidth * (1 - _progress),
            // MediaQuery 대신 실제 Container 너비 사용
            0,
            0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.secondary500, AppColors.primary500],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressText() {
    return Center(
      child: Text(
        '${_isLoadingStarted ? S.of(context).compatibility_analyzing : S.of(context).compatibility_analyzing_prepare} ${_isLoadingStarted ? '($_seconds${S.of(context).seconds})' : ''}',
        style: getTextStyle(
          AppTypo.body14B,
          AppColors.grey00,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: [
        SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            return _buildProgressBar(constraints);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary500, AppColors.secondary500],
          ),
        ),
        child: Column(
          children: [
            RepaintBoundary(
              key: _printKey,
              child: Column(
                children: [
                  CompatibilityCard(
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
