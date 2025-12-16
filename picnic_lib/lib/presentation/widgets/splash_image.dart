import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/config_service.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:picnic_lib/core/utils/shorebird_utils.dart';

class SplashImageData {
  final String imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? deepLinkUrl;
  final String? platform;
  final Map<String, dynamic>? metadata;

  const SplashImageData({
    required this.imageUrl,
    this.startDate,
    this.endDate,
    this.deepLinkUrl,
    this.platform,
    this.metadata,
  });

  factory SplashImageData.fromJson(Map<String, dynamic> json) {
    return SplashImageData(
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '') as String,
      startDate: _parseDate(json['starts_at'] ?? json['startDate']),
      endDate: _parseDate(json['ends_at'] ?? json['endDate']),
      deepLinkUrl: json['deep_link_url'] as String?,
      platform: json['platform'] as String?,
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'image_url': imageUrl,
    'starts_at': startDate?.toIso8601String(),
    'ends_at': endDate?.toIso8601String(),
    'deep_link_url': deepLinkUrl,
    'platform': platform,
    'metadata': metadata,
  };

  bool get isValid => imageUrl.isNotEmpty;

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class SplashConfigPayload {
  final String imageUrl;
  final int version;
  final DateTime? expiresAt;
  final bool enabled;

  SplashConfigPayload({
    required this.imageUrl,
    required this.version,
    this.expiresAt,
    this.enabled = true,
  });

  bool get isValid => imageUrl.isNotEmpty;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  static SplashConfigPayload? fromRaw(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final versionValue =
          decoded['version'] ?? decoded['Version'] ?? decoded['VERSION'];
      final version = _parseVersion(versionValue) ?? 1;

      final imageUrl = _resolveImageUrl(
        decoded['cdnUrl'] ?? decoded['cdn_url'],
        decoded['cdnPath'] ?? decoded['cdn_path'],
      );
      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }

      final expiresValue = decoded['expiresAt'] ?? decoded['expires_at'];
      DateTime? expiresAt;
      if (expiresValue is String && expiresValue.isNotEmpty) {
        expiresAt = DateTime.tryParse(expiresValue);
      }

      final enabledValue = decoded['enabled'];
      final enabled = enabledValue is bool ? enabledValue : true;

      return SplashConfigPayload(
        imageUrl: imageUrl,
        version: version,
        expiresAt: expiresAt,
        enabled: enabled,
      );
    } catch (e, stack) {
      logger.w('스플래시 config 파싱 실패: $e', stackTrace: stack);
      return null;
    }
  }

  static int? _parseVersion(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }

  static String? _resolveImageUrl(dynamic cdnUrlValue, dynamic cdnPathValue) {
    final cdnUrl = cdnUrlValue is String ? cdnUrlValue.trim() : '';
    if (cdnUrl.isNotEmpty) {
      return cdnUrl;
    }

    final cdnPath = cdnPathValue is String ? cdnPathValue.trim() : '';
    if (cdnPath.isEmpty) {
      return null;
    }

    if (cdnPath.startsWith('http://') || cdnPath.startsWith('https://')) {
      return cdnPath;
    }

    final base = Environment.cdnUrl;
    final sanitizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;

    var sanitizedPath = cdnPath;
    if (sanitizedPath.startsWith(sanitizedBase)) {
      sanitizedPath = sanitizedPath.substring(sanitizedBase.length);
    }
    if (sanitizedPath.startsWith('/')) {
      sanitizedPath = sanitizedPath.substring(1);
    }

    return '$sanitizedBase/$sanitizedPath';
  }
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
  static const _splashCacheKey = 'picnic.cached.splash.asset';
  static const _splashConfigKey = 'splash_screen_asset';

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCachedSplashImage();
      await _syncSplashImageFromConfig();

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

  /// 앱 시작 시 패치 체크 및 자동 적용
  Future<void> _checkForUpdatesStable() async {
    if (UniversalPlatform.isWeb || _patchCheckCompleted) {
      logger.i(
        '패치 체크 스킵: 웹환경=${UniversalPlatform.isWeb}, 완료됨=$_patchCheckCompleted',
      );
      return;
    }

    setStateIfMounted(() {
      _isCheckingUpdate = true;
      _updateStatus = 'Checking for updates...';
    });

    try {
      logger.i('🔍 패치 상태 확인 시작');

      final updater = shorebird.ShorebirdUpdater();

      // 현재 패치 정보 확인
      final currentPatch = await updater.readCurrentPatch();
      final currentPatchNumber = currentPatch?.number;
      logger.i('📋 현재 패치 번호: ${currentPatchNumber ?? "없음"}');

      // 서버에서 업데이트 확인 (10초 타임아웃)
      final status = await updater.checkForUpdate().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.w('⏱️ 패치 확인 타임아웃');
          return shorebird.UpdateStatus.upToDate;
        },
      );

      logger.i('📊 패치 상태: $status');

      switch (status) {
        case shorebird.UpdateStatus.outdated:
          // 새 패치 다운로드 및 적용
          await _downloadAndApplyPatch(updater, currentPatchNumber);
          break;

        case shorebird.UpdateStatus.restartRequired:
          // 이미 다운로드된 패치가 있음 - 재시작 필요
          logger.i('🔄 재시작이 필요한 패치가 대기 중');
          _updatePatchInfoProvider({
            'currentPatch': currentPatchNumber,
            'updateDownloaded': true,
            'needsRestart': true,
            'hasUpdate': false,
          });
          await _scheduleAppRestart('Update ready! Restarting...');
          break;

        case shorebird.UpdateStatus.upToDate:
          await _handleUpToDate(currentPatchNumber);
          break;

        default:
          logger.i('ℹ️ 패치 상태: $status');
          await _handleUpToDate(currentPatchNumber);
          break;
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

  /// 패치 다운로드 및 적용 후 자동 재시작
  Future<void> _downloadAndApplyPatch(
    shorebird.ShorebirdUpdater updater,
    int? currentPatchNumber,
  ) async {
    setStateIfMounted(() {
      _updateStatus = 'Downloading update...';
    });

    try {
      logger.i('⬇️ 패치 다운로드 시작');

      // 패치 다운로드
      await updater.update();

      // 다운로드 후 패치 정보 확인
      final patchAfter = await updater.readCurrentPatch();
      logger.i('📋 다운로드 후 패치: ${patchAfter?.number}');

      // PatchInfoProvider 업데이트
      _updatePatchInfoProvider({
        'currentPatch': currentPatchNumber,
        'newPatch': patchAfter?.number,
        'updateDownloaded': true,
        'needsRestart': true,
        'hasUpdate': false,
      });

      logger.i('✅ 패치 다운로드 완료 - 자동 재시작 진행');
      await _scheduleAppRestart('Update complete! Restarting...');
    } catch (e) {
      logger.e('💥 패치 다운로드 실패: $e');
      // 다운로드 실패해도 앱은 계속 진행
      await _handleUpToDate(currentPatchNumber);
    }
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

  Future<void> _loadCachedSplashImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_splashCacheKey);
      if (cachedJson == null) {
        return;
      }

      final cached = jsonDecode(cachedJson) as Map<String, dynamic>;
      final assetMap = cached['asset'] as Map<String, dynamic>?;
      final cachedPlatform = cached['platform'] as String?;

      if (assetMap == null) {
        return;
      }

      final splash = SplashImageData.fromJson(assetMap);
      if (!splash.isValid) {
        return;
      }

      final currentPlatform = _resolvePlatformParam();
      final platformMatches =
          cachedPlatform == null ||
          cachedPlatform == 'all' ||
          cachedPlatform == currentPlatform;

      if (!platformMatches) {
        logger.i(
          '캐시된 스플래시 이미지 플랫폼 불일치: cached=$cachedPlatform, current=$currentPlatform',
        );
        return;
      }

      if (splash.isExpired) {
        logger.i('캐시된 스플래시 이미지가 만료되어 삭제합니다.');
        await prefs.remove(_splashCacheKey);
        return;
      }

      setStateIfMounted(() {
        scheduledSplashUrl = splash.imageUrl;
      });
    } catch (e, stack) {
      logger.w('캐시된 스플래시 이미지를 불러오지 못했습니다: $e', stackTrace: stack);
    }
  }

  Future<void> _cacheSplashAsset(
    SplashImageData splash,
    String platform, {
    int? configVersion,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _splashCacheKey,
        jsonEncode({
          'platform': platform,
          'asset': splash.toJson(),
          'cached_at': DateTime.now().toIso8601String(),
          'config_version': configVersion,
        }),
      );
    } catch (e) {
      logger.w('스플래시 이미지 캐시 저장 실패: $e');
    }
  }

  String _resolvePlatformParam() {
    if (UniversalPlatform.isIOS) {
      return 'ios';
    }
    if (UniversalPlatform.isAndroid) {
      return 'android';
    }
    if (UniversalPlatform.isMacOS) {
      return 'macos';
    }
    if (UniversalPlatform.isWindows) {
      return 'windows';
    }
    return 'all';
  }

  Future<void> _syncSplashImageFromConfig() async {
    logger.d('스플래시 config 동기화 시작');
    try {
      final configService = ref.read(configServiceProvider);
      final raw = await configService.getConfig(_splashConfigKey);
      if (raw == null || raw.isEmpty) {
        logger.i('시작화면 config 값이 없습니다. 캐시를 삭제합니다.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_splashCacheKey);
        setStateIfMounted(() {
          scheduledSplashUrl = null;
        });
        return;
      }

      final configPayload = SplashConfigPayload.fromRaw(raw);
      if (configPayload == null || !configPayload.isValid) {
        logger.w('시작화면 config 파싱 실패. 캐시를 삭제합니다.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_splashCacheKey);
        setStateIfMounted(() {
          scheduledSplashUrl = null;
        });
        return;
      }

      if (!configPayload.enabled) {
        logger.i('시작화면이 비활성화되어 있습니다.');
        // 캐시된 스플래시 이미지 제거
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_splashCacheKey);
        setStateIfMounted(() {
          scheduledSplashUrl = null;
        });
        return;
      }

      if (configPayload.isExpired) {
        logger.i('시작화면 config가 만료되었습니다. 캐시를 삭제합니다.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_splashCacheKey);
        setStateIfMounted(() {
          scheduledSplashUrl = null;
        });
        return;
      }

      final splash = SplashImageData(
        imageUrl: configPayload.imageUrl,
        startDate: null,
        endDate: configPayload.expiresAt,
        platform: 'all',
        metadata: {'source': 'config', 'version': configPayload.version},
      );

      await _cacheSplashAsset(
        splash,
        'all',
        configVersion: configPayload.version,
      );

      setStateIfMounted(() {
        scheduledSplashUrl = splash.imageUrl;
        logger.d('시작화면 이미지 url 업데이트: $scheduledSplashUrl');
      });
    } catch (e, stack) {
      logger.e('스플래시 config 동기화 실패: $e', stackTrace: stack);
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
    bool showStatus =
        (widget.enablePatchCheck &&
            (_isCheckingUpdate || _updateStatus.isNotEmpty)) ||
        (widget.statusMessage != null && widget.statusMessage!.isNotEmpty);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) 기본(로컬) 스플래시 이미지
        Image.asset('assets/splash.webp', fit: BoxFit.cover),

        // 2) 서버에서 조회된 이미지가 있으면 덮어씌우기
        if (scheduledSplashUrl != null)
          PicnicCachedNetworkImage(
            imageUrl: scheduledSplashUrl!,
            fit: BoxFit.cover, // contain에서 cover로 변경
            showLoadingOverlay: false,
            placeholder: const SizedBox.shrink(),
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
                      style: getTextStyle(
                        AppTypo.body14B,
                        AppColors.grey00,
                      ).copyWith(decoration: TextDecoration.none),
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
