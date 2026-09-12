import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/image_shimmer_loading.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

export 'package:picnic_lib/presentation/common/image_shimmer_loading.dart'
    show buildImageLoadingOverlay;

/// 이미지 복잡도 레벨
enum ImageComplexity {
  low, // 작은 크기, 단순한 이미지
  medium, // 중간 크기 이미지
  high, // 큰 크기, 복잡한 이미지
}

/// Lazy Loading 전략
enum LazyLoadingStrategy {
  none, // Lazy Loading 비활성화
  viewport, // 뷰포트에 들어올 때 로드
  preload, // 뷰포트 근처에서 미리 로드
  progressive, // 점진적 로딩 (저품질 → 고품질)
}

/// 이미지 로딩 우선순위
enum ImagePriority { low, normal, high }

/// 성공적으로 로딩된 이미지 URL을 추적하는 글로벌 Set
/// 위젯이 재생성되더라도 이미 성공한 source는 lazy gate를 즉시 통과한다.
///
/// Flutter의 PaintingBinding.imageCache 로 대체할 수 없다 — 그 캐시는
/// ImageProvider(오브젝트) 를 키로 쓰는 반면 이 Set은 원본 imageUrl만으로
/// "이 세션에서 한 번은 성공했다"를 묻는 lazy 진입 힌트다. 실제 준비 완료와
/// overlay 제거는 항상 현재 provider의 첫 decoded frame으로 결정한다.
///
/// **LRU, FIFO 아님.** 삽입 순서상 가장 오래 재사용되지 않은(least-recently-
/// used) 항목을 버린다 — [_rememberSuccessfullyLoadedImageUrl] 이 재사용 시
/// 기존 엔트리를 지웠다 다시 넣어 "가장 최근" 위치(LinkedHashSet 삽입 순서상
/// 맨 뒤)로 옮긴다. 단순 FIFO(재사용해도 위치 갱신 없음)였다면, 인기 아티스트
/// 이미지처럼 반복 재사용되는(hot) URL 도 최초 삽입 시점 기준으로만 밀려나
/// 상한을 넘기는 즉시 스킵 대상에서 빠지고 shimmer/loading-overlay 경로를 다시
/// 탄다 — 자주 쓰는 이미지일수록 먼저 밀려나는 역설이 생긴다.
///
/// **상한 500 의 근거**: CDN 이미지 URL 은 보통
/// `https://cdn.picnic.fan/.../<uuid>.jpg?w=400&h=400&q=85` 형태로 평균
/// 100~160자(여유 있게 150자로 계산). Dart String 은 UTF-16 저장이라 문자당
/// 2바이트, 문자열 인스턴스/LinkedHashSet 노드 오버헤드를 넉넉히 문자당 1바이트
/// 추가로 잡아도 항목당 대략 450바이트, 500개 전체로 ~220KB — 이 위젯이 이미
/// 유지하는 200MB 이미지 캐시에 비해 무시할 수 있는 크기다. 반면 한 화면(리스트/
/// 그리드/캐러셀)에 동시에 걸리는 distinct 이미지 수는 보통 수십~한두 백 개
/// 수준이라, LRU 갱신과 맞물리면 실사용 중 hot URL 이 이 상한 안에서 밀려날
/// 일은 사실상 없다.
const int _maxSuccessfullyLoadedImageUrls = 500;
final Set<String> _successfullyLoadedImageUrls = {};

void _rememberSuccessfullyLoadedImageUrl(String url) {
  // 이미 있으면 지웠다 다시 넣어 "가장 최근 사용" 위치로 갱신한다(LRU).
  _successfullyLoadedImageUrls.remove(url);
  if (_successfullyLoadedImageUrls.length >= _maxSuccessfullyLoadedImageUrls) {
    _successfullyLoadedImageUrls.remove(_successfullyLoadedImageUrls.first);
  }
  _successfullyLoadedImageUrls.add(url);
}

/// 테스트 전용: 세션 전역 상태인 [_successfullyLoadedImageUrls] 를 초기화한다.
/// (top-level 전역이라 테스트 간 격리를 위해 필요.)
@visibleForTesting
void resetSuccessfullyLoadedImageUrlsForTest() {
  _successfullyLoadedImageUrls.clear();
}

/// 테스트 전용: 상한 검증을 위해 현재 크기를 읽는다.
@visibleForTesting
int get successfullyLoadedImageUrlsCountForTest =>
    _successfullyLoadedImageUrls.length;

/// 테스트 전용: [_maxSuccessfullyLoadedImageUrls] 를 그대로 노출한다 — 테스트가
/// 상한 숫자를 별도로 하드코딩해 두 값이 어긋나는 것을 막는다.
@visibleForTesting
int get successfullyLoadedImageUrlsCapacityForTest =>
    _maxSuccessfullyLoadedImageUrls;

/// 테스트 전용: 특정 URL 이 세션 성공 Set 에 남아있는지 확인한다.
@visibleForTesting
bool successfullyLoadedImageUrlsContainsForTest(String url) =>
    _successfullyLoadedImageUrls.contains(url);

/// 테스트 전용: 실제 이미지 디코드 성공 콜백 없이 LRU 상한/갱신 로직만
/// 단위 테스트하기 위한 진입점. 헤드리스 테스트 환경에서는 네트워크 이미지
/// 디코드가 항상 실패하므로, 위젯을 통한 진짜 성공 경로로는 이 Set 의
/// 상한 동작을 검증할 수 없다.
@visibleForTesting
void rememberSuccessfullyLoadedImageUrlForTest(String url) {
  _rememberSuccessfullyLoadedImageUrl(url);
}

class PicnicCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Duration? timeout;
  final int? maxRetries;

  // Lazy Loading 관련 매개변수
  final LazyLoadingStrategy lazyLoadingStrategy;
  final double visibilityThreshold; // 가시성 임계값 (0.0 ~ 1.0)
  // 소스 호환성을 위해 유지한다. 최초 표시를 시간으로 지연하지 않는다.
  final Duration? lazyLoadDelay;
  final Widget? placeholder; // 커스텀 플레이스홀더

  // 성능 최적화 관련 매개변수
  // 소스 호환성과 호출부 의미 표기를 위해 유지하며 로드 시각은 바꾸지 않는다.
  final ImagePriority priority;
  final bool enableMemoryOptimization; // 메모리 최적화 활성화
  final bool enableProgressiveLoading; // 점진적 로딩 활성화

  final Widget? errorWidget; // 커스텀 에러 위젯
  final bool showLoadingOverlay;

  // C3: 리스트 전용 요청 가중치 축소(다른 화면 영향 없음 — 기본값 null = 현재 동작 유지).
  // maxQualityOverride: 단일(저복잡도) URL 의 q 값을 이 값으로 제한.
  // maxResolutionMultiplierCap: _getResolutionMultiplier 결과를 이 값으로 clamp.
  final int? maxQualityOverride;
  final double? maxResolutionMultiplierCap;

  /// Prefetch와 display가 정확히 같은 provider/key를 공유해야 할 때 전달한다.
  /// null이면 현재 layout과 DPR로 request를 매 build마다 다시 계산한다.
  final PicnicImageRequest? imageRequest;

  // 기존 public API를 유지한다. 실제 scroll deferral은 Flutter Image가 내부의
  // ScrollAwareImageProvider로 처리해 warm/pending Image subtree를 보존한다.
  final bool deferDuringFastScroll;

  const PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.timeout,
    this.maxRetries,
    this.lazyLoadingStrategy = LazyLoadingStrategy.viewport,
    this.visibilityThreshold = 0.1,
    this.lazyLoadDelay,
    this.placeholder,
    this.errorWidget,
    this.showLoadingOverlay = true,
    this.priority = ImagePriority.normal,
    this.enableMemoryOptimization = true,
    this.enableProgressiveLoading = true,
    this.maxQualityOverride,
    this.maxResolutionMultiplierCap,
    this.imageRequest,
    this.deferDuringFastScroll = false,
  });

  /// 테스트 환경에서 이미지 로딩 타이머 비활성화 (pending timer assertion 방지)
  @visibleForTesting
  static bool disableTimeoutForTest = false;

  @override
  State<PicnicCachedNetworkImage> createState() =>
      _PicnicCachedNetworkImageState();
}

typedef _ImageAttempt = ({int generation, int reloadToken});
typedef _ImageRequestIdentity = ({
  String url,
  int decodeWidth,
  int decodeHeight,
  ImageProvider<Object> provider,
});

class _PicnicCachedNetworkImageState extends State<PicnicCachedNetworkImage> {
  bool _loading = false;
  bool _hasError = false;
  bool _shouldLoadImage = false; // Lazy Loading 제어
  bool _isVisible = false; // 가시성 상태
  bool _isImageLoaded = false;
  DateTime? _loadStartTime;
  int _retryCount = 0;
  Timer? _retryTimer; // 재시도 백오프 (취소 가능)
  Timer? _imageTimeoutTimer; // 단일 이미지 로딩 타임아웃 — dispose/URL 변경 시 반드시 취소
  int _imageRequestGeneration = 0;
  _ImageRequestIdentity? _activeRequestIdentity;
  ImageConfiguration? _activeImageConfiguration;
  _ImageAttempt? _requestKeyResolutionScheduledFor;
  _ImageAttempt? _loadAllowanceCheckScheduledFor;
  _ImageAttempt? _attemptStartedFor;
  _ImageAttempt? _successTransitionScheduledFor;
  _ImageAttempt? _successfulAttempt;
  _ImageAttempt? _handledErrorAttempt;
  _ImageRequestIdentity? _cacheProbeIdentity;
  _ImageRequestIdentity? _cachePromotionScheduledFor;

  /// VisibilityDetector 의 Key 는 위젯 식별자일 뿐 아니라 visibility_detector
  /// 패키지의 **전역 static map**(`_updates`, `_lastVisibility`) 의 키로도 쓰인다.
  ///
  /// 예전에는 이 Key 를 `Key('lazy_image_$imageUrl')` — 즉 이미지 URL 로 만들었다.
  /// 그래서 같은 이미지가 화면에 두 번 이상 나오면(인기 아티스트가 여러 투표 카드의
  /// top3 에 걸리거나, 예정 투표 썸네일 그리드에 동시 노출) 키가 충돌해
  /// `_updates[key] = callback` 이 서로를 덮어썼고, 한쪽 인스턴스는 가시성 콜백을
  /// 영영 받지 못해 `_shouldLoadImage` 가 false 인 채로 남았다 — 로딩을 시작조차
  /// 못 하고 shimmer 만 보였다. 형제 위젯이 아니면 Flutter 가 중복 Key 에러도 내지
  /// 않아 조용히 오동작한다.
  ///
  /// 따라서 인스턴스마다 고유한 키를 쓴다.
  final Key _visibilityKey = UniqueKey();

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _defaultMaxRetries = 2;
  static const Duration _maxBackoffDelay = Duration(seconds: 30);

