import 'dart:async';

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

  /// 서비스 초기화
  Future<void> initialize({String language = 'ko'}) async {
    if (_isInitialized) return;

    try {
      logger.i('🔤 폰트 최적화 서비스 초기화 시작');

      _currentLanguage = language;

      // 폰트 메타데이터 등록
      _registerFontMetadata();

      // 중요한 폰트만 즉시 로드
      await _loadCriticalFonts();

      // 백그라운드에서 고빈도 폰트 로드
      unawaited(_loadHighFrequencyFonts());

      _isInitialized = true;
      logger.i('✅ 폰트 최적화 서비스 초기화 완료');
    } catch (e, stackTrace) {
      logger.e('폰트 최적화 서비스 초기화 실패', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 폰트 메타데이터 등록
  void _registerFontMetadata() {
    // Pretendard Regular - 가장 중요 (즉시 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath: 'assets/fonts/Pretendard/Pretendard-Regular.otf',
      weight: FontWeight.w400,
      frequency: FontUsageFrequency.critical,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));

    // Pretendard Medium - 자주 사용 (백그라운드 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath: 'assets/fonts/Pretendard/Pretendard-Medium.otf',
      weight: FontWeight.w500,
      frequency: FontUsageFrequency.high,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));

    // Pretendard SemiBold - 가끔 사용 (지연 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath: 'assets/fonts/Pretendard/Pretendard-SemiBold.otf',
      weight: FontWeight.w600,
      frequency: FontUsageFrequency.medium,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));

    // Pretendard Bold - 드물게 사용 (필요시 로드)
    _registerFont(FontMetadata(
      fontFamily: 'Pretendard',
      assetPath: 'assets/fonts/Pretendard/Pretendard-Bold.otf',
      weight: FontWeight.w700,
      frequency: FontUsageFrequency.low,
      estimatedSizeBytes: 1600000,
      supportedLanguages: ['ko', 'en', 'ja'],
    ));
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

  /// 고빈도 폰트들 백그라운드 로드
  Future<void> _loadHighFrequencyFonts() async {
    // 잠시 대기 (앱 시작 완료 후)
    await Future.delayed(const Duration(milliseconds: 800));

    final highFrequencyFonts = _fontRegistry.values
        .where((font) => font.frequency == FontUsageFrequency.high)
        .toList();

    logger.i('⚡ 고빈도 폰트 백그라운드 로딩 시작 (${highFrequencyFonts.length}개)');

    for (final font in highFrequencyFonts) {
      await _loadFont(font);
      // 부하 분산을 위해 잠시 대기
      await Future.delayed(const Duration(milliseconds: 300));
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

      // 폰트 파일 로드
      final fontData = await rootBundle.load(metadata.assetPath);

      // 폰트 로더 생성 및 등록
      final fontLoader = FontLoader(metadata.fontFamily);
      fontLoader.addFont(Future.value(fontData));
      await fontLoader.load();

      // 로더 저장 (나중에 정리용)
      _fontLoaders[key] = fontLoader;

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

      logger.d(
          '폰트 로드 완료: ${metadata.fontFamily} ${metadata.weight.value} (${duration.inMilliseconds}ms, ${fontData.lengthInBytes} bytes)');
      completer.complete();
    } catch (e) {
      _loadingResults[key] = FontLoadingResult(
        fontFamily: metadata.fontFamily,
        weight: metadata.weight,
        state: FontLoadingState.failed,
        error: e.toString(),
      );

      logger.e('폰트 로드 실패: ${metadata.fontFamily} ${metadata.weight.value}',
          error: e);
      completer.completeError(e);
    } finally {
      _loadingCompleters.remove(key);
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

  /// 유휴 시간에 나머지 폰트들 프리로드
  void preloadRemainingFonts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        _preloadRemainingFonts();
      });
    });
  }

  /// 나머지 폰트들 프리로드
  Future<void> _preloadRemainingFonts() async {
    final remainingFonts = _fontRegistry.values
        .where((font) =>
            font.frequency == FontUsageFrequency.medium ||
            font.frequency == FontUsageFrequency.low)
        .where((font) => !isFontLoaded(font.fontFamily, font.weight))
        .toList();

    logger.i('🔄 나머지 폰트 프리로드 시작 (${remainingFonts.length}개)');

    for (final font in remainingFonts) {
      await _loadFont(font);
      // 부하 분산을 위해 잠시 대기
      await Future.delayed(const Duration(milliseconds: 500));
    }
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
  }
}
