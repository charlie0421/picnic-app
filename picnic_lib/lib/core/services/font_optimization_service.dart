import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 폰트 가중치별 사용 빈도
enum FontUsageFrequency {
  critical, // 항상 사용 (Regular)
  high, // 자주 사용 (Medium)
  medium, // 가끔 사용 (SemiBold)
  low, // 드물게 사용 (Bold)
}

/// 폰트 메타데이터
class FontMetadata {
  final String fontFamily;
  final String assetPath;
  final FontWeight weight;
  final FontUsageFrequency frequency;
  final int estimatedSizeBytes;
  final List<String> supportedLanguages;

  const FontMetadata({
    required this.fontFamily,
    required this.assetPath,
    required this.weight,
    required this.frequency,
    required this.estimatedSizeBytes,
    this.supportedLanguages = const ['ko', 'en'],
  });
}

/// 폰트 로딩 상태
enum FontLoadingState {
  notLoaded,
  loading,
  loaded,
  failed,
}

/// 폰트 로딩 결과
class FontLoadingResult {
  final String fontFamily;
  final FontWeight weight;
  final FontLoadingState state;
  final DateTime? loadTime;
  final Duration? loadDuration;
  final int? sizeBytes;
  final String? error;

  const FontLoadingResult({
    required this.fontFamily,
    required this.weight,
    required this.state,
    this.loadTime,
    this.loadDuration,
    this.sizeBytes,
    this.error,
  });
}

/// 폰트 최적화 서비스
///
/// 폰트 로딩을 최적화하여 앱 시작 시간을 개선합니다:
/// - 중요한 폰트 가중치만 즉시 로드
/// - 나머지는 필요할 때 지연 로딩
/// - 메모리 효율적인 폰트 관리
/// - 언어별 폰트 서브셋 지원
/// - 모바일 플랫폼별 최적화
class FontOptimizationService {
  static final FontOptimizationService _instance =
      FontOptimizationService._internal();
  factory FontOptimizationService() => _instance;
  FontOptimizationService._internal();

  // 폰트 메타데이터 레지스트리
  final Map<String, FontMetadata> _fontRegistry = {};

  // 폰트 로딩 상태 추적
  final Map<String, FontLoadingResult> _loadingResults = {};
  final Map<String, Completer<void>> _loadingCompleters = {};

  // 로드된 폰트 로더들
  final Map<String, FontLoader> _fontLoaders = {};

  // 현재 언어
  String _currentLanguage = 'ko';

  // 초기화 상태
  bool _isInitialized = false;

  // 모바일 플랫폼별 설정
  bool? _isLowMemoryDevice;
  Duration? _fontLoadingDelay;
  int? _maxConcurrentFontLoads;