  // 성능 모니터링용 (CachedNetworkImage 캐시와는 별개)
  static final Map<String, DateTime> _lastSnapshotTimes = {};
  static final Map<String, List<DateTime>> _failureHistory = {};
  // _failureHistory 정리(removeWhere)는 맵 전체를 순회한다 — 실패 1건마다
  // 매번 돌리면, CDN 장애 등으로 1시간 내 distinct URL 수천 개가 실패할 때
  // 실패 처리 경로 전체가 O(실패 횟수 × distinct URL 수)가 된다. 정리 자체를
  // 벽시계 기준으로 최소 이 간격만큼만 실행해, 실패가 몰릴 때도 정리 비용이
  // 실패 1건당이 아니라 시간당으로 상한이 걸리게 한다. (정리를 건너뛴 사이에도
  // 엔트리는 계속 추가되지만, 다음 정리 때 한 번에 걸러지므로 카디널리티
  // 상한 자체는 그대로 유지된다 — 다만 걸러지는 시점이 최대 이 간격만큼
  // 늦어질 수 있다.)
  static DateTime? _lastFailureHistorySweep;
  static const Duration _failureHistorySweepInterval = Duration(seconds: 30);
  static DateTime? _lastGlobalSnapshot;
  static int _snapshotCount = 0;
  static DateTime? _lastMemoryPressureLog;
  static const Duration _memoryPressureLogInterval = Duration(minutes: 1);
  static final Map<String, DateTime> _lastTimeoutLogTimes = {};
  static const Duration _timeoutLogInterval = Duration(minutes: 3);
  // URL 이 다시는 성공하지 않으면(영구 실패) _onImageLoadSuccess 의
  // `_lastTimeoutLogTimes.remove(url)` 이 절대 발화하지 않아 엔트리가 영구히
  // 남는다. 새 엔트리를 기록할 때마다 오래된 엔트리를 함께 정리해 "최근
  // 1시간 내 타임아웃이 있었던 URL 집합" 으로 상한을 둔다.
  static const Duration _timeoutLogRetention = Duration(hours: 1);
  // _lastTimeoutLogTimes 정리도 위와 같은 이유로 벽시계 기준 주기 제한을 둔다 —
  // 정리 자체는 (개별 URL 당) _timeoutLogInterval 을 넘길 때만 시도되지만,
  // distinct URL 수천 개가 각자 자신의 3분 게이트를 넘기며 거의 동시에 새
  // 엔트리를 기록하면 그 각각이 맵 전체를 훑는 O(n) 정리를 유발할 수 있다.
  static DateTime? _lastTimeoutLogSweep;
  static const Duration _timeoutLogSweepInterval = Duration(seconds: 30);

  // 위 두 sweep 주기 제한은 "정리 비용"만 시간당으로 묶을 뿐, sweep 사이에
  // 유입되는 엔트리 수(맵 카디널리티) 자체는 묶지 않는다 — CDN 장애로 30초
  // sweep 주기 안에 distinct URL 수천 개가 동시에 실패/타임아웃되면, 다음
  // sweep 이 돌기 전까지 두 맵 모두 무제한으로 커질 수 있다. 신규 키를 넣기
  // 직전에 카디널리티 상한을 직접 걸어, sweep 타이밍과 무관하게 최악의 경우도
  // 유계로 만든다.
  //
  // 상한 2000 의 근거: 두 맵 모두 "실패/타임아웃이 있었던 URL" 만 담으므로
  // 값이 작다. CDN 이미지 URL 은 평균 100~160자(여유 있게 150자, UTF-16 2바이트
  // +노드 오버헤드 감안 문자당 3바이트 ≈ 450바이트 — _successfullyLoadedImageUrls
  // 산정과 동일 기준). _lastTimeoutLogTimes 는 값이 DateTime 하나(수십 바이트)라
  // 항목당 대략 500바이트, 2000개 전체로 ~1MB. _failureHistory 는 값이
  // List<DateTime> 이라 조금 더 크다 — _shouldRetry 가 recentFailures < 15 를
  // 재시도 조건으로 쓰므로 항목당 최악 15개(각 수십 바이트)+List 오버헤드로
  // 대략 1.1KB, 2000개 전체로도 ~2.2MB. 둘 다 이 위젯이 이미 유지하는 200MB
  // 이미지 캐시에 비해 무시할 수 있는 크기이면서, "CDN 장애로 distinct URL
  // 수천 개가 동시 실패" 시나리오를 sweep 이전에도 대부분 그대로 수용할 만큼
  // 넉넉하다.
  //
  // 상한 도달 시 가장 오래 삽입된 키를 버린다 — LRU 가 아니라 FIFO다. 두 맵
  // 모두 값이 "이 URL 에 대한 게이트 상태"일 뿐이고, 재사용(재실패/재타임아웃)
  // 시에도 굳이 최신 위치로 옮길 필요가 없다: 잘못 버려도 결과가 완만하다 —
  // 실패 이력을 잃으면 다음 실패 시 재시도 카운트가 0부터 다시 쌓일 뿐이고
  // (더 관대해지는 쪽이라 안전 방향), 타임아웃 로그 시각을 잃으면 로그 한 줄이
  // 중복될 뿐이다. _successfullyLoadedImageUrls 처럼 "재사용해도 밀려나면
  // 안 되는" 사용자 가시적 요구가 없으므로, 갱신(touch)까지 갖춘 LRU 를 도입할
  // 이유가 없다.
  static const int _maxTrackedUrlMapEntries = 2000;

  static void _capTrackedUrlMapSize<V>(Map<String, V> map, String incomingKey) {
    if (map.containsKey(incomingKey)) return;
    if (map.length >= _maxTrackedUrlMapEntries) {
      map.remove(map.keys.first);
    }
  }

  int _reloadToken = 0;

  Duration get effectiveTimeout => widget.timeout ?? _defaultTimeout;
  int get effectiveMaxRetries => widget.maxRetries ?? _defaultMaxRetries;

  Duration _calculateBackoffDelay(int retryCount) {
    final baseDelay = Duration(milliseconds: 500);
    final delay = Duration(
      milliseconds: (baseDelay.inMilliseconds * math.pow(1.5, retryCount))
          .toInt(),
    );
    return delay > _maxBackoffDelay ? _maxBackoffDelay : delay;
  }

  @override
  void initState() {
    super.initState();
    // Visibility gates use post-frame geometry; request throttling stays in
    // the Image request pipeline.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    _initializeLazyLoading();

    if (widget.enableMemoryOptimization) {
      _PicnicCachedNetworkImageState._optimizeImageCache();
    }
  }

