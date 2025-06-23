import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 글로벌 LoadingOverlay 상태를 관리하는 프로바이더
final loadingOverlayProvider =
    StateNotifierProvider<LoadingOverlayNotifier, LoadingOverlayState>((ref) {
  return LoadingOverlayNotifier();
});

/// LoadingOverlay의 상태를 나타내는 클래스
@immutable
class LoadingOverlayState {
  /// 로딩 표시 여부
  final bool isLoading;

  /// 로딩 메시지
  final String? message;

  /// 커스텀 로딩 위젯
  final Widget? customWidget;

  /// 애니메이션 타입
  final LoadingAnimationType animationType;

  /// 테마
  final LoadingOverlayTheme theme;

  const LoadingOverlayState({
    this.isLoading = false,
    this.message,
    this.customWidget,
    this.animationType = LoadingAnimationType.fade,
    this.theme = LoadingOverlayTheme.dark,
  });

  LoadingOverlayState copyWith({
    bool? isLoading,
    String? message,
    Widget? customWidget,
    LoadingAnimationType? animationType,
    LoadingOverlayTheme? theme,
  }) {
    return LoadingOverlayState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      customWidget: customWidget ?? this.customWidget,
      animationType: animationType ?? this.animationType,
      theme: theme ?? this.theme,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadingOverlayState &&
        other.isLoading == isLoading &&
        other.message == message &&
        other.customWidget == customWidget &&
        other.animationType == animationType &&
        other.theme == theme;
  }

  @override
  int get hashCode {
    return Object.hash(
      isLoading,
      message,
      customWidget,
      animationType,
      theme,
    );
  }
}

/// LoadingOverlay 상태를 관리하는 StateNotifier
class LoadingOverlayNotifier extends StateNotifier<LoadingOverlayState> {
  LoadingOverlayNotifier() : super(const LoadingOverlayState());

  /// 로딩 표시
  void show({
    String? message,
    Widget? customWidget,
    LoadingAnimationType? animationType,
    LoadingOverlayTheme? theme,
  }) {
    state = state.copyWith(
      isLoading: true,
      message: message,
      customWidget: customWidget,
      animationType: animationType,
      theme: theme,
    );
  }

  /// 로딩 숨김
  void hide() {
    state = state.copyWith(
      isLoading: false,
      message: null,
      customWidget: null,
    );
  }

  /// 메시지 업데이트
  void updateMessage(String message) {
    if (state.isLoading) {
      state = state.copyWith(message: message);
    }
  }

  /// 테마 변경
  void updateTheme(LoadingOverlayTheme theme) {
    state = state.copyWith(theme: theme);
  }

  /// 애니메이션 타입 변경
  void updateAnimationType(LoadingAnimationType animationType) {
    state = state.copyWith(animationType: animationType);
  }
}

/// 애니메이션 타입 열거형
enum LoadingAnimationType {
  fade,
  scale,
  slideUp,
  slideDown,
  rotate,
}

/// LoadingOverlay 테마 열거형
enum LoadingOverlayTheme {
  dark,
  light,
  transparent,
  blur,
}

/// 글로벌 LoadingOverlay 관리자
class LoadingOverlayManager {
  static LoadingOverlayManager? _instance;

  LoadingOverlayManager._();

  static LoadingOverlayManager get instance {
    _instance ??= LoadingOverlayManager._();
    return _instance!;
  }

  /// 현재 액티브한 LoadingOverlay 상태들
  final Map<String, LoadingOverlayState> _overlays = {};

  /// 특정 키로 로딩 표시
  void showWithKey({
    required String key,
    String? message,
    Widget? customWidget,
    LoadingAnimationType animationType = LoadingAnimationType.fade,
    LoadingOverlayTheme theme = LoadingOverlayTheme.dark,
  }) {
    _overlays[key] = LoadingOverlayState(
      isLoading: true,
      message: message,
      customWidget: customWidget,
      animationType: animationType,
      theme: theme,
    );
  }

  /// 특정 키로 로딩 숨김
  void hideWithKey(String key) {
    _overlays.remove(key);
  }

  /// 모든 로딩 숨김
  void hideAll() {
    _overlays.clear();
  }

  /// 특정 키의 로딩 상태 확인
  bool isLoadingWithKey(String key) {
    return _overlays.containsKey(key) && _overlays[key]!.isLoading;
  }

  /// 전체 로딩 상태 확인 (하나라도 로딩 중이면 true)
  bool get isAnyLoading => _overlays.isNotEmpty;

  /// 현재 활성화된 오버레이 키 목록
  List<String> get activeKeys => _overlays.keys.toList();

  /// 특정 키의 상태 가져오기
  LoadingOverlayState? getStateWithKey(String key) {
    return _overlays[key];
  }
}

/// 테마별 색상 및 스타일 정의
class LoadingOverlayThemeData {
  final Color barrierColor;
  final Color progressColor;
  final Color textColor;
  final double? blurSigma;

  const LoadingOverlayThemeData({
    required this.barrierColor,
    required this.progressColor,
    required this.textColor,
    this.blurSigma,
  });

  static const Map<LoadingOverlayTheme, LoadingOverlayThemeData> themes = {
    LoadingOverlayTheme.dark: LoadingOverlayThemeData(
      barrierColor: Colors.black54,
      progressColor: Colors.white,
      textColor: Colors.white,
    ),
    LoadingOverlayTheme.light: LoadingOverlayThemeData(
      barrierColor: Colors.white70,
      progressColor: Colors.blue,
      textColor: Colors.black87,
    ),
    LoadingOverlayTheme.transparent: LoadingOverlayThemeData(
      barrierColor: Colors.transparent,
      progressColor: Colors.blue,
      textColor: Colors.black87,
    ),
    LoadingOverlayTheme.blur: LoadingOverlayThemeData(
      barrierColor: Colors.white30,
      progressColor: Colors.blue,
      textColor: Colors.black87,
      blurSigma: 3.0,
    ),
  };

  static LoadingOverlayThemeData getThemeData(LoadingOverlayTheme theme) {
    return themes[theme] ?? themes[LoadingOverlayTheme.dark]!;
  }
}

/// WidgetRef 확장을 통한 Riverpod 기반 로딩 관리
extension LoadingOverlayRiverpodRef on WidgetRef {
  /// Riverpod을 사용한 로딩 표시
  void showLoadingWithRiverpod({
    String? message,
    Widget? customWidget,
    LoadingAnimationType animationType = LoadingAnimationType.fade,
    LoadingOverlayTheme theme = LoadingOverlayTheme.dark,
  }) {
    read(loadingOverlayProvider.notifier).show(
      message: message,
      customWidget: customWidget,
      animationType: animationType,
      theme: theme,
    );
  }

  /// Riverpod을 사용한 로딩 숨김
  void hideLoadingWithRiverpod() {
    read(loadingOverlayProvider.notifier).hide();
  }

  /// 로딩 메시지 업데이트
  void updateLoadingMessage(String message) {
    read(loadingOverlayProvider.notifier).updateMessage(message);
  }

  /// 현재 로딩 상태 가져오기
  LoadingOverlayState getLoadingState() {
    return read(loadingOverlayProvider);
  }
}
