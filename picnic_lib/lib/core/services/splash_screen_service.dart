import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 스플래시 스크린 관련 설정
class SplashScreenConfig {
  final Duration minDisplayDuration;
  final Duration fadeTransitionDuration;
  final Color backgroundColor;
  final Color darkModeBackgroundColor;
  final bool showProgressIndicator;
  final bool enableBrandingAnimation;

  const SplashScreenConfig({
    this.minDisplayDuration = const Duration(milliseconds: 2000),
    this.fadeTransitionDuration = const Duration(milliseconds: 500),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.darkModeBackgroundColor = const Color(0xFF1F2937),
    this.showProgressIndicator = true,
    this.enableBrandingAnimation = true,
  });
}

/// 스플래시 스크린 상태
enum SplashScreenState {
  initializing,
  loading,
  ready,
  transitioning,
  completed,
}

/// 초기화 단계별 진행 상태
class InitializationProgress {
  final String stageName;
  final double progress; // 0.0 ~ 1.0
  final String description;
  final bool isCompleted;

  const InitializationProgress({
    required this.stageName,
    required this.progress,
    required this.description,
    this.isCompleted = false,
  });
}

/// 스플래시 스크린 서비스
///
/// 앱 시작 시 표시되는 스플래시 스크린의 상태와 전환을 관리합니다:
/// - 초기화 진행 상태 추적
/// - 매끄러운 전환 애니메이션
/// - 브랜딩과 일관성 있는 시각적 경험
/// - 적응적 스플래시 지속 시간
class SplashScreenService {
  static final SplashScreenService _instance = SplashScreenService._internal();
  factory SplashScreenService() => _instance;
  SplashScreenService._internal();

  // 설정
  SplashScreenConfig _config = const SplashScreenConfig();

  // 상태 관리
  SplashScreenState _state = SplashScreenState.initializing;
  final StreamController<SplashScreenState> _stateController =
      StreamController<SplashScreenState>.broadcast();

  // 진행률 관리
  double _overallProgress = 0.0;
  final StreamController<InitializationProgress> _progressController =
      StreamController<InitializationProgress>.broadcast();

  // 타이밍 관리
  DateTime? _startTime;
  Timer? _minDurationTimer;
  final Completer<void> _readyCompleter = Completer<void>();

  // 초기화 매니저와의 연동 (순환 의존성 방지를 위해 제거)
  // 대신 외부에서 초기화 상태 함수를 주입받습니다
  bool Function(String)? _isStageCompletedFn;

  /// 서비스 초기화
  void initialize({
    SplashScreenConfig? config,
    bool Function(String)? isStageCompletedFn,
  }) {
    _config = config ?? _config;
    _isStageCompletedFn = isStageCompletedFn;
    _startTime = DateTime.now();
    _state = SplashScreenState.initializing;

    logger.i('🎨 스플래시 스크린 서비스 초기화');

    _stateController.add(_state);

    // 초기화 상태 확인 함수가 있는 경우에만 추적 시작
    if (_isStageCompletedFn != null) {
      _startInitializationTracking();
    }
  }

  /// 스플래시 스크린 설정
  void configure(SplashScreenConfig config) {
    _config = config;
  }

  /// 초기화 추적 시작
  void _startInitializationTracking() {
    // 최소 표시 시간 타이머 설정
    _minDurationTimer = Timer(_config.minDisplayDuration, () {
      logger.d('스플래시 최소 표시 시간 완료');
    });

    // 초기화 단계별 진행률 추적
    _trackInitializationStages();
  }