  /// Lazy Loading 초기화
  void _initializeLazyLoading() {
    // 이미 성공적으로 로딩된 이미지인지 확인
    final isAlreadyLoaded = _successfullyLoadedImageUrls.contains(
      widget.imageUrl,
    );

    if (isAlreadyLoaded) {
      // Source 성공 이력은 lazy 진입만 앞당긴다. 캐시가 evict됐을 수 있으므로
      // 실제 첫 frame 전에는 loaded/ready 상태로 간주하지 않는다.
      _shouldLoadImage = true;
      _isImageLoaded = false;
      _loading = false;
      _rememberSuccessfullyLoadedImageUrl(widget.imageUrl);
      return;
    }

    _isImageLoaded = false;
    switch (widget.lazyLoadingStrategy) {
      case LazyLoadingStrategy.none:
        _shouldLoadImage = true;
        break;
      case LazyLoadingStrategy.viewport:
      case LazyLoadingStrategy.preload:
      case LazyLoadingStrategy.progressive:
        _shouldLoadImage = false;
        break;
    }
  }

  /// 가시성 변경 처리
  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final isVisible = info.visibleFraction >= widget.visibilityThreshold;

    if (isVisible != _isVisible) {
      _isVisible = isVisible;

      if (isVisible && !_shouldLoadImage) {
        _triggerLazyLoad();
      }

      // 가시화 시 이전에 에러가 있었고 재시도 가능하면 즉시 재시도 트리거
      if (isVisible && _hasError && _retryCount < effectiveMaxRetries) {
        setState(() {
          _hasError = false;
          _loading = true;
          _shouldLoadImage = true;
        });
      }
    }
  }

  /// Lazy Loading 트리거
  ///
  /// 예전에는 앱 레벨에서 동시 로딩을 8개로 제한하고 초과분을 전역 큐에 넣었으나,
  /// (1) 실제 다운로드 동시성은 flutter_cache_manager 가 이미 제어한다 —
  ///     WebHelper 가 concurrentFetches(기본 10)를 넘는 요청을 내부 큐에 넣는다
  ///     (flutter_cache_manager/lib/src/web/web_helper.dart). 따라서 앱 레벨의
  ///     추가 게이트는 중복이고,
  /// (2) 전역 카운터가 acquire/release 불일치(dispose 무조건 감소 + math.max
  ///     clamp)로 부정확해 큐 게이트가 사실상 발동하지 않았으며,
  /// (3) 카운터를 정확히 만들면 리스트 화면(항상 8개 이상 동시 로딩)에서 무관한
  ///     이미지가 큐에 갇히거나 저대역폭 오판(_isLowBandwidthConnection)이 켜지는
  ///     회귀를 낳았다.
  /// → 전역 동시성 제어와 최초 시간 지연 없이 visibility 진입 즉시 로드한다.
  void _triggerLazyLoad() {
    if (_shouldLoadImage || !mounted) return;
    _startLoading();
  }

  /// 로딩 시작
  void _startLoading() {
    if (!mounted) return;

    setState(() {
      _shouldLoadImage = true;
      _isImageLoaded = false;
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _imageTimeoutTimer?.cancel();
    // visibility_detector 는 RenderObject dispose 시 전역 맵을 정리하지 않고,
    // `_lastVisibility` 는 "보이지 않게 될 때"만 엔트리를 지운다. 즉 보이는 상태로
    // dispose 되면(라우트 pop, 리스트 축소, pull-to-refresh) 엔트리가 영구히 남는다.
    // URL 기반 키일 때는 distinct URL 수만큼 유한했지만, 위의 인스턴스 고유 키는
    // dispose 마다 하나씩 무한히 늘어나므로 반드시 직접 정리해 줘야 한다.
    VisibilityDetectorController.instance.forget(_visibilityKey);
    super.dispose();
  }

  /// Flutter ImageCache 설정 최적화
  static void _optimizeImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;

    if (kIsWeb) {
      // 웹에서는 더 보수적인 설정
      imageCache.maximumSizeBytes = 150 * 1024 * 1024; // 150MB
      imageCache.maximumSize = 300; // 최대 300개 이미지
    } else {
      // 모바일에서는 메모리 사용 폭을 완화
      imageCache.maximumSizeBytes = 200 * 1024 * 1024; // 200MB
      imageCache.maximumSize = 500; // 최대 500개 이미지
    }

    // 캐시 정리 임계값을 더 높게 설정하여 빈번한 정리 방지
    imageCache.pendingImageCount;
  }

  @override
  void didUpdateWidget(PicnicCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl) {
      _resetActiveRequest(incrementGeneration: true);
      _shouldLoadImage =
          widget.lazyLoadingStrategy == LazyLoadingStrategy.none ||
          _successfullyLoadedImageUrls.contains(widget.imageUrl);
      if (_successfullyLoadedImageUrls.contains(widget.imageUrl)) {
        _rememberSuccessfullyLoadedImageUrl(widget.imageUrl);
      }

      if (!_shouldLoadImage && _isVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_shouldLoadImage && _isVisible) {
            _triggerLazyLoad();
          }
        });
      }
    } else if (oldWidget.lazyLoadingStrategy != widget.lazyLoadingStrategy &&
        widget.lazyLoadingStrategy == LazyLoadingStrategy.none) {
      _shouldLoadImage = true;
    }

    if (oldWidget.timeout != widget.timeout) {
      _imageTimeoutTimer?.cancel();
      _imageTimeoutTimer = null;
      _attemptStartedFor = null;
    }
  }

  void _resetActiveRequest({required bool incrementGeneration}) {
    if (incrementGeneration) _imageRequestGeneration++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _imageTimeoutTimer?.cancel();
    _imageTimeoutTimer = null;
    _activeRequestIdentity = null;
    _activeImageConfiguration = null;
    _requestKeyResolutionScheduledFor = null;
    _loadAllowanceCheckScheduledFor = null;
    _attemptStartedFor = null;
    _successTransitionScheduledFor = null;
    _successfulAttempt = null;
    _handledErrorAttempt = null;
    _cacheProbeIdentity = null;
    _cachePromotionScheduledFor = null;
    _reloadToken = 0;
    _retryCount = 0;
    _loading = false;
    _hasError = false;
    _isImageLoaded = false;
    _loadStartTime = null;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.imageRequest == null ||
          widget.imageRequest!.imageUrl == widget.imageUrl,
      'imageRequest.imageUrl must match imageUrl.',
    );

    if (widget.lazyLoadingStrategy == LazyLoadingStrategy.none) {
      return _buildForLayout(loadImage: true);
    }

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildForLayout(loadImage: _shouldLoadImage),
    );
  }

  Widget _buildForLayout({required bool loadImage}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _resolveLayoutDimension(
          widget.width,
          constraints.maxWidth,
          constraints.constrainWidth,
        );
        final height = _resolveLayoutDimension(
          widget.height,
          constraints.maxHeight,
          constraints.constrainHeight,
        );
        final hasArea = width > 0 && height > 0;

        if (!hasArea || widget.imageUrl.trim().isEmpty) {
          _unbindActiveRequest();
          return SizedBox(
            width: width,
            height: height,
            child: _buildPlaceholder(width, height),
          );
        }

        if (!loadImage) {
          _probeCurrentCache(context, width, height);
          return SizedBox(
            width: width,
            height: height,
            child: _buildPlaceholder(width, height),
          );
        }

        try {
          final request =
              widget.imageRequest ??
              _resolveRequestForLayout(context, width, height);
          if (request.url.trim().isEmpty) {
            _unbindActiveRequest();
            return SizedBox(
              width: width,
              height: height,
              child: _buildPlaceholder(width, height),
            );
          }

          final configuration = createLocalImageConfiguration(
            context,
            size: Size(width, height),
          );
          _bindActiveRequest(request, configuration);
          final attempt = (
            generation: _imageRequestGeneration,
            reloadToken: _reloadToken,
          );
          _ensureAttemptMonitoring(request, configuration, attempt);

          return SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: Image(
                key: ValueKey((
                  request.url,
                  request.decodeWidth,
                  request.decodeHeight,
                  _reloadToken,
                )),
                image: request.provider,
                width: width,
                height: height,
                fit: widget.fit,
                gaplessPlayback: false,
                frameBuilder: (context, child, frame, synchronousCall) {
                  if (frame == null) {
                    if (_isCurrentAttempt(request, attempt) && _hasError) {
                      return _buildErrorWidget(width, height);
                    }
                    return _buildPlaceholder(width, height);
                  }
                  _onImageLoadSuccess(request, attempt);
                  return child;
                },
                errorBuilder: (context, error, stackTrace) {
                  return _handleAttemptError(
                    request,
                    attempt,
                    error,
                    stackTrace,
                    width,
                    height,
                  );
                },
              ),
            ),
          );
        } catch (error, stackTrace) {
          logger.e('이미지 요청 생성 중 예외 발생: $error (URL: ${widget.imageUrl})');
          Sentry.captureException(error, stackTrace: stackTrace);
          _unbindActiveRequest();
          return _buildErrorWidget(width, height);
        }
      },
    );
  }

  double _resolveLayoutDimension(
    double? explicit,
    double maximum,
    double Function(double) constrain,
  ) {
    final candidate = _isValidDimension(explicit)
        ? explicit!
        : maximum.isFinite && maximum >= 0
        ? maximum
        : 100.0;
    return constrain(candidate);
  }

  bool _isValidDimension(double? value) =>
      value != null && value.isFinite && value > 0;

  PicnicImageRequest _resolveRequestForLayout(
    BuildContext context,
    double renderedWidth,
    double renderedHeight,
  ) {
    final hasExplicitWidth = _isValidDimension(widget.width);
    final hasExplicitHeight = _isValidDimension(widget.height);
    final double? requestWidth;
    final double? requestHeight;

    if (hasExplicitWidth || hasExplicitHeight) {
      requestWidth = hasExplicitWidth ? renderedWidth : null;
      requestHeight = hasExplicitHeight ? renderedHeight : null;
    } else {
      requestWidth = renderedWidth;
      requestHeight = widget.fit == BoxFit.cover ? renderedHeight : null;
    }

    return PicnicImageRequest.resolve(
      context: context,
      imageUrl: widget.imageUrl,
      width: requestWidth,
      height: requestHeight,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      maxQualityOverride: widget.maxQualityOverride,
      maxResolutionMultiplierCap: widget.maxResolutionMultiplierCap,
    );
  }

  void _probeCurrentCache(BuildContext context, double width, double height) {
    final PicnicImageRequest request;
    try {
      request =
          widget.imageRequest ??
          _resolveRequestForLayout(context, width, height);
    } on FormatException {
      return;
    } on ArgumentError {
      return;
    }
    if (request.url.trim().isEmpty) return;

    final identity = (
      url: request.url,
      decodeWidth: request.decodeWidth,
      decodeHeight: request.decodeHeight,
      provider: request.provider,
    );
    if (_cacheProbeIdentity == identity ||
        _cachePromotionScheduledFor == identity) {
      return;
    }
    _cacheProbeIdentity = identity;
    final configuration = createLocalImageConfiguration(
      context,
      size: Size(width, height),
    );
    unawaited(
      request
          .obtainKey(configuration)
          .then<void>(
            (key) {
              if (_cacheProbeIdentity != identity ||
                  !mounted ||
                  _shouldLoadImage ||
                  widget.imageUrl != request.imageUrl) {
                return;
              }
              _cacheProbeIdentity = null;
              if (!PaintingBinding.instance.imageCache.containsKey(key)) return;
              _cachePromotionScheduledFor = identity;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_cachePromotionScheduledFor != identity) return;
                _cachePromotionScheduledFor = null;
                if (!mounted ||
                    _shouldLoadImage ||
                    widget.imageUrl != request.imageUrl) {
                  return;
                }
                setState(() {
                  _shouldLoadImage = true;
                });
              });
            },
            onError: (Object _, StackTrace _) {
              if (_cacheProbeIdentity == identity) _cacheProbeIdentity = null;
            },
          ),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    if (widget.placeholder != null) {
      return SizedBox(width: width, height: height, child: widget.placeholder!);
    }

    if (!widget.showLoadingOverlay) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Container(
          width: width,
          height: height,
          color: const Color.fromRGBO(158, 158, 158, 0.05),
          child: ShimmerLoading(
            isLoading: true,
            child: Container(width: width, height: height, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _unbindActiveRequest() {
    if (_activeRequestIdentity == null) return;
    _resetActiveRequest(incrementGeneration: true);
  }

  void _bindActiveRequest(
    PicnicImageRequest request,
    ImageConfiguration configuration,
  ) {
    final identity = (
      url: request.url,
      decodeWidth: request.decodeWidth,
      decodeHeight: request.decodeHeight,
      provider: request.provider,
    );
    if (_activeRequestIdentity != null && _activeRequestIdentity != identity) {
      _resetActiveRequest(incrementGeneration: true);
    }
    _activeRequestIdentity = identity;
    _activeImageConfiguration = configuration;
  }

  void _ensureAttemptMonitoring(
    PicnicImageRequest request,
    ImageConfiguration configuration,
    _ImageAttempt attempt,
  ) {
    if (_successfulAttempt == attempt ||
        _attemptStartedFor == attempt ||
        _requestKeyResolutionScheduledFor == attempt) {
      return;
    }
    _requestKeyResolutionScheduledFor = attempt;

    try {
      unawaited(
        request
            .obtainKey(configuration)
            .then<void>(
              (key) {
                if (_requestKeyResolutionScheduledFor == attempt) {
                  _requestKeyResolutionScheduledFor = null;
                }
                if (!_isCurrentAttempt(request, attempt)) return;
                _startCurrentAttemptWhenAllowed(request, attempt, key);
              },
              onError: (Object error, StackTrace stackTrace) {
                if (_requestKeyResolutionScheduledFor == attempt) {
                  _requestKeyResolutionScheduledFor = null;
                }
                if (!_isCurrentAttempt(request, attempt)) return;
                _consumeAttemptError(
                  request,
                  attempt,
                  error,
                  stackTrace,
                  fromTimeout: false,
                );
              },
            ),
      );
    } catch (error, stackTrace) {
      _requestKeyResolutionScheduledFor = null;
      _consumeAttemptError(
        request,
        attempt,
        error,
        stackTrace,
        fromTimeout: false,
      );
    }
  }

  void _startCurrentAttemptWhenAllowed(
    PicnicImageRequest request,
    _ImageAttempt attempt,
    Object key,
  ) {
    if (!mounted) return;
    _startAttemptWhenAllowed(context, request, attempt, key);
  }

  void _startAttemptWhenAllowed(
    BuildContext context,
    PicnicImageRequest request,
    _ImageAttempt attempt,
    Object key,
  ) {
    if (!_isCurrentAttempt(request, attempt) ||
        _successfulAttempt == attempt ||
        _attemptStartedFor == attempt) {
      return;
    }

    final cacheContainsKey = PaintingBinding.instance.imageCache.containsKey(
      key,
    );
    final shouldDefer =
        context.mounted &&
        Scrollable.recommendDeferredLoadingForContext(context);
    if (!cacheContainsKey && shouldDefer) {
      _scheduleLoadAllowanceCheck(context, request, attempt, key);
      return;
    }

    _attemptStartedFor = attempt;
    _loading = true;
    _hasError = false;
    _isImageLoaded = false;
    _loadStartTime ??= DateTime.now();
    if (PicnicCachedNetworkImage.disableTimeoutForTest) return;

    late final Timer timeoutTimer;
    timeoutTimer = Timer(effectiveTimeout, () {
      if (!identical(_imageTimeoutTimer, timeoutTimer)) return;
      _imageTimeoutTimer = null;
      if (!_isCurrentAttempt(request, attempt) ||
          _successfulAttempt == attempt ||
          !_loading ||
          _hasError ||
          _isImageLoaded) {
        return;
      }

      final now = DateTime.now();
      final lastLoggedAt = _lastTimeoutLogTimes[request.url];
      if (lastLoggedAt == null ||
          now.difference(lastLoggedAt) >= _timeoutLogInterval) {
        _capTrackedUrlMapSize(_lastTimeoutLogTimes, request.url);
        _lastTimeoutLogTimes[request.url] = now;

        final lastSweep = _lastTimeoutLogSweep;
        if (lastSweep == null ||
            now.difference(lastSweep) >= _timeoutLogSweepInterval) {
          _lastTimeoutLogSweep = now;
          _lastTimeoutLogTimes.removeWhere(
            (url, time) => now.difference(time) >= _timeoutLogRetention,
          );
        }
        logger.w('이미지 로딩 타임아웃: ${request.url}');
      }

      _consumeAttemptError(
        request,
        attempt,
        'Timeout after ${effectiveTimeout.inSeconds} seconds',
        StackTrace.current,
        fromTimeout: true,
      );
      if (_isCurrentAttempt(request, attempt)) setState(() {});
    });
    _imageTimeoutTimer = timeoutTimer;
  }

  void _scheduleLoadAllowanceCheck(
    BuildContext context,
    PicnicImageRequest request,
    _ImageAttempt attempt,
    Object key,
  ) {
    if (_loadAllowanceCheckScheduledFor == attempt) return;
    _loadAllowanceCheckScheduledFor = attempt;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (_loadAllowanceCheckScheduledFor != attempt) return;
      _loadAllowanceCheckScheduledFor = null;
      if (!_isCurrentAttempt(request, attempt) || !context.mounted) return;
      _startAttemptWhenAllowed(context, request, attempt, key);
    });
  }

  Widget _handleAttemptError(
    PicnicImageRequest request,
    _ImageAttempt attempt,
    Object error,
    StackTrace? stackTrace,
    double width,
    double height,
  ) {
    if (!_isCurrentAttempt(request, attempt)) {
      return SizedBox(width: width, height: height);
    }

    _consumeAttemptError(
      request,
      attempt,
      error,
      stackTrace,
      fromTimeout: false,
    );
    return _hasError
        ? _buildErrorWidget(width, height)
        : _buildPlaceholder(width, height);
  }

  void _consumeAttemptError(
    PicnicImageRequest request,
    _ImageAttempt attempt,
    Object error,
    StackTrace? stackTrace, {
    required bool fromTimeout,
  }) {
    if (!_isCurrentAttempt(request, attempt) ||
        _handledErrorAttempt == attempt ||
        _successfulAttempt == attempt) {
      return;
    }
    _handledErrorAttempt = attempt;
    _imageTimeoutTimer?.cancel();
    _imageTimeoutTimer = null;
    _loading = false;
    _isImageLoaded = false;

    logger.w('이미지 로딩 실패 감지: ${request.url}, error: $error');
    _recordFailure(request.url);
    if (_shouldRetry(request.url, error)) {
      _hasError = false;
      _scheduleRetry(request, attempt, evictFailedKey: !fromTimeout);
      return;
    }

    _hasError = true;
    _onImageLoadError(request.url, error, request, attempt);
  }

  // 실패 기록
  //
  // 예전에는 url 별 리스트만 1시간 넘은 항목을 걸러냈다 — 그런데 그 필터는
  // 해당 url 이 다시 실패해야만 실행되므로, 1시간 넘게 재실패가 없는 url 은
  // 빈 리스트를 값으로 가진 채 맵 키로 영구히 남았다(distinct 실패 URL 수만큼
  // 무한 누적). 맵 전체를 훑어 "최근 1시간 내 실패가 있는 URL" 만 남기도록
  // 정리하되, 그 정리 자체는 _failureHistorySweepInterval 마다 최대 한 번만
  // 실행한다 — 실패 1건마다 매번 돌리면 CDN 장애로 distinct URL 수천 개가
  // 동시에 실패할 때 이 경로가 O(실패 횟수 × distinct URL 수)가 된다.
  void _recordFailure(String url) {
    final now = DateTime.now();
    _capTrackedUrlMapSize(_failureHistory, url);
    _failureHistory[url] = (_failureHistory[url] ?? [])..add(now);

    final lastSweep = _lastFailureHistorySweep;
    if (lastSweep == null ||
        now.difference(lastSweep) >= _failureHistorySweepInterval) {
      _lastFailureHistorySweep = now;
      _failureHistory.removeWhere((key, times) {
        times.removeWhere((time) => now.difference(time).inHours > 1);
        return times.isEmpty;
      });
    }
  }

  // 재시도 여부 결정
  bool _shouldRetry(String url, dynamic error) {
    if (_retryCount >= effectiveMaxRetries) return false;

    final errorString = error.toString().toLowerCase();
    // 더 포괄적인 재시도 가능한 에러 목록
    final retryableErrors = [
      'timeout',
      'connection',
      'network',
      'socket',
      'handshake',
      'host',
      'resolve', // DNS 해결 실패
      'unreachable', // 네트워크 도달 불가
      'interrupted', // 연결 중단
      'refused', // 연결 거부
      'reset', // 연결 재설정
      'dispose', // 디코드 중 리소스 해제
    ];

    final isRetryableError = retryableErrors.any(
      (keyword) => errorString.contains(keyword),
    );

    final recentFailures = _failureHistory[url]?.length ?? 0;

    // 더 관대한 재시도 조건 (기존 10회에서 15회로 증가)
    return isRetryableError && recentFailures < 15;
  }

  // 재시도 스케줄링
  void _scheduleRetry(
    PicnicImageRequest request,
    _ImageAttempt attempt, {
    required bool evictFailedKey,
  }) {
    _retryCount++;
    final delay = _calculateBackoffDelay(_retryCount);

    logger.i(
      '이미지 로드 재시도 예정: ${request.url} '
      '(시도: $_retryCount/$effectiveMaxRetries, 지연: ${delay.inSeconds}초)',
    );

    _retryTimer?.cancel();
    late final Timer retryTimer;
    retryTimer = Timer(delay, () async {
      if (!identical(_retryTimer, retryTimer)) return;
      _retryTimer = null;
      if (!_isCurrentAttempt(request, attempt) ||
          _successfulAttempt == attempt) {
        return;
      }

      if (evictFailedKey) {
        await request.provider.evict(
          configuration: _activeImageConfiguration ?? ImageConfiguration.empty,
        );
        if (!_isCurrentAttempt(request, attempt) ||
            _successfulAttempt == attempt) {
          return;
        }
      }

      setState(() {
        _reloadToken++;
        _requestKeyResolutionScheduledFor = null;
        _loadAllowanceCheckScheduledFor = null;
        _attemptStartedFor = null;
        _successTransitionScheduledFor = null;
        _successfulAttempt = null;
        _handledErrorAttempt = null;
        logger.i('이미지 로드 재시도 시작: ${request.url} (토큰: $_reloadToken)');
        _loading = false;
        _hasError = false;
        _isImageLoaded = false;
        _loadStartTime = null;
        _shouldLoadImage = true;
      });
    });
    _retryTimer = retryTimer;
  }

  // 에러 위젯 생성
  Widget _buildErrorWidget(double? width, double? height) {
    if (widget.errorWidget != null) {
      return SizedBox(width: width, height: height, child: widget.errorWidget);
    }

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _retryCount >= effectiveMaxRetries
                      ? Icons.image_not_supported
                      : Icons.refresh,
                  color: Colors.grey[600],
                  size: math.min(width ?? 40, height ?? 40) * 0.3,
                ),
                if (_retryCount >= effectiveMaxRetries) ...[
                  const SizedBox(height: 4),
                  Text(
                    '이미지 로드 실패',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 메모리 압박 상황 체크
  Future<bool> _checkMemoryPressure() async {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final maxSizeBytes = imageCache.maximumSizeBytes;
      final currentSizeBytes = imageCache.currentSizeBytes;

      final usagePercentage = (currentSizeBytes / maxSizeBytes) * 100;

      return usagePercentage >= 90.0;
    } catch (e) {
      logger.e('메모리 압박 상황 체크 중 오류: $e');
      return false;
    }
  }

  bool _shouldLogMemoryPressure(DateTime now) {
    final lastLoggedAt = _lastMemoryPressureLog;
    if (lastLoggedAt == null ||
        now.difference(lastLoggedAt) >= _memoryPressureLogInterval) {
      _lastMemoryPressureLog = now;
      return true;
    }
    return false;
  }

  bool _isCurrentAttempt(PicnicImageRequest request, _ImageAttempt attempt) {
    return mounted &&
        _imageRequestGeneration == attempt.generation &&
        _reloadToken == attempt.reloadToken &&
        widget.imageUrl == request.imageUrl &&
        _activeRequestIdentity ==
            (
              url: request.url,
              decodeWidth: request.decodeWidth,
              decodeHeight: request.decodeHeight,
              provider: request.provider,
            );
  }

  void _onImageLoadSuccess(
    PicnicImageRequest request,
    _ImageAttempt attempt,
  ) async {
    if (!_isCurrentAttempt(request, attempt) ||
        _successTransitionScheduledFor == attempt ||
        _successfulAttempt == attempt) {
      return;
    }
    _successTransitionScheduledFor = attempt;

    _imageTimeoutTimer?.cancel();
    _imageTimeoutTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;

    final loadDuration = _loadStartTime != null
        ? DateTime.now().difference(_loadStartTime!)
        : Duration.zero;
    _loadStartTime = null;
    _lastTimeoutLogTimes.remove(request.url);
    _retryCount = 0;

    _rememberSuccessfullyLoadedImageUrl(request.imageUrl);
    _loading = false;
    _hasError = false;
    _isImageLoaded = true;
    _successfulAttempt = attempt;
    _successTransitionScheduledFor = null;

    final warningThreshold = Environment.imageLoadWarningThreshold;
    final errorThreshold = Environment.imageLoadErrorThreshold;

    if (kDebugMode && loadDuration.inSeconds > warningThreshold) {
      // 메모리 스냅샷 최적화 - 더 엄격한 조건으로 제한
      if (loadDuration.inSeconds > errorThreshold &&
          loadDuration.inSeconds > 180) {
        final now = DateTime.now();
        final globalLastSnapshot = _lastGlobalSnapshot;

        // 전역적으로 스냅샷 생성 빈도 제한 (최대 15분에 1회)
        if (globalLastSnapshot == null ||
            now.difference(globalLastSnapshot).inMinutes >= 15) {
          final urlLastSnapshot = _lastSnapshotTimes[request.url];

          // 특정 URL에 대한 스냅샷 생성 빈도 제한 (최대 2시간에 1회)
          if (urlLastSnapshot == null ||
              now.difference(urlLastSnapshot).inHours >= 2) {
            final isMemoryPressured = await _checkMemoryPressure();

            if (!isMemoryPressured || loadDuration.inSeconds > 300) {
              _lastSnapshotTimes[request.url] = now;
              _lastGlobalSnapshot = now;
              _snapshotCount++;

              logger.i(
                '느린 이미지 로딩 감지됨 ($_snapshotCount번째): '
                '${request.url} - ${loadDuration.inSeconds}초',
              );
            } else {
              if (_shouldLogMemoryPressure(now)) {
                logger.d('메모리 압박으로 로깅 건너뜀: ${request.url}');
              }
            }
          }
        }

        // 오래된 스냅샷 기록 정리 (4시간 이상)
        _lastSnapshotTimes.removeWhere(
          (key, time) => now.difference(time).inHours >= 4,
        );
      }
    }
  }

  void _onImageLoadError(
    String url,
    Object error,
    PicnicImageRequest request,
    _ImageAttempt attempt,
  ) {
    if (!_isCurrentAttempt(request, attempt)) return;

    logger.e('이미지 로드 에러: $url, error: $error');
    _loadStartTime = null;
  }

  // 테스트 전용: 실제 네트워크 실패/타임아웃 콜백 없이 _failureHistory/
  // _lastTimeoutLogTimes 의 카디널리티 상한 로직만 단위 테스트하기 위한
  // 진입점. 클래스가 private 이라 아래 static 멤버는 파일 하단의 public
  // top-level 래퍼(resetImageLoadTrackingMapsForTest 등)를 통해서만
  // 테스트 파일에 노출된다.
  static void _resetTrackingMapsForTest() {
    _failureHistory.clear();
    _lastTimeoutLogTimes.clear();
    _lastFailureHistorySweep = null;
    _lastTimeoutLogSweep = null;
  }

  static void _recordFailureForTest(String url) {
    _capTrackedUrlMapSize(_failureHistory, url);
    _failureHistory[url] = (_failureHistory[url] ?? [])..add(DateTime.now());
  }

  static void _recordTimeoutLogForTest(String url) {
    _capTrackedUrlMapSize(_lastTimeoutLogTimes, url);
    _lastTimeoutLogTimes[url] = DateTime.now();
  }
}

/// 테스트 전용: 세션 전역 상태인 실패/타임아웃 로그 추적 맵을 초기화한다.
@visibleForTesting
void resetImageLoadTrackingMapsForTest() {
  _PicnicCachedNetworkImageState._resetTrackingMapsForTest();
}

/// 테스트 전용: [_PicnicCachedNetworkImageState._recordFailure] 의 카디널리티
/// 상한 로직만 검증하기 위한 진입점.
@visibleForTesting
void recordFailureForTest(String url) {
  _PicnicCachedNetworkImageState._recordFailureForTest(url);
}

/// 테스트 전용: 타임아웃 로그 상한 로직만 검증하기 위한 진입점.
@visibleForTesting
void recordTimeoutLogForTest(String url) {
  _PicnicCachedNetworkImageState._recordTimeoutLogForTest(url);
}

@visibleForTesting
int get failureHistoryCountForTest =>
    _PicnicCachedNetworkImageState._failureHistory.length;

@visibleForTesting
int get lastTimeoutLogTimesCountForTest =>
    _PicnicCachedNetworkImageState._lastTimeoutLogTimes.length;

@visibleForTesting
int get trackedUrlMapCapacityForTest =>
    _PicnicCachedNetworkImageState._maxTrackedUrlMapEntries;

@visibleForTesting
bool failureHistoryContainsForTest(String url) =>
    _PicnicCachedNetworkImageState._failureHistory.containsKey(url);

@visibleForTesting
bool lastTimeoutLogTimesContainsForTest(String url) =>
    _PicnicCachedNetworkImageState._lastTimeoutLogTimes.containsKey(url);
