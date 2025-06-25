import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'dart:async';

class SplashImageData {
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;

  SplashImageData({
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
  });
}

class SplashImage extends ConsumerStatefulWidget {
  const SplashImage({
    super.key,
  });

  @override
  ConsumerState<SplashImage> createState() => _OptimizedSplashImageState();
}

class _OptimizedSplashImageState extends ConsumerState<SplashImage> {
  String? scheduledSplashUrl;
  bool _isCheckingUpdate = false;
  String _updateStatus = '';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    // 웹 환경에서는 스플래시 이미지를 가져오지 않음
    if (UniversalPlatform.isWeb) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchScheduledSplashImage();
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // setState 호출을 안전하게 하기 위한 헬퍼 메서드
  void setStateIfMounted(VoidCallback fn) {
    if (!mounted || _disposed) return;
    setState(fn);
  }

  Future<void> _checkForUpdates() async {
    setStateIfMounted(() {
      _isCheckingUpdate = true;
      _updateStatus = t('patch_check');
    });
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final status = await updater.checkForUpdate();
      if (status == shorebird.UpdateStatus.outdated) {
        setStateIfMounted(() {
          _updateStatus = t('patch_install');
        });
        await Future.delayed(const Duration(milliseconds: 500));

        await ShorebirdUtils.checkAndUpdate();
        setStateIfMounted(() {
          _updateStatus = t('patch_restart_app');
        });

        await Future.delayed(const Duration(milliseconds: 500));

        // Phoenix.rebirth 실행 및 실패 시 대체 로직
        await _performRestart();
      } else if (status == shorebird.UpdateStatus.restartRequired) {
        setStateIfMounted(() {
          _updateStatus = t('patch_restart_app');
        });
        await Future.delayed(const Duration(milliseconds: 500));

        // Phoenix.rebirth 실행 및 실패 시 대체 로직
        await _performRestart();
      } else {
        setStateIfMounted(() {
          _updateStatus = '';
        });
      }
    } catch (e) {
      logger.e('패치 체크 중 오류 발생: $e');
      setStateIfMounted(() {
        _updateStatus = t('patch_error');
      });
    } finally {
      setStateIfMounted(() {
        _isCheckingUpdate = false;
      });
    }
  }

  /// Phoenix.rebirth 실행 및 실패 시 대체 로직
  Future<void> _performRestart() async {
    if (!mounted) return;

    try {
      logger.i('Phoenix.rebirth를 통한 앱 재시작 시도');

      // 현재 컨텍스트 유효성 확인
      if (!context.mounted) {
        logger.e('Phoenix.rebirth 시도 시 컨텍스트가 유효하지 않음');
        await _fallbackRestart();
        return;
      }

      // 최상위 네비게이터 컨텍스트 사용
      final navigatorContext =
          Navigator.of(context, rootNavigator: true).context;

      // 현재 프레임 완료 후 재시작 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorContext.mounted && mounted) {
          try {
            Phoenix.rebirth(navigatorContext);
            logger.i('Phoenix.rebirth 성공적으로 호출됨');
          } catch (e) {
            logger.e('Phoenix.rebirth 실행 중 직접 오류: $e');
            // 비동기적으로 대체 로직 실행
            Future.microtask(() async {
              if (mounted) await _fallbackRestart();
            });
          }
        } else {
          logger.w('Phoenix.rebirth 시도 시 네비게이터 컨텍스트가 유효하지 않음');
          // 비동기적으로 대체 로직 실행
          Future.microtask(() async {
            if (mounted) await _fallbackRestart();
          });
        }
      });

      // Phoenix.rebirth 실패 감지를 위한 타이머 (좀 더 긴 시간)
      Timer(const Duration(milliseconds: 3000), () {
        if (mounted) {
          // 만약 여기까지 실행되면 Phoenix.rebirth가 제대로 작동하지 않은 것
          logger.w('Phoenix.rebirth가 예상대로 작동하지 않음 - 대체 로직 실행');
          Future.microtask(() async {
            if (mounted) await _fallbackRestart();
          });
        }
      });
    } catch (e) {
      logger.e('Phoenix.rebirth 시도 중 전체 오류: $e');
      await _fallbackRestart();
    }
  }

  /// Phoenix.rebirth 실패 시 대체 재시작 로직
  Future<void> _fallbackRestart() async {
    if (!mounted) return;

    try {
      logger.i('대체 재시작 로직 실행');

      setStateIfMounted(() {
        _updateStatus = '앱을 다시 시작해주세요';
      });

      // 사용자에게 수동 재시작 안내
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setStateIfMounted(() {
          _updateStatus = '패치가 완료되었습니다\n앱을 완전히 종료 후 다시 실행해주세요';
        });
      }
    } catch (e) {
      logger.e('대체 재시작 로직 실행 중 오류: $e');
      setStateIfMounted(() {
        _updateStatus = '패치 완료 - 앱을 재시작해주세요';
      });
    }
  }

  Future<void> _fetchScheduledSplashImage() async {
    logger.d('스플래시 이미지 fetch 시작');
    try {
      // Supabase RPC 함수 호출
      final response =
          await supabase.rpc('get_current_splash_image').maybeSingle();

      logger.d('스플래시 response: $response');

      // response.data가 null 이면, 현재 노출할 이미지가 없다는 의미
      if (response == null) {
        logger.d('스플래시 이미지 없음');
        return;
      }

      final splashData = SplashImageData(
        imageUrl: getLocaleTextFromJson(response['image']),
        startDate: DateTime.parse(response['start_at'] as String),
        endDate: DateTime.parse(response['end_at'] as String),
      );

      logger.d('스플래시 데이터: $splashData');

      setStateIfMounted(() {
        scheduledSplashUrl = splashData.imageUrl;
        logger.d('스플래시 이미지 url: $scheduledSplashUrl');
      });
    } catch (e, stack) {
      logger.e('스플래시 이미지 fetch 실패: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹 환경에서는 스플래시 이미지를 표시하지 않음
    if (UniversalPlatform.isWeb) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) 기본(로컬) 스플래시 이미지
        Image.asset(
          'assets/splash.webp',
          fit: BoxFit.cover,
        ),

        // 2) 서버에서 조회된 이미지가 있으면 덮어씌우기
        if (scheduledSplashUrl != null)
          PicnicCachedNetworkImage(
            imageUrl: scheduledSplashUrl!,
            fit: BoxFit.contain,
          ),

        // 3) 업데이트 상태 표시
        if (_isCheckingUpdate || _updateStatus.isNotEmpty)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: SizedBox(
                height: 32,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _updateStatus,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey00)
                          .copyWith(decoration: TextDecoration.none),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 16),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: SmallPulseLoadingIndicator(
                        iconColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
