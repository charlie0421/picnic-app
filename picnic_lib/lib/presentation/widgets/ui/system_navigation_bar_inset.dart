import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Android 시스템 내비게이션 바(3버튼·제스처) 영역을 앱 콘텐츠에서 제외한다.
///
/// Android 15+(targetSdk 35+)는 edge-to-edge 가 강제되고 시스템 내비 바가
/// 투명해져, 스크롤되는 콘텐츠가 3버튼 바 밑으로 그대로 지나간다(PICNIC-777).
/// 이 위젯은 바 높이만큼 [color] 로 칠한 띠를 아래에 예약하고, 하위 트리의
/// `MediaQuery.padding.bottom` / `viewPadding.bottom` 을 0 으로 만들어
/// 각 페이지가 따로 하단 여백을 더하지 않게 한다.
///
/// - 높이 기준은 `padding.bottom` 이다. 키보드가 바를 덮으면 Scaffold 가
///   `padding` 에서 그만큼 빼 주므로 띠도 함께 사라진다.
/// - Android 외 플랫폼과 웹에서는 아무것도 하지 않는다(iOS 홈 인디케이터는
///   기존처럼 콘텐츠가 그 아래로 지나가며 페이지 끝 여백으로 처리한다).
class SystemNavigationBarInset extends StatelessWidget {
  const SystemNavigationBarInset({
    super.key,
    required this.child,
    required this.color,
  });

  final Widget child;

  /// 예약된 띠에 칠할 색. 보통 화면 배경색.
  final Color color;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    if (!_isAndroid) return child;

    final data = MediaQuery.of(context);
    final inset = data.padding.bottom;
    if (inset <= 0) return child;

    return ColoredBox(
      color: color,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: MediaQuery(
          data: data.copyWith(
            padding: data.padding.copyWith(bottom: 0),
            viewPadding: data.viewPadding.copyWith(bottom: 0),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 모든 [PageRoute] 의 본문을 [SystemNavigationBarInset] 으로 감싸는
/// [PageTransitionsBuilder] 데코레이터. 전환 애니메이션은 [inner] 에 그대로
/// 위임한다.
///
/// 띠를 `MaterialApp.builder`(Navigator 바깥)가 아니라 각 라우트 안쪽에 두는
/// 이유: 모달 배리어는 Navigator 오버레이 안만 어둡게 하므로, 바깥에 두면
/// 다이얼로그가 떠도 하단 띠만 밝게 남는다(PICNIC-777).
class SystemNavigationBarInsetPageTransitionsBuilder
    extends PageTransitionsBuilder {
  const SystemNavigationBarInsetPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  // MaterialApp 은 App 이 재빌드될 때마다 새 ThemeData 를 받는다. 래퍼가
  // 값 동등성을 갖지 않으면 PageTransitionsTheme → ThemeData 가 매번 달라져
  // Theme 의존 위젯 전부에 didChangeDependencies 가 돌고, Portal 페이지들이
  // settingNavigation 을 다시 호출해 헤더·하단 내비가 뒤바뀐다.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemNavigationBarInsetPageTransitionsBuilder &&
          other.inner == inner;

  @override
  int get hashCode => Object.hash(runtimeType, inner);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return inner.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      SystemNavigationBarInset(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
    );
  }
}
