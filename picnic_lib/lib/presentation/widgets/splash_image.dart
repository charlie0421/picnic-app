import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:picnic_lib/core/utils/shorebird_utils.dart';

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
  final String? statusMessage; // 외부에서 전달받은 상태 메시지
  final bool enablePatchCheck; // 패치 체크 활성화 여부

  const SplashImage({
    super.key,
    this.statusMessage,
    this.enablePatchCheck = true,
  });

  @override
  ConsumerState<SplashImage> createState() => _OptimizedSplashImageState();
}

class _OptimizedSplashImageState extends ConsumerState<SplashImage> {
  String? scheduledSplashUrl;
  bool _disposed = false;

  // 패치 체크 관련 상태
  bool _isCheckingUpdate = false;
  String _updateStatus = '';
  bool _patchCheckCompleted = false;

  // 재시작 관련 상태
  final bool _needsRestart = false;

  @override
  void initState() {
    super.initState();

    // 웹 환경에서는 스플래시 이미지를 가져오지 않음
    if (UniversalPlatform.isWeb) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchScheduledSplashImage();

      // 패치 체크가 활성화된 경우에만 실행
      if (widget.enablePatchCheck) {
        _checkForUpdatesStable();
      }
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

  /// 간소화된 패치 체크 로직 (auto_update 사용)
  Future<void> _checkForUpdatesStable() async {
    if (UniversalPlatform.isWeb || _patchCheckCompleted) {
      logger.i(
          '패치 체크 스킵: 웹환경=${UniversalPlatform.isWeb}, 완료됨=$_patchCheckCompleted');
      return;
    }

    setStateIfMounted(() {
      _isCheckingUpdate = true;
      _updateStatus = 'Checking for updates...';
    });

    try {
      logger.i('🔍 간단한 패치 정보 확인 시작 (auto_update 활성화됨)');

      // 간단한 현재 패치 정보만 확인 (Shorebird auto_update가 패치 처리)
      try {
        final patch = await ShorebirdUtils.checkPatch();
        final currentPatchNumber = patch?.number;

        logger.i('✅ 현재 패치 번호: ${currentPatchNumber ?? "없음"}');

        // PatchInfoProvider 업데이트
        _updatePatchInfoProvider({
          'currentPatch': currentPatchNumber,
          'updateAvailable': false, // auto_update가 처리
          'needsRestart': false,
          'statusMessage': '패치 정보 확인 완료',
        });

        await _handleUpToDate(currentPatchNumber);
      } catch (e) {
        logger.w('⚠️ 패치 정보 확인 실패: $e');

        // 실패해도 정상 진행
        _updatePatchInfoProvider({
          'currentPatch': null,
          'updateAvailable': false,
          'needsRestart': false,
          'statusMessage': '패치 정보 확인 실패',
        });

        await _handleUpToDate(null);
      }
    } catch (e, stackTrace) {
      logger.e('💥 패치 체크 중 오류: $e', stackTrace: stackTrace);
      await _handlePatchError(e);
    } finally {
      setStateIfMounted(() {
        _patchCheckCompleted = true;
        _isCheckingUpdate = false;
      });

      logger.i('🏁 Splash 패치 체크 완료');
    }
  }

  /// 새로운 패치가 있는 경우 처리
  Future<void> _handleOutdatedUpdate(
      shorebird.ShorebirdUpdater updater, int? currentPatchNumber) async {
    setStateIfMounted(() {
      _updateStatus = 'Downloading update...';
    });

    try {
      logger.i('💾 패치 다운로드 및 적용 시작');

      // 업데이트 전 패치 정보
      final patchBefore = await updater.readCurrentPatch();
      logger.i('📋 업데이트 전 패치: ${patchBefore?.number}');

      // 패치 다운로드 및 적용
      logger.i('⬇️ 패치 다운로드 중...');
      await updater.update();
      logger.i('✅ 패치 다운로드 완료');

      // 업데이트 후 패치 정보
      final patchAfter = await updater.readCurrentPatch();
      logger.i('📋 업데이트 후 패치: ${patchAfter?.number}');

      if (patchBefore?.number != patchAfter?.number) {
        logger.i(
            '🎉 패치가 성공적으로 적용됨 (${patchBefore?.number} → ${patchAfter?.number})');

        // PatchInfoProvider 업데이트 - 재시작 필요 상태
        _updatePatchInfoProvider({
          'updateAvailable': false,
          'updateDownloaded': true,
          'needsRestart': true,
          'currentPatch': patchBefore?.number,
          'newPatch': patchAfter?.number,
        });

        await _scheduleAppRestart('Update complete! Restarting app...');
      } else {
        logger.w('⚠️ 패치 업데이트가 완료되었지만 패치 번호가 변경되지 않음');

        // PatchInfoProvider 업데이트 - 완료 상태
        _updatePatchInfoProvider({
          'updateAvailable': false,
          'updateDownloaded': true,
          'needsRestart': false,
          'currentPatch': currentPatchNumber,
        });

        setStateIfMounted(() {
          _updateStatus = 'Update completed';
        });
      }
    } catch (e) {
      logger.e('💥 패치 적용 중 오류: $e');
      rethrow;
    }
  }

  /// 재시작이 필요한 경우 처리
  Future<void> _handleRestartRequired(int? currentPatchNumber) async {
    logger.w('🔄 재시작이 필요한 상태 감지 - 패치 번호: $currentPatchNumber');

    // PatchInfoProvider 업데이트 - 재시작 필요 상태
    _updatePatchInfoProvider({
      'updateAvailable': false,
      'updateDownloaded': true,
      'needsRestart': true,
      'currentPatch': currentPatchNumber,
    });

    await _scheduleAppRestart('Restarting app...');
  }

  /// 최신 상태인 경우 처리
  Future<void> _handleUpToDate(int? currentPatchNumber) async {
    logger.i('✅ 패치 업데이트 불필요 (최신 상태) - 패치 번호: $currentPatchNumber');

    // PatchInfoProvider 업데이트 - 최신 상태
    _updatePatchInfoProvider({
      'updateAvailable': false,
      'updateDownloaded': false,
      'needsRestart': false,
      'currentPatch': currentPatchNumber,
    });

    setStateIfMounted(() {
      _updateStatus = 'App is up to date';
    });

    // 잠시 메시지 표시 후 숨김
    await Future.delayed(const Duration(milliseconds: 1000));
    setStateIfMounted(() {
      _updateStatus = '';
    });
  }

  /// 패치 오류 처리
  Future<void> _handlePatchError(dynamic error) async {
    logger.e('💥 패치 오류 처리: $error');

    // PatchInfoProvider 업데이트 - 오류 상태
    _updatePatchInfoProvider({
      'updateAvailable': false,
      'updateDownloaded': false,
      'needsRestart': false,
      'error': error.toString(),
    });

    setStateIfMounted(() {
      _updateStatus = 'Update check failed';
    });

    // 에러 메시지 잠시 표시 후 숨김
    await Future.delayed(const Duration(milliseconds: 2000));
    setStateIfMounted(() {
      _updateStatus = '';
    });
  }

  /// PatchInfoProvider 업데이트 헬퍼 메서드
  void _updatePatchInfoProvider(Map<String, dynamic> patchData) {
    try {
      if (context.mounted) {
        final container = ProviderScope.containerOf(context);
        container.read(patchInfoProvider.notifier).updatePatchInfo(patchData);
        logger.i('📊 PatchInfoProvider 업데이트됨: $patchData');
      } else {
        logger.w('⚠️ Context가 mounted되지 않아 PatchInfoProvider 업데이트 스킵');
      }
    } catch (e) {
      logger.e('💥 PatchInfoProvider 업데이트 실패: $e');
    }
  }

  /// 안정적인 앱 재시작 스케줄링
  Future<void> _scheduleAppRestart(String message) async {
    setStateIfMounted(() {
      _updateStatus = message;
    });

    // 메시지 표시 시간
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 카운트다운 시작
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;

      setStateIfMounted(() {
        _updateStatus = 'Restarting in ${i}s...';
      });

      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    setStateIfMounted(() {
      _updateStatus = 'Restarting now...';
    });

    // 짧은 딜레이 후 재시작
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      try {
        logger.i('Phoenix를 사용하여 앱 재시작');
        Phoenix.rebirth(context);
        logger.i('Phoenix.rebirth 성공적으로 실행됨');
      } catch (e) {
        logger.e('Phoenix 재시작 실패: $e');

        // 재시작 실패 시 사용자에게 수동 재시작 요청
        if (mounted) {
          setStateIfMounted(() {
            _patchCheckCompleted = false;
            _isCheckingUpdate = false;
            _updateStatus = 'Restart required - please restart manually';
          });

          // 5초 후 메시지 숨김
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setStateIfMounted(() {
                _updateStatus = '';
              });
            }
          });
        }
      }
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

    // 현재 표시할 상태 메시지 결정
    String? currentStatusMessage = widget.statusMessage ?? _updateStatus;
    bool showStatus = (widget.enablePatchCheck &&
            (_isCheckingUpdate || _updateStatus.isNotEmpty)) ||
        (widget.statusMessage != null && widget.statusMessage!.isNotEmpty);

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
            fit: BoxFit.cover, // contain에서 cover로 변경
          ),

        // 3) 상태 메시지 표시 (패치 체크 진행 상황 등)
        if (showStatus && currentStatusMessage.isNotEmpty)
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
                      currentStatusMessage,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey00)
                          .copyWith(decoration: TextDecoration.none),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 16),
                    if (_isCheckingUpdate || _needsRestart)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: SmallPulseLoadingIndicator(),
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
