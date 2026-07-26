import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

typedef RestoreCallback = void Function();

/// 헤드리스 테스트에서 **불가피한** 이미지/에셋 로딩 실패인지 판별한다.
///
/// 테스트 환경에는 실제 네트워크도, 디코딩 가능한 에셋 번들도 없다. 그래서
/// 이미지 위젯은 반드시 실패한다 — 위젯 결함이 아니라 환경 제약이다.
/// **그 계열만** 걸러내고, 나머지(레이아웃 오버플로·빌드 예외·ParentData 오용
/// 등)는 절대 삼키지 않는다.
bool isExpectedImageOrAssetError(Object error) {
  // flutter 의 NetworkImage 전용 예외.
  if (error is NetworkImageLoadException) return true;

  // cached_network_image 의 HttpExceptionWithStatus.
  // 패키지 타입에 의존하지 않도록 이름으로 판별한다.
  if (error.runtimeType.toString() == 'HttpExceptionWithStatus') return true;

  final text = error.toString();

  // rootBundle 에 실제 에셋 바이트가 없어서 나는 실패.
  if (text.contains('Unable to load asset:')) return true;

  // 이미지 디코더가 빈/깨진 바이트를 받았을 때.
  const codecFailures = <String>[
    'Invalid image data',
    'Could not instantiate image codec',
    'Unable to decode image',
  ];
  return codecFailures.any(text.contains);
}

bool _isExpectedImageDetails(FlutterErrorDetails details) =>
    details.library == 'image resource service' ||
    isExpectedImageOrAssetError(details.exception);

/// 이미지/에셋 계열 FlutterError 만 버리고 나머지는 원래 핸들러로 넘기는 필터를
/// 설치한다. 반환된 콜백으로 복원한다.
///
/// **주의 — `setUp()` 에서 호출하면 아무 효과가 없다.**
/// flutter_test 바인딩은 `setUp()` 이 끝난 뒤 테스트 본문 직전에
/// `FlutterError.onError` 를 자기 것으로 덮어쓴다(binding.dart `runTest`).
/// 따라서 이 필터는 **테스트 본문 안에서** 설치해야 실제로 동작한다.
/// [pumpAndIgnoreErrors] / [pumpWidgetAndIgnoreErrors] / [drainExpectedImageErrors]
/// 는 본문 안에서 실행되므로 알아서 설치한다.
RestoreCallback suppressImageErrors() {
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isExpectedImageDetails(details)) return;
    origOnError?.call(details);
  };
  return () => FlutterError.onError = origOnError;
}

/// 현재 테스트에서 "이미 알려진 결함" 으로 통과시키기로 한 에러 메시지 조각들.
/// 테스트마다 초기화된다([_ensureFilterInstalled] 의 tearDown).
final Set<String> _knownDefects = <String>{};

bool _isKnownDefect(Object error) {
  if (_knownDefects.isEmpty) return false;
  final text = error.toString();
  return _knownDefects.any(text.contains);
}

/// 아직 못 고친 **프로덕션 결함 하나**를 이름으로 지목해, 그 group 안에서만
/// 통과시킨다. `main()` 이나 `group()` 본문에서 호출한다.
///
/// 여기 적은 문자열을 포함하는 에러만 넘어가고 나머지는 그대로 테스트를 깨뜨린다
/// — 즉 이 위젯에 **다른** 결함이 새로 생기면 여전히 빨간불이 된다.
/// 반드시 결함 위치와 왜 여기서 안 고치는지를 주석으로 남길 것.
void allowKnownDefects(List<String> defects) {
  setUp(() => _knownDefects.addAll(defects));
  tearDown(_knownDefects.clear);
}

/// 현재 테스트 본문에 필터가 설치돼 있는지 표시. `addTearDown` 으로 자동 복원한다.
bool _filterInstalled = false;

void _ensureFilterInstalled() {
  if (_filterInstalled) return;
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isExpectedImageDetails(details)) return;
    if (_isKnownDefect(details.exception)) return;
    origOnError?.call(details);
  };
  _filterInstalled = true;
  addTearDown(() {
    FlutterError.onError = origOnError;
    _knownDefects.clear();
    _filterInstalled = false;
  });
}

/// 이미 기록된 예외 중 **이미지/에셋 계열만** 비운다.
///
/// 그 외 예외는 다시 던져서 진짜 위젯 결함이 조용히 통과하지 않게 한다.
/// 원래 스택을 최대한 보존한다([Error] 는 자신의 `stackTrace` 를 들고 있다).
///
/// 부수 효과로 남은 테스트 구간에 이미지 에러 필터를 설치한다 — 그래야 이후
/// 프레임의 이미지 에러가 `_pendingExceptionDetails` 를 차지해서 진짜 에러와
/// "Multiple exceptions" 로 뭉개지는 일을 막을 수 있다.
/// [knownDefects] 는 **이미 알려진 프로덕션 결함 하나**를 이름으로 지목해 통과시키는
/// 좁은 화이트리스트다. 여기 적힌 문자열을 포함하는 에러만 넘어가고, 그 외 에러는
/// 여전히 테스트를 깨뜨린다. 반드시 "왜 아직 못 고쳤는지" 주석과 함께 쓴다.
/// 지정한 순간부터 그 테스트가 끝날 때까지 적용된다.
void drainExpectedImageErrors(
  WidgetTester tester, {
  Iterable<String> knownDefects = const <String>[],
}) {
  _ensureFilterInstalled();
  _knownDefects.addAll(knownDefects);
  for (Object? e = tester.takeException(); e != null; e = tester.takeException()) {
    if (isExpectedImageOrAssetError(e)) continue;
    if (_isKnownDefect(e)) continue;
    if (e is Error) {
      final stack = e.stackTrace;
      if (stack != null) Error.throwWithStackTrace(e, stack);
    }
    // ignore: only_throw_errors
    throw e;
  }
}

/// `tester.pump()` 후 이미지/에셋 계열 예외만 무시한다.
Future<void> pumpAndIgnoreErrors(
  WidgetTester tester, [
  Duration? duration,
  Iterable<String> knownDefects = const <String>[],
]) async {
  _ensureFilterInstalled();
  _knownDefects.addAll(knownDefects);
  await tester.pump(duration);
  drainExpectedImageErrors(tester);
}

/// `tester.pumpWidget()` 후 이미지/에셋 계열 예외만 무시한다.
Future<void> pumpWidgetAndIgnoreErrors(
  WidgetTester tester,
  Widget widget, {
  Iterable<String> knownDefects = const <String>[],
}) async {
  _ensureFilterInstalled();
  _knownDefects.addAll(knownDefects);
  await tester.pumpWidget(widget);
  drainExpectedImageErrors(tester);
}
