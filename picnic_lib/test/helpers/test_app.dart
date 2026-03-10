import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 모든 위젯/프로바이더 테스트에서 사용할 공통 래퍼
///
/// 사용법:
///   await tester.pumpWidget(
///     TestApp(
///       overrides: [myProvider.overrideWithValue(mockValue)],
///       child: MyWidget(),
///     ),
///   );
class TestApp extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;
  final Locale locale;

  const TestApp({
    super.key,
    required this.child,
    this.overrides = const [],
    this.locale = const Locale('ko'),
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        home: Scaffold(body: child),
      ),
    );
  }
}

/// Consumer 빌더를 통해 WidgetRef를 캡처하는 테스트 래퍼
///
/// 사용법:
///   late WidgetRef testRef;
///   await tester.pumpWidget(
///     TestApp(
///       child: RefCaptureWidget(
///         onRefCaptured: (ref) => testRef = ref,
///         child: MyWidget(),
///       ),
///     ),
///   );
class RefCaptureWidget extends ConsumerWidget {
  final Widget child;
  final void Function(WidgetRef ref) onRefCaptured;

  const RefCaptureWidget({
    super.key,
    required this.child,
    required this.onRefCaptured,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onRefCaptured(ref);
    return child;
  }
}
