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

/// 현재 **테스트 하나** 안에서 "이미 알려진 결함" 으로 통과시키기로 한 에러 메시지
/// 조각들. 테스트가 끝나면 비워진다([_ensureFilterInstalled] 의 addTearDown).
///
/// 채우는 방법은 하나뿐이다 — [drainExpectedImageErrors] /
/// [pumpWidgetAndIgnoreErrors] 의 `knownDefects` 인자. 즉 격리를 선언하는 순간
/// 반드시 drain 도 함께 일어나므로, "선언은 했는데 drain 을 안 불러서 조용히
/// 무효" 인 상태가 만들어질 수 없다. (이전의 파일 단위 `allowKnownDefects` 는
/// 그 함정이 있었고, 게다가 한 번 부르면 파일 전체 테스트에 걸렸다.)
final Set<String> _knownDefects = <String>{};

bool _isKnownDefect(Object error) {
  if (_knownDefects.isEmpty) return false;
  final text = error.toString();
  return _knownDefects.any(text.contains);
}

/// 필터가 통과시킨 에러의 [FlutterErrorDetails] 를 테스트 단위로 보관한다.
///
/// `tester.takeException()` 은 예외 객체만 돌려주고 "어느 위젯이 원인이었는지"
/// (`The relevant error-causing widget was ...`) 는 버린다. drain 이 진짜 결함을
/// 다시 던질 때 그 정보를 되살리려고 여기 남겨 둔다.
final List<FlutterErrorDetails> _seenDetails = <FlutterErrorDetails>[];

FlutterErrorDetails? _detailsFor(Object exception) {
  for (final details in _seenDetails) {
    if (identical(details.exception, exception)) return details;
  }
  return null;
}

/// 현재 테스트 본문에 필터가 설치돼 있는지 표시. `addTearDown` 으로 자동 복원한다.
bool _filterInstalled = false;

void _ensureFilterInstalled() {
  if (_filterInstalled) return;
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isExpectedImageDetails(details)) return;
    if (_isKnownDefect(details.exception)) return;
    _seenDetails.add(details);
    origOnError?.call(details);
  };
  _filterInstalled = true;
  addTearDown(() {
    FlutterError.onError = origOnError;
    _knownDefects.clear();
    _seenDetails.clear();
    _filterInstalled = false;
  });
}

/// drain 이 걸러내지 못한 예외를, 진단 정보를 최대한 붙여서 다시 던진다.
///
/// 그냥 `throw e` 하면 스택이 이 헬퍼를 가리키고 `FlutterErrorDetails` 가 통째로
/// 사라져서, 정작 이 PR 이 사려던 "어느 위젯이 터뜨렸는지" 를 잃는다.
Never _rethrowWithDiagnostics(Object e) {
  final details = _detailsFor(e);
  if (details != null) {
    // FlutterErrorDetails.toString() 은 에러 요약 + `The relevant error-causing
    // widget was` + informationCollector 출력까지 전부 렌더한다.
    Error.throwWithStackTrace(
      TestFailure(details.toString()),
      details.stack ?? StackTrace.current,
    );
  }
  if (e is Error) {
    final stack = e.stackTrace;
    if (stack != null) Error.throwWithStackTrace(e, stack);
  }
  // ignore: only_throw_errors
  throw e;
}

/// 이미 기록된 예외 중 **이미지/에셋 계열만** 비운다.
///
/// 그 외 예외는 다시 던져서 진짜 위젯 결함이 조용히 통과하지 않게 한다. 이때
/// [FlutterErrorDetails] 를 되살려 던지므로 "어느 위젯이 원인이었는지" 까지 그대로
/// 보고된다([_rethrowWithDiagnostics]).
///
/// 부수 효과로 남은 테스트 구간에 이미지 에러 필터를 설치한다 — 그래야 이후
/// 프레임의 이미지 에러가 `_pendingExceptionDetails` 를 차지해서 진짜 에러와
/// "Multiple exceptions" 로 뭉개지는 일을 막을 수 있다.
///
/// [knownDefects] 는 **아직 못 고친 프로덕션 결함 하나**를 에러 메시지로 지목해
/// 통과시키는 좁은 화이트리스트다. 여기 적힌 문자열을 포함하는 에러만 넘어가고,
/// 그 외 에러는 여전히 테스트를 깨뜨린다. 적용 범위는 **이 호출이 일어난 테스트
/// 하나** 뿐이고 테스트가 끝나면 사라진다 — 같은 파일의 다른 테스트는 그대로
/// 살아 있다. 반드시 "결함 위치 + 왜 아직 못 고쳤는지" 주석과 함께 쓴다.
void drainExpectedImageErrors(
  WidgetTester tester, {
  Iterable<String> knownDefects = const <String>[],
}) {
  _ensureFilterInstalled();
  _knownDefects.addAll(knownDefects);
  for (Object? e = tester.takeException(); e != null; e = tester.takeException()) {
    if (isExpectedImageOrAssetError(e)) continue;
    if (_isKnownDefect(e)) continue;
    _rethrowWithDiagnostics(e);
  }
}

/// `tester.pump()` 후 이미지/에셋 계열 예외만 무시한다.
Future<void> pumpAndIgnoreErrors(
  WidgetTester tester, [
  Duration? duration,
]) async {
  _ensureFilterInstalled();
  await tester.pump(duration);
  drainExpectedImageErrors(tester);
}

/// `tester.pumpWidget()` 후 이미지/에셋 계열 예외만 무시한다.
///
/// [knownDefects] 는 [drainExpectedImageErrors] 와 같은 의미다 — 이 테스트 하나에만
/// 적용되는 격리. 첫 프레임부터 터지는 결함은 여기서 지목해야 한다.
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