  /// 서비스 초기화
  Future<void> initialize({String language = 'ko'}) async {
    if (_isInitialized) return;

    try {
      logger.i('🔤 폰트 최적화 서비스 초기화 시작 (모바일 최적화)');

      _currentLanguage = language;

      // 모바일 플랫폼별 설정 초기화
      _initializeMobileSettings();

      // 폰트 메타데이터 등록
      _registerFontMetadata();

      // 중요한 폰트만 즉시 로드 (플랫폼별 최적화)
      await _loadCriticalFonts();

      // 백그라운드에서 고빈도 폰트 로드 (지연 시간 조정)
      unawaited(_loadHighFrequencyFontsDelayed());

      _isInitialized = true;
      logger.i('✅ 폰트 최적화 서비스 초기화 완료 (플랫폼: ${_getPlatformName()})');
    } catch (e, stackTrace) {
      logger.e('폰트 최적화 서비스 초기화 실패', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 모바일 플랫폼별 설정 초기화
  void _initializeMobileSettings() {
    // 저사양 기기 감지 (간소화된 방법)
    _isLowMemoryDevice = _detectLowMemoryDevice();

    // 플랫폼별 폰트 로딩 지연 시간 설정
    if (kIsWeb) {
      _fontLoadingDelay = const Duration(milliseconds: 500);
      _maxConcurrentFontLoads = 4;
    } else if (Platform.isIOS) {
      // iOS는 폰트 로딩이 상대적으로 빠름
      _fontLoadingDelay = _isLowMemoryDevice!
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 800);
      _maxConcurrentFontLoads = _isLowMemoryDevice! ? 2 : 3;
    } else if (Platform.isAndroid) {
      // Android는 더 신중한 접근 필요
      _fontLoadingDelay = _isLowMemoryDevice!
          ? const Duration(milliseconds: 1500)
          : const Duration(milliseconds: 1000);
      _maxConcurrentFontLoads = _isLowMemoryDevice! ? 1 : 2;
    } else {
      // 기타 플랫폼 (데스크톱 등)
      _fontLoadingDelay = const Duration(milliseconds: 600);
      _maxConcurrentFontLoads = 4;
    }

    logger.i(
        '📱 모바일 설정: 저사양기기=$_isLowMemoryDevice, 지연=${_fontLoadingDelay!.inMilliseconds}ms, 동시로딩=$_maxConcurrentFontLoads');
  }

  /// 저사양 기기 감지 (간소화된 방법)
  bool _detectLowMemoryDevice() {
    // 실제 구현에서는 device_info_plus 패키지 등을 사용하여
    // 더 정확한 기기 성능 정보를 가져올 수 있습니다.
    // 여기서는 간단한 휴리스틱을 사용합니다.

    if (kIsWeb) return false;

    try {
      // 플랫폼별 간단한 성능 추정
      if (Platform.isAndroid) {
        // Android는 다양한 성능의 기기가 있으므로 보수적으로 접근
        return true; // 기본적으로 저사양으로 가정하고 최적화
      } else if (Platform.isIOS) {
        // iOS는 일반적으로 성능이 균일하므로 덜 보수적
        return false;
      }
    } catch (e) {
      logger.w('기기 성능 감지 실패, 보수적으로 저사양 기기로 가정', error: e);
    }

    return true; // 안전하게 저사양 기기로 가정
  }

  /// 플랫폼 이름 반환
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isIOS) return 'iOS';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Platform 정보를 가져올 수 없는 경우
    }
    return 'Unknown';
  }

  /// 폰트 메타데이터 등록
  void _registerFontMetadata() {
    // 패키지 컨텍스트에서 실행되는지 확인하여 적절한 경로 사용
    final assetPathPrefix = _getAssetPathPrefix();

    // Pretendard Regular - 가장 중요 (즉시 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath:
          '${assetPathPrefix}assets/fonts/Pretendard/Pretendard-Regular.otf',
      weight: FontWeight.w400,
      frequency: FontUsageFrequency.critical,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));

    // Pretendard Medium - 자주 사용 (백그라운드 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath:
          '${assetPathPrefix}assets/fonts/Pretendard/Pretendard-Medium.otf',
      weight: FontWeight.w500,
      frequency: FontUsageFrequency.high,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));

    // Pretendard SemiBold - 가끔 사용 (지연 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath:
          '${assetPathPrefix}assets/fonts/Pretendard/Pretendard-SemiBold.otf',
      weight: FontWeight.w600,
      frequency: FontUsageFrequency.medium,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));

    // Pretendard Bold - 드물게 사용 (필요시 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath:
          '${assetPathPrefix}assets/fonts/Pretendard/Pretendard-Bold.otf',
      weight: FontWeight.w700,
      frequency: FontUsageFrequency.low,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));
  }

  /// Asset 경로 접두사 결정
  String _getAssetPathPrefix() {
    // 패키지에서 실행될 때 패키지 경로 사용
    return 'packages/picnic_lib/';
  }

  /// 폰트 등록
  void _registerFont(FontMetadata metadata) {
    final key = _getFontKey(metadata.fontFamily, metadata.weight);
    _fontRegistry[key] = metadata;
  }

  /// 폰트 키 생성
  String _getFontKey(String fontFamily, FontWeight weight) {
    return '${fontFamily}_${weight.value}';
  }

  /// 중요한 폰트들 즉시 로드
  Future<void> _loadCriticalFonts() async {
    final criticalFonts = _fontRegistry.values
        .where((font) => font.frequency == FontUsageFrequency.critical)
        .toList();

    logger.i('🚀 중요 폰트 로딩 시작 (${criticalFonts.length}개)');

    final futures = <Future<void>>[];
    for (final font in criticalFonts) {
      futures.add(_loadFont(font));
    }

    await Future.wait(futures);
    logger.i('✅ 중요 폰트 로딩 완료');
  }

  /// 고빈도 폰트들 지연 로드 (모바일 최적화)
  Future<void> _loadHighFrequencyFontsDelayed() async {
    // 플랫폼별 대기 시간 적용
    final delay = _fontLoadingDelay ?? const Duration(milliseconds: 1000);
    await Future.delayed(delay);

    final highFrequencyFonts = _fontRegistry.values
        .where((font) => font.frequency == FontUsageFrequency.high)
        .toList();

    logger.i(
        '⚡ 고빈도 폰트 지연 로딩 시작 (${highFrequencyFonts.length}개, ${delay.inMilliseconds}ms 지연)');

    // 동시 로딩 제한 적용
    final maxConcurrent = _maxConcurrentFontLoads ?? 2;
    for (int i = 0; i < highFrequencyFonts.length; i += maxConcurrent) {
      final batch = highFrequencyFonts.skip(i).take(maxConcurrent);
      final futures = batch.map((font) => _loadFont(font)).toList();

      await Future.wait(futures);

      // 배치 간 대기 (저사양 기기에서 부하 분산)
      final isLowMemory = _isLowMemoryDevice ?? false;
      if (isLowMemory && i + maxConcurrent < highFrequencyFonts.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  /// 개별 폰트 로드
  Future<void> _loadFont(FontMetadata metadata) async {
    final key = _getFontKey(metadata.fontFamily, metadata.weight);

    if (_loadingResults[key]?.state == FontLoadingState.loaded) {
      return; // 이미 로드됨
    }

    if (_loadingCompleters.containsKey(key)) {
      return _loadingCompleters[key]!.future; // 이미 로딩 중
    }

    final completer = Completer<void>();
    _loadingCompleters[key] = completer;

    final startTime = DateTime.now();

    try {
      _loadingResults[key] = FontLoadingResult(
        fontFamily: metadata.fontFamily,
        weight: metadata.weight,
        state: FontLoadingState.loading,
      );

      logger.d(
          '폰트 로딩 시작: ${metadata.fontFamily} ${metadata.weight.value} (${metadata.assetPath})');

      // 폰트 파일 로드 (더 상세한 에러 처리)
      ByteData? fontData;
      try {
        fontData = await rootBundle.load(metadata.assetPath);
        logger.d(
            '폰트 파일 로드 성공: ${metadata.assetPath} (${fontData.lengthInBytes} bytes)');
      } catch (e) {
        logger.e('폰트 파일 로드 실패: ${metadata.assetPath}', error: e);
        throw Exception('폰트 파일을 찾을 수 없습니다: ${metadata.assetPath} - $e');
      }

      if (fontData.lengthInBytes == 0) {
        throw Exception('폰트 파일이 비어있습니다: ${metadata.assetPath}');
      }

      // FontLoader를 사용한 폰트 등록 (더 안전한 처리)
      FontLoader? fontLoader;
      try {
        fontLoader = FontLoader(metadata.fontFamily);
        fontLoader.addFont(Future.value(fontData));

        logger.d('FontLoader 로딩 시작: ${metadata.fontFamily}');
        await fontLoader.load();
        logger.d('FontLoader 로딩 완료: ${metadata.fontFamily}');

        // 로더 저장 (나중에 정리용)
        _fontLoaders[key] = fontLoader;
      } catch (e) {
        logger.e('FontLoader 등록 실패: ${metadata.fontFamily}', error: e);
        throw Exception('폰트 등록에 실패했습니다: ${metadata.fontFamily} - $e');
      }

      // 폰트가 실제로 사용 가능한지 확인
      try {
        await _verifyFontAvailability(metadata.fontFamily);
      } catch (e) {
        logger.w('폰트 검증 실패하지만 계속 진행: ${metadata.fontFamily}', error: e);
        // 검증 실패해도 계속 진행 (일부 환경에서는 검증이 어려울 수 있음)
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _loadingResults[key] = FontLoadingResult(
        fontFamily: metadata.fontFamily,
        weight: metadata.weight,
        state: FontLoadingState.loaded,
        loadTime: endTime,
        loadDuration: duration,
        sizeBytes: fontData.lengthInBytes,
      );

      logger.i(
          '✅ 폰트 로드 완료: ${metadata.fontFamily} ${metadata.weight.value} (${duration.inMilliseconds}ms, ${fontData.lengthInBytes} bytes)');

      // 메모리 사용량 로깅 (매 폰트 로드 후)
      if (_loadingResults.length % 2 == 0) {
        _logMemoryUsage();
      }

      completer.complete();
    } catch (e, stackTrace) {
      _loadingResults[key] = FontLoadingResult(
        fontFamily: metadata.fontFamily,
        weight: metadata.weight,
        state: FontLoadingState.failed,
        error: e.toString(),
      );

      logger.e('❌ 폰트 로드 실패: ${metadata.fontFamily} ${metadata.weight.value}',
          error: e, stackTrace: stackTrace);

      // 모바일에서 폰트 로딩 실패 시 폴백 처리
      await _handleFontLoadingFailure(metadata);

      // 에러를 전파하지 않고 경고만 로그 (앱 시작 차단 방지)
      completer.complete();
    } finally {
      _loadingCompleters.remove(key);
    }
  }

  /// 폰트 사용 가능성 검증
  Future<void> _verifyFontAvailability(String fontFamily) async {
    try {
      // 간단한 텍스트 렌더링으로 폰트 사용 가능성 확인
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontFamily: fontFamily,
        fontSize: 14.0,
      ));
      paragraphBuilder.addText('Test');
      final paragraph = paragraphBuilder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 100));

      logger.d('폰트 검증 성공: $fontFamily');
    } catch (e) {
      logger.w('폰트 검증 실패: $fontFamily - $e');
      rethrow;
    }
  }

  /// 폰트 로딩 실패 처리 (모바일 최적화)
  Future<void> _handleFontLoadingFailure(FontMetadata metadata) async {
    try {
      // 시스템 기본 폰트로 폴백 등록
      final fallbackFontFamily = _getFallbackFontFamily();
      logger.i(
          '🔄 폰트 로딩 실패, 시스템 폰트로 폴백: ${metadata.fontFamily} → $fallbackFontFamily');

      // 실패한 폰트 정보를 기록하여 나중에 재시도할 수 있도록 함
      _recordFailedFont(metadata);
    } catch (e) {
      logger.w('폴백 폰트 처리 실패', error: e);
    }
  }

  /// 플랫폼별 폴백 폰트 패밀리 반환
  String _getFallbackFontFamily() {
    if (kIsWeb) return 'system-ui';

    try {
      if (Platform.isIOS) {
        return '.SF UI Text'; // iOS 시스템 폰트
      } else if (Platform.isAndroid) {
        return 'Roboto'; // Android 기본 폰트
      }
    } catch (e) {
      logger.w('플랫폼 감지 실패', error: e);
    }

    return 'sans-serif'; // 범용 폴백
  }

  /// 실패한 폰트 기록
  void _recordFailedFont(FontMetadata metadata) {
    // 추후 재시도나 분석을 위해 실패한 폰트 정보 저장
    // 실제 구현에서는 SharedPreferences나 다른 영구 저장소 사용 가능
    logger.d('실패한 폰트 기록: ${metadata.fontFamily} ${metadata.weight.value}');
  }

  /// 저사양 기기에서 폰트 로딩 재시도
  Future<void> retryFailedFonts() async {
    final isLowMemory = _isLowMemoryDevice ?? false;
    if (!isLowMemory) return;

    final failedFonts = _loadingResults.entries
        .where((entry) => entry.value.state == FontLoadingState.failed)
        .map((entry) => _fontRegistry[entry.key])
        .where((metadata) => metadata != null)
        .cast<FontMetadata>()
        .toList();

    if (failedFonts.isEmpty) return;

    logger.i('🔄 저사양 기기에서 실패한 폰트 재시도: ${failedFonts.length}개');

    for (final metadata in failedFonts) {
      // 재시도 간격을 두어 시스템 부하 최소화
      await Future.delayed(const Duration(seconds: 2));
      try {
        await _loadFont(metadata);
      } catch (e) {
        logger.w('폰트 재시도 실패: ${metadata.fontFamily}', error: e);
      }
    }
  }

  /// 특정 폰트가 로드되었는지 확인
  bool isFontLoaded(String fontFamily, FontWeight weight) {
    final key = _getFontKey(fontFamily, weight);
    return _loadingResults[key]?.state == FontLoadingState.loaded;
  }

  /// 특정 폰트 로드 대기
  Future<void> waitForFont(String fontFamily, FontWeight weight) async {
    final key = _getFontKey(fontFamily, weight);

    if (isFontLoaded(fontFamily, weight)) return;

    final metadata = _fontRegistry[key];
    if (metadata == null) {
      throw Exception('등록되지 않은 폰트: $fontFamily $weight');
    }

    if (_loadingCompleters.containsKey(key)) {
      await _loadingCompleters[key]!.future;
    } else {
      // 아직 로딩이 시작되지 않은 경우 즉시 로드
      await _loadFont(metadata);
    }
  }

  /// 빈도별 폰트 로드
  Future<void> loadFontsByFrequency(FontUsageFrequency frequency) async {
    final fonts = _fontRegistry.values
        .where((font) => font.frequency == frequency)
        .toList();

    final futures = <Future<void>>[];
    for (final font in fonts) {
      if (!isFontLoaded(font.fontFamily, font.weight)) {
        futures.add(_loadFont(font));
      }
    }

    await Future.wait(futures);
  }

  /// 언어 변경 시 폰트 재로드
  Future<void> changeLanguage(String language) async {
    if (_currentLanguage == language) return;

    logger.i('🌐 언어 변경: $_currentLanguage -> $language');
    _currentLanguage = language;

    // 현재 언어를 지원하지 않는 폰트들 확인
    final unsupportedFonts = _fontRegistry.values
        .where((font) => !font.supportedLanguages.contains(language))
        .toList();

    if (unsupportedFonts.isNotEmpty) {
      logger.w('현재 언어($language)를 지원하지 않는 폰트: ${unsupportedFonts.length}개');
    }

    // 필요시 언어별 폰트 서브셋 로드 로직 추가
  }

  /// 유휴 시간에 나머지 폰트들 프리로드 (모바일 최적화)
  void preloadRemainingFonts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 플랫폼별 지연 시간 적용
      final isLowMemory = _isLowMemoryDevice ?? false;
      final idleDelay = isLowMemory
          ? const Duration(seconds: 5) // 저사양 기기는 더 긴 지연
          : const Duration(seconds: 3);

      Timer(idleDelay, () {
        _preloadRemainingFonts();
      });
    });
  }

  /// 나머지 폰트들 프리로드 (모바일 최적화)
  Future<void> _preloadRemainingFonts() async {
    final remainingFonts = _fontRegistry.values
        .where((font) =>
            font.frequency == FontUsageFrequency.medium ||
            font.frequency == FontUsageFrequency.low)
        .where((font) => !isFontLoaded(font.fontFamily, font.weight))
        .toList();

    if (remainingFonts.isEmpty) {
      logger.i('🔄 프리로드할 폰트가 없습니다.');
      return;
    }

    logger.i(
        '🔄 나머지 폰트 프리로드 시작 (${remainingFonts.length}개, 저사양기기: $_isLowMemoryDevice)');

    // 저사양 기기에서는 한 번에 하나씩만 로딩
    final isLowMemory = _isLowMemoryDevice ?? false;
    final batchSize = isLowMemory ? 1 : 2;
    final delayBetweenBatches = isLowMemory
        ? const Duration(milliseconds: 1000)
        : const Duration(milliseconds: 500);

    for (int i = 0; i < remainingFonts.length; i += batchSize) {
      final batch = remainingFonts.skip(i).take(batchSize);
      final futures = batch.map((font) => _loadFont(font)).toList();

      try {
        await Future.wait(futures);
      } catch (e) {
        logger.w('프리로드 배치 실패', error: e);
      }

      // 배치 간 대기 (시스템 부하 최소화)
      if (i + batchSize < remainingFonts.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }

    // 최종 메모리 사용량 보고
    _logMemoryUsage();
    logger.i('✅ 모든 폰트 프리로드 완료');
  }

  /// 폰트 로딩 통계 반환
  Map<String, dynamic> getLoadingStats() {
    final stats = <FontLoadingState, int>{};
    int totalSize = 0;
    Duration totalLoadTime = Duration.zero;

    for (final result in _loadingResults.values) {
      stats[result.state] = (stats[result.state] ?? 0) + 1;

      if (result.sizeBytes != null) {
        totalSize += result.sizeBytes!;
      }

      if (result.loadDuration != null) {
        totalLoadTime += result.loadDuration!;
      }
    }

    return {
      'totalFonts': _fontRegistry.length,
      'loadedFonts': stats[FontLoadingState.loaded] ?? 0,
      'loadingFonts': stats[FontLoadingState.loading] ?? 0,
      'failedFonts': stats[FontLoadingState.failed] ?? 0,
      'totalSizeBytes': totalSize,
      'totalLoadTimeMs': totalLoadTime.inMilliseconds,
      'averageLoadTimeMs': _loadingResults.isNotEmpty
          ? totalLoadTime.inMilliseconds / _loadingResults.length
          : 0,
      'currentLanguage': _currentLanguage,
    };
  }

  /// 메모리 정리
  void dispose() {
    _loadingResults.clear();
    _loadingCompleters.clear();
    _fontLoaders.clear();
    _fontRegistry.clear();
    _isInitialized = false;

    // 모바일 설정 리셋
    _isLowMemoryDevice = null;
    _fontLoadingDelay = null;
    _maxConcurrentFontLoads = null;
  }

  /// 메모리 사용량 모니터링
  void _logMemoryUsage() {
    final totalFontSize = _loadingResults.values
        .where((result) => result.sizeBytes != null)
        .fold<int>(0, (sum, result) => sum + result.sizeBytes!);

    final loadedFonts = _loadingResults.values
        .where((result) => result.state == FontLoadingState.loaded)
        .length;

    logger.i(
        '📊 폰트 메모리 사용량: ${(totalFontSize / (1024 * 1024)).toStringAsFixed(2)}MB ($loadedFonts개 폰트)');
  }
}
