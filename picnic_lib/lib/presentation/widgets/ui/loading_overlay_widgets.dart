/// # LoadingOverlay 라이브러리
///
/// 전체화면 로딩 오버레이를 제공하는 포괄적인 Flutter 라이브러리입니다.
/// 다양한 애니메이션, 테마, 상태 관리 방식을 지원합니다.
///
/// ## 주요 컴포넌트
///
/// ### 1. LoadingOverlay
/// 기본적인 로딩 오버레이 위젯
/// ```dart
/// LoadingOverlay(
///   child: Scaffold(...),
/// )
///
/// // 사용법
/// context.showLoading();
/// context.hideLoading();
/// ```
///
/// ### 2. LoadingOverlayWithIcon
/// **앱 아이콘이 포함된 로딩 오버레이 (NEW!)**
/// ```dart
/// LoadingOverlayWithIcon(
///   iconAssetPath: 'assets/app_icon_128.png',
///   enableRotation: false,
///   enableScale: true,
///   enableFade: true,
///   minScale: 0.98,
///   maxScale: 1.02,
///   showProgressIndicator: false,
///   loadingMessage: null,
///   child: Scaffold(...),
/// )
///
/// // 사용법
/// final key = GlobalKey<LoadingOverlayWithIconState>();
/// key.currentState?.show();
/// key.currentState?.hide();
/// ```
///
/// ### 3. SimpleLoadingOverlay
/// Boolean 상태 기반 간단한 사용
/// ```dart
/// SimpleLoadingOverlay(
///   isLoading: _isLoading,
///   message: '처리 중...',
///   theme: LoadingOverlayTheme.dark,
///   child: Scaffold(...),
/// )
/// ```
///
/// ### 4. AdvancedLoadingOverlay
/// Riverpod 기반 고급 기능
/// ```dart
/// AdvancedLoadingOverlay(
///   animationType: LoadingAnimationType.scale,
///   theme: LoadingOverlayTheme.blur,
///   child: Scaffold(...),
/// )
///
/// // Riverpod 사용법
/// ref.showLoadingWithRiverpod(message: '로딩 중...');
/// ref.hideLoadingWithRiverpod();
/// ```
///
/// ### 5. LoadingOverlayManager
/// 글로벌 매니저를 통한 다중 로딩 관리
/// ```dart
/// final manager = LoadingOverlayManager.instance;
///
/// manager.showWithKey(
///   key: 'download',
///   message: '다운로드 중...',
///   theme: LoadingOverlayTheme.dark,
/// );
///
/// manager.hideWithKey('download');
/// manager.hideAll();
/// ```
///
/// ## 애니메이션 타입
/// - `LoadingAnimationType.fade`: 페이드 효과
/// - `LoadingAnimationType.scale`: 스케일 효과
/// - `LoadingAnimationType.slideUp`: 위로 슬라이드
/// - `LoadingAnimationType.slideDown`: 아래로 슬라이드
/// - `LoadingAnimationType.rotate`: 회전 효과
///
/// ## 테마
/// - `LoadingOverlayTheme.dark`: 어두운 테마
/// - `LoadingOverlayTheme.light`: 밝은 테마
/// - `LoadingOverlayTheme.transparent`: 투명 테마
/// - `LoadingOverlayTheme.blur`: 블러 효과 테마
///
/// ## 성능 최적화
/// - RepaintBoundary 자동 적용
/// - 지연 초기화로 메모리 절약
/// - 단일 AnimatedBuilder로 성능 향상
/// - 실시간 FPS 모니터링 (개발 모드)
///
/// ## 예제
/// 완전한 예제는 `example/loading_overlay_example.dart`를 참조하세요.
///
/// ## 실제 사용 사례
/// - 파일 업로드/다운로드
/// - API 요청 처리
/// - 데이터 동기화
/// - 이미지 저장/공유
/// - 복잡한 계산 작업
library loading_overlay_widgets;

// 기본 위젯
export 'loading_overlay.dart';

// 앱 아이콘 포함 로딩 오버레이
export 'loading_overlay_with_icon.dart';

// 고급 위젯 및 상태 관리
export 'loading_overlay_manager.dart'
    show
        LoadingOverlayNotifier,
        LoadingAnimationType,
        LoadingOverlayTheme,
        LoadingOverlayManager,
        LoadingOverlayThemeData,
        LoadingOverlayRiverpodRef,
        loadingOverlayProvider;
export 'loading_overlay_advanced.dart';