  /// 초기화 단계별 진행률 추적
  void _trackInitializationStages() {
    // _isStageCompletedFn이 없으면 추적하지 않음
    if (_isStageCompletedFn == null) {
      logger.w('초기화 상태 확인 함수가 없어 진행률 추적을 건너뜀');
      return;
    }

    // 예상 초기화 단계들과 가중치
    final stages = {
      'flutter_bindings': 0.05, // InitializationManager 상수 대신 직접 문자열 사용
      'screen_util': 0.10,
      'critical_services': 0.15,
      'asset_loading': 0.25,
      'data_services': 0.30,
      'auth_services': 0.10,
      'reflection': 0.05,
      'lazy_loading': 0.15,
      'app_widget': 0.05,
    };

    double cumulativeProgress = 0.0;

    // 각 단계 완료를 주기적으로 확인
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      bool hasUpdate = false;
      double newProgress = 0.0;

      for (final entry in stages.entries) {
        final stageName = entry.key;
        final weight = entry.value;

        if (_isStageCompletedFn!(stageName)) {
          newProgress += weight;
        }
      }

      if (newProgress != cumulativeProgress) {
        cumulativeProgress = newProgress;
        hasUpdate = true;

        // 현재 진행 중인 단계 찾기
        String currentStage = '초기화 중...';
        for (final stageName in stages.keys) {
          if (!_isStageCompletedFn!(stageName)) {
            currentStage = _getStageDisplayName(stageName);
            break;
          }
        }

        final progress = InitializationProgress(
          stageName: currentStage,
          progress: newProgress,
          description: currentStage,
          isCompleted: newProgress >= 1.0,
        );

        _overallProgress = newProgress;
        _progressController.add(progress);

        // 로딩 상태 업데이트
        if (_state == SplashScreenState.initializing && newProgress > 0) {
          _setState(SplashScreenState.loading);
        }
      }

      // 초기화 완료 확인
      if (newProgress >= 1.0) {
        timer.cancel();
        _onInitializationCompleted();
      }
    });
  }

  /// 단계명을 사용자 친화적 이름으로 변환
  String _getStageDisplayName(String stageName) {
    switch (stageName) {
      case 'flutter_bindings':
        return '앱 환경 준비 중...';
      case 'screen_util':
        return '화면 설정 중...';
      case 'critical_services':
        return '핵심 서비스 시작 중...';
      case 'asset_loading':
        return '리소스 로딩 중...';
      case 'data_services':
        return '데이터 서비스 연결 중...';
      case 'auth_services':
        return '인증 서비스 준비 중...';
      case 'reflection':
        return '앱 구성 요소 설정 중...';
      case 'lazy_loading':
        return '최적화 적용 중...';
      case 'app_widget':
        return '앱 시작 준비 완료...';
      default:
        return '초기화 중...';
    }
  }

  /// 초기화 완료 처리
  void _onInitializationCompleted() {
    logger.i('✅ 앱 초기화 완료');
    _setState(SplashScreenState.ready);

    // 최소 표시 시간과 초기화 완료 시간 중 늦은 시점에 전환
    final elapsedTime = DateTime.now().difference(_startTime!);

    if (elapsedTime >= _config.minDisplayDuration) {
      _startTransition();
    } else {
      // 최소 표시 시간 완료 대기
      final remainingTime = _config.minDisplayDuration - elapsedTime;
      Timer(remainingTime, _startTransition);
    }
  }

  /// 스플래시에서 메인 앱으로 전환 시작
  void _startTransition() {
    logger.i('🔄 스플래시 화면 전환 시작');
    _setState(SplashScreenState.transitioning);

    // 전환 애니메이션 완료 후 최종 완료 상태로 변경
    Timer(_config.fadeTransitionDuration, () {
      _setState(SplashScreenState.completed);
      _readyCompleter.complete();
    });
  }

  /// 상태 업데이트
  void _setState(SplashScreenState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
      logger.d('스플래시 상태 변경: $_state');
    }
  }

  /// 스플래시 완료 대기
  Future<void> waitForCompletion() async {
    await _readyCompleter.future;
  }

  /// 현재 상태 반환
  SplashScreenState get currentState => _state;

  /// 상태 스트림
  Stream<SplashScreenState> get stateStream => _stateController.stream;

  /// 진행률 스트림
  Stream<InitializationProgress> get progressStream =>
      _progressController.stream;

  /// 현재 진행률 반환
  double get currentProgress => _overallProgress;

  /// 설정 반환
  SplashScreenConfig get config => _config;

  /// 스플래시 완료 여부
  bool get isCompleted => _state == SplashScreenState.completed;

  /// 서비스 종료
  void dispose() {
    _minDurationTimer?.cancel();
    _stateController.close();
    _progressController.close();
  }
}
