import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

/// PicnicCachedNetworkImage 의 lazy loading 회귀 테스트.
///
/// 배경: VisibilityDetector 의 Key 는 위젯 식별자일 뿐 아니라 visibility_detector
/// 패키지의 **전역 static map**(`_updates`, `_lastVisibility`) 의 키로도 쓰인다.
/// 예전에는 이 Key 를 `Key('lazy_image_$imageUrl')` — 즉 이미지 URL 로 만들었기
/// 때문에, 같은 이미지가 화면에 두 번 이상 나오면 키가 충돌해 `_updates[key]` 가
/// 서로를 덮어쓰고 한쪽 인스턴스는 가시성 콜백을 영영 받지 못했다(= 이미지 간헐
/// 누락). 인스턴스 고유 키로 바꾸면서, 전역 동시 로딩 기계장치(_currentLoadingCount
/// /_loadingQueue/_isLowBandwidthConnection)도 함께 제거했다 — 그 기계장치가
/// 정확해지면 리스트 화면에서 무관한 이미지를 굶기거나 해상도를 영구 강등시켰다.
void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    restore = suppressImageErrors();
    setupMockSupabase({});
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
  });

  /// 테스트에서 기대되는(무시해도 되는) 예외만 삼킨다. 헤드리스 환경에서 네트워크
  /// 이미지 디코드는 항상 실패하므로 그 계열만 걸러내고, 그 외 build/layout 예외는
  /// 다시 던져 진짜 위젯 결함이 조용히 통과하지 않도록 한다.
  void drainExpectedExceptions(WidgetTester tester) {
    for (var ex = tester.takeException(); ex != null; ex = tester.takeException()) {
      final text = ex.toString().toLowerCase();
      final isImageLoad = ex is NetworkImageLoadException ||
          text.contains('image') ||
          text.contains('http') ||
          text.contains('codec') ||
          text.contains('404') ||
          text.contains('failed host lookup') ||
          text.contains('connection');
      if (!isImageLoad) {
        // ignore: only_throw_errors
        throw ex;
      }
    }
  }

  /// 가시성 콜백(post-frame)과 lazy load 트리거가 모두 처리되도록 프레임을 흘린다.
  Future<void> settle(WidgetTester tester) async {
    drainExpectedExceptions(tester);
    for (final d in [
      Duration.zero,
      const Duration(milliseconds: 50),
      const Duration(milliseconds: 500),
    ]) {
      await tester.pump(d);
      drainExpectedExceptions(tester);
    }
  }

  /// 로딩이 시작된 인스턴스만 CachedNetworkImage 를 빌드한다.
  List<CachedNetworkImage> loadedImages(WidgetTester tester) => tester
      .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
      .toList();

  group('같은 imageUrl 이 화면에 동시에 여러 번 나올 때', () {
    testWidgets('두 인스턴스 모두 로딩을 시작해야 한다', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/duplicated.jpg',
                width: 80,
                height: 80,
              ),
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/duplicated.jpg',
                width: 80,
                height: 80,
              ),
            ],
          ),
        ),
      );
      await settle(tester);

      expect(
        loadedImages(tester),
        hasLength(2),
        reason: '같은 URL 을 쓰는 두 위젯 모두 이미지 로딩을 시작해야 한다 '
            '(키가 충돌하면 한쪽이 가시성 콜백을 못 받아 1개만 발견된다)',
      );
    });

    testWidgets('세 인스턴스가 동시에 있어도 모두 로딩을 시작해야 한다', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/triple.jpg',
                width: 60,
                height: 60,
              ),
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/triple.jpg',
                width: 60,
                height: 60,
              ),
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/triple.jpg',
                width: 60,
                height: 60,
              ),
            ],
          ),
        ),
      );
      await settle(tester);

      expect(loadedImages(tester), hasLength(3));
    });

    testWidgets('서로 다른 URL 이 섞여 있어도 전부 로딩을 시작해야 한다', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Column(
            children: [
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/shared.jpg',
                width: 50,
                height: 50,
              ),
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/unique.jpg',
                width: 50,
                height: 50,
              ),
              PicnicCachedNetworkImage(
                imageUrl: 'https://example.com/shared.jpg',
                width: 50,
                height: 50,
              ),
            ],
          ),
        ),
      );
      await settle(tester);

      expect(loadedImages(tester), hasLength(3));
    });
  });

  group('전역 동시 로딩 제한 제거 (슬롯 기아 없음)', () {
    testWidgets('9개 이상이 동시에 있어도 전부 로딩을 시작해야 한다', (tester) async {
      // 예전 큐 게이트는 8개까지만 로딩하고 나머지를 대기시켰다.
      // 특히 같은 인기 아티스트 이미지가 top3 에 반복되면 무관한 이미지가 굶었다.
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              for (int i = 0; i < 12; i++)
                PicnicCachedNetworkImage(
                  key: ValueKey('slot$i'),
                  // 앞 9개는 같은 인기 이미지, 뒤 3개는 서로 다른 이미지
                  imageUrl: i < 9
                      ? 'https://example.com/popular.jpg'
                      : 'https://example.com/other$i.jpg',
                  width: 30,
                  height: 30,
                ),
            ],
          ),
        ),
      );
      await settle(tester);

      expect(
        loadedImages(tester),
        hasLength(12),
        reason: '동시 로딩 제한을 제거했으므로 12개 전부 로딩을 시작해야 한다 '
            '(뒤쪽 서로 다른 이미지가 큐에 갇히면 안 된다)',
      );
    });

    testWidgets('많은 이미지가 동시에 로딩돼도 해상도가 강등되면 안 된다', (tester) async {
      // 예전엔 동시 로딩 수 > 6.4 이면 저대역폭으로 오판해 dpr 을 낮추고
      // (모바일 1.0/1.2) 그 결과가 _cachedUrls 에 영구 고정됐다.
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              for (int i = 0; i < 10; i++)
                PicnicCachedNetworkImage(
                  key: ValueKey('res$i'),
                  imageUrl: 'https://test-cdn.example.com/res$i.jpg',
                  width: 40,
                  height: 40,
                ),
            ],
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, hasLength(10));
      // CDN 은 dpr 파라미터를 무시하므로(2026-08-07 실측) 더 이상 URL 에 실리지
      // 않는다. 대신 dpr 기반 해상도 배율은 여전히 w 파라미터 산출에 쓰이므로,
      // 저대역폭 강등이 없다는 걸 w 값으로 검증한다. 테스트 뷰의
      // devicePixelRatio 는 3.0(mock) → 배수는 2.5 로 clamp 되어 정상 URL 은
      // w=100(40*2.5) 을 가진다. 저대역폭 강등이 켜지면 배수가 1.0/1.2 로
      // 떨어져 w 가 40~48 로 줄어든다.
      final wRe = RegExp(r'[?&]w=(\d+)');
      for (final img in images) {
        final m = wRe.firstMatch(img.imageUrl);
        expect(m, isNotNull, reason: 'w 파라미터가 있어야 한다: ${img.imageUrl}');
        final w = int.parse(m!.group(1)!);
        expect(w, greaterThan(80),
            reason: '동시 로딩 포화가 해상도 강등(배수<=2)을 유발하면 안 된다: ${img.imageUrl}');
      }
    });
  });

  group('CDN 이 무시하는 파라미터 제거 (f/fm 이중 다운로드 결함)', () {
    // 배경: cdn.picnic.fan(CloudFront + 커스텀 리사이저)의 캐시 키는
    // `_w{w}_h{h}_f{format}_q{q}` 뿐이며, 실측 결과 dpr/fm 은 응답에 아무
    // 영향을 주지 않는다(2026-08-07). 예전엔 f/fm 값이 (이제는 삭제된)
    // WebPSupportChecker.instance.supportInfo 의 비동기 초기화(Phase 2,
    // runApp 이후 완료) 에 좌우돼, 초기 프레임엔 f=jpg URL 을, 이후
    // 재생성된 위젯은 f=webp URL 을 만들었다 — 서버는 둘 다 같은 바이트를
    // 주지만 캐시 키가 곧 URL 이라 같은 이미지를 두 번 받아 두 번
    // 저장했다.
    //
    // imageUrl 은 CDN 호스트(test-cdn.example.com, test_environment.dart)로
    // 둔다 — CDN 이 아닌 절대 URL 은 원본 그대로 반환되어(아래 'CDN 변환은
    // 호스트로 스코프된다' 그룹 참고) 여기서 검증하려는 w/h/q 부여 자체가
    // 일어나지 않는다.
    testWidgets('URL 에 서버가 무시하는 dpr/fm/f/fl/auto/fit 파라미터가 없어야 한다',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://test-cdn.example.com/dead-params.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      final deadParamRe = RegExp(r'[?&](dpr|fm|f|fl|auto|fit)=');
      for (final img in images) {
        expect(deadParamRe.hasMatch(img.imageUrl), isFalse,
            reason: '서버가 무시하는 파라미터가 URL 에 남아 있으면 안 된다: ${img.imageUrl}');
      }
    });

    testWidgets('URL 에 서버가 실제로 쓰는 w/h/q 파라미터는 있어야 한다',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://test-cdn.example.com/live-params.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(img.imageUrl, matches(RegExp(r'[?&]w=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]h=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]q=\d+')));
      }
    });
  });

  group('CDN 변환은 호스트로 스코프된다 (외부 절대 URL 은 원본 그대로)', () {
    // 배경: 예전에는 절대 URL 이면 호스트가 무엇이든 uri.replace(queryParameters: ...)
    // 로 원래 쿼리를 통째로 버리고 w/h/q 로 갈아끼웠다. 스플래시(서버가 내려주는
    // scheduledSplashUrl), YouTube 썸네일(img.youtube.com, 하드코딩된 실제
    // 외부 호스트), FAQ/게시글에 박제된 외부 이미지 URL 등이 실제로 이 경로를
    // 탄다. 서명 URL(`?X-Amz-Signature=`, `?token=`)이 들어오면 서명이 깨지고,
    // 실제 외부 CDN(Imgix/Cloudinary 등)이면 fit 등 원래 파라미터가 사라져
    // 렌더링이 달라진다 — CDN 도입 이전부터 있던 선재 결함이다.
    testWidgets('CDN 절대 URL 에는 w/h/q 가 붙는다', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://test-cdn.example.com/picnic/artist/1.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          startsWith('https://test-cdn.example.com/picnic/artist/1.jpg?'),
        );
        expect(img.imageUrl, matches(RegExp(r'[?&]w=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]h=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]q=\d+')));
      }
    });

    testWidgets('CDN 상대 경로는 cdnUrl 로 조립되고 w/h/q 가 붙는다', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'artist/1.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          startsWith('https://test-cdn.example.com/artist/1.jpg?'),
        );
        expect(img.imageUrl, matches(RegExp(r'[?&]w=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]h=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]q=\d+')));
      }
    });

    testWidgets('외부 절대 URL(쿼리 있음)은 쿼리를 보존한 채 원본 그대로 반환된다',
        (tester) async {
      const externalUrl =
          'https://img.youtube.com/vi/abc123/mqdefault.jpg?token=signed-abc&expires=999';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: externalUrl,
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          externalUrl,
          reason: 'CDN 이 아닌 외부 호스트는 원래 쿼리를 보존한 채 아무 파라미터도 '
              '추가되지 않고 원본 그대로 반환돼야 한다: ${img.imageUrl}',
        );
      }
    });

    testWidgets('외부 절대 URL(쿼리 없음)도 원본 그대로 반환된다', (tester) async {
      const externalUrl = 'https://img.youtube.com/vi/abc123/mqdefault.jpg';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: externalUrl,
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          externalUrl,
          reason: '외부 호스트에는 w/h/q 를 포함해 아무 파라미터도 추가되면 안 된다: '
              '${img.imageUrl}',
        );
      }
    });
  });

  group('CDN 판정은 host 뿐 아니라 origin(scheme+host+port) 전체를 본다', () {
    // 배경: host 문자열만 비교하면 scheme 이나 port 가 다른 별개 origin 도 CDN
    // 으로 오판정된다. 실측된 리사이저 계약은 HTTPS 기본 포트 origin
    // (test_environment.dart 의 cdn_url = https://test-cdn.example.com,
    // 포트 미표기 = 443) 에 대해서만 확인됐다 — 그 범위를 벗어난 origin 에
    // w/h/q 를 적용하면 서명 URL(`?X-Amz-Signature=`, `?token=`)의 서명이
    // 깨지거나, 실은 CDN이 아닌 다른 서버가 우리 파라미터를 오해석할 수 있다.
    testWidgets('scheme 이 다르면(http vs CDN 의 https) CDN 으로 보지 않는다',
        (tester) async {
      const externalUrl = 'http://test-cdn.example.com/img.jpg?sig=abc';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: externalUrl,
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          externalUrl,
          reason: 'CDN 과 host 는 같아도 scheme(http)이 다르면 별개 origin 이다 — '
              '쿼리를 건드리면 안 된다: ${img.imageUrl}',
        );
      }
    });

    testWidgets('port 가 다르면(CDN 의 기본 443 이 아님) CDN 으로 보지 않는다',
        (tester) async {
      const externalUrl = 'https://test-cdn.example.com:8443/img.jpg?sig=abc';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: externalUrl,
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          externalUrl,
          reason: 'CDN 과 host/scheme 이 같아도 port(8443)가 다르면 별개 origin '
              '이다 — 쿼리를 건드리면 안 된다: ${img.imageUrl}',
        );
      }
    });

    testWidgets('CDN 의 기본 포트를 명시해도(:443) 여전히 CDN 으로 본다',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://test-cdn.example.com:443/artist/1.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(img.imageUrl, matches(RegExp(r'[?&]w=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]h=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]q=\d+')));
      }
    });

    testWidgets('CDN 호스트에 trailing dot(FQDN)이 붙어도 CDN 으로 본다',
        (tester) async {
      // 정책 결정: trailing dot(`cdn.picnic.fan.`)은 DNS 상 같은 호스트를
      // 가리키는 표기일 뿐이다. 문자열이 다르다는 이유로 CDN이 아니라고
      // 판정하면 얻는 안전 이득 없이 원본 대용량 이미지를 그대로 받게 되므로,
      // 정규화해서 CDN 으로 인정한다. (반대 방향 오탐 — CDN이 아닌 host가
      // trailing dot 때문에 CDN으로 오판정되는 경우는 없다. host 문자열 자체가
      // 여전히 같아야 하기 때문이다.)
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://test-cdn.example.com./artist/1.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(img.imageUrl, matches(RegExp(r'[?&]w=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]h=\d+')));
        expect(img.imageUrl, matches(RegExp(r'[?&]q=\d+')));
      }
    });
  });

  group('절대 URL 판별은 Uri 파싱 기반이다 (문자열 접두어 검사 아님)', () {
    // 배경: 예전에는 `key.startsWith('http://') || key.startsWith('https://')`
    // 문자열 검사였다. 그래서 대문자 스킴(`HTTPS://...`)과 scheme 없는
    // network-path reference(`//host/path`, protocol-relative URL)가 둘 다
    // 절대 URL 인데도 상대 경로로 오인돼 Environment.cdnUrl 뒤에 그대로
    // 이어붙어 URL 이 깨졌다. _classifyImageKey 가 Uri.tryParse 기반으로
    // hasScheme/hasAuthority 를 직접 보도록 고쳤다.
    testWidgets('대문자 스킴(HTTPS://)인 CDN URL 도 변환된다', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'HTTPS://test-cdn.example.com/artist/upper.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          startsWith('https://test-cdn.example.com/artist/upper.jpg?'),
          reason: '대문자 스킴이 상대 경로로 오인돼 cdnUrl 뒤에 그대로 '
              '이어붙으면 안 된다: ${img.imageUrl}',
        );
        expect(img.imageUrl, matches(RegExp(r'[?&]w=\d+')));
      }
    });

    testWidgets('대문자 스킴(HTTPS://)인 외부 URL 은 원본 대소문자 그대로 반환된다',
        (tester) async {
      const externalUrl = 'HTTPS://img.youtube.com/vi/upper-case/mqdefault.jpg';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: externalUrl,
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          externalUrl,
          reason: '외부 절대 URL 은 스킴 대소문자를 포함해 완전히 원본 그대로 '
              '반환돼야 한다: ${img.imageUrl}',
        );
      }
    });

    testWidgets('scheme 없는 //host/path(protocol-relative) 는 CDN 호스트면 https 로 '
        '승격돼 변환된다', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: '//test-cdn.example.com/artist/protocol-relative.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          startsWith(
            'https://test-cdn.example.com/artist/protocol-relative.jpg?',
          ),
          reason: '//host/path 를 상대 경로로 오인해 cdnUrl 뒤에 이어붙이면 '
              '전혀 다른(깨진) URL 이 된다: ${img.imageUrl}',
        );
        expect(img.imageUrl, matches(RegExp(r'[?&]w=\d+')));
      }
    });

    testWidgets(
        'scheme 없는 //host/path 는 외부 호스트면 https 로 승격만 되고 변환은 없다',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: '//img.youtube.com/vi/protocol-relative/mqdefault.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(
          img.imageUrl,
          'https://img.youtube.com/vi/protocol-relative/mqdefault.jpg',
          reason: '//host/path 는 https 로 승격되어야 fetch 가능한 URL이 된다 '
              '(avatar_url_resolver.dart 의 resolveAvatarImageUrl 과 같은 관례). '
              'CDN 이 아니므로 w/h/q 는 붙지 않아야 한다: ${img.imageUrl}',
        );
      }
    });

    testWidgets('빈 문자열/공백 imageUrl 은 예외 없이 상대 경로로 처리된다',
        (tester) async {
      // 빈 문자열/공백은 Uri.tryParse 로도 스킴+authority 를 못 갖추므로 상대
      // 경로 취급이다 — 예전(문자열 접두어 검사)에도 'http'로 시작하지
      // 않으므로 동일하게 상대 경로였다. 여기서는 Uri.tryParse 로 바꾼 뒤에도
      // 예외 없이 같은 동작을 유지하는지만 확인한다(크래시 방지 회귀 테스트).
      for (final blank in ['', '   ']) {
        await tester.pumpWidget(
          buildTestApp(
            PicnicCachedNetworkImage(
              key: ValueKey('blank-$blank'),
              imageUrl: blank,
              width: 100,
              height: 100,
            ),
          ),
        );
        await settle(tester);

        final images = loadedImages(tester);
        expect(images, isNotEmpty);
        for (final img in images) {
          expect(
            img.imageUrl,
            startsWith(Environment.cdnUrl),
            reason: '빈/공백 imageUrl 은 예외 없이 cdnUrl 기준 상대 경로로 '
                '조립돼야 한다: ${img.imageUrl}',
          );
        }
      }
    });
  });

  group('외부 URL 은 progressive 단계를 만들지 않는다 (중복 다운로드 방지)', () {
    // 배경: 변환이 적용되지 않는(=CDN 이 아닌) 절대 URL 은 _getTransformedUrl 이
    // resolutionMultiplier/quality 인자와 무관하게 항상 원본 문자열을 그대로
    // 돌려준다. 그런데 _getTransformedUrls 는 medium/high complexity 에서
    // 같은 imageUrl 을 인자만 바꿔 2~3번 호출해 progressive 단계를 만든다 —
    // 외부 URL 에서는 이 단계들이 전부 동일한 URL 이 된다. 캐시 키는
    // _cacheKeyFor 에서 index/isLowQuality 로 단계별로 다르게 만들어지므로,
    // 결과적으로 같은 바이트를 서로 다른 캐시 키로 2~3 회 받는다 — #149 에서
    // 고친 f=jpg/f=webp 이중 다운로드와 정확히 같은 종류의 결함이 CDN 밖에서
    // 재발한 것이다.
    //
    // 이 그룹은 "실제 다운로드 시도 횟수" 를 직접 세지 않고 "생성되는
    // CachedNetworkImage 위젯 수 / cacheKey 집합의 크기" 를 센다. 이것으로
    // 충분한 이유(간접이지만 근거 있는 증거):
    // flutter_cache_manager 의 CacheStore 는 URL 이 아니라 `key`(우리가 넘기는
    // cacheKey)로 캐시 항목을 식별한다. 서로 다른 cacheKey 는 각각 독립된
    // 캐시 조회를 만들고, 조회가 미스면 WebHelper.downloadFile 이 정확히 한 번
    // FileService.get() 을 호출해 다운로드를 시도한다. 즉 cacheKey 개수 == 캐시
    // 조회 횟수이고, 콜드 캐시에서는 캐시 조회 횟수 == 다운로드 시도 횟수다.
    //
    // 실제 다운로드 시도를 mock FileService 로 직접 세는 시도도 해봤다:
    // PicnicCachedNetworkImage 에 테스트 전용 CacheManager 주입 지점을 추가하고
    // (cacheManager: null → testCacheManagerOverride), FileService.get() 을
    // 가로채는 커스텀 CacheManager 를 주입했다. 그런데 이 위젯은 항상
    // memCacheWidth/Height 를 넘기므로 cached_network_image 내부가 "리사이즈
    // 하려면 cacheManager 가 ImageCacheManager 여야 한다" 고 단언해 일반
    // CacheManager 는 FileService.get() 에 닿기도 전에 죽었고, `CacheManager
    // with ImageCacheManager` 서브클래스로 바꾸자 이번엔 CacheManager 생성자가
    // 내부적으로 만드는 CacheStore 가 path_provider 플랫폼 채널을 기다리며
    // 테스트를 무한정 멈춰 세웠다(실제로 120초 넘게 응답 없이 걸려 백그라운드
    // 프로세스를 강제 종료해야 했다) — 이 하네스에는 path_provider 목이 없다.
    // path_provider 플랫폼 채널 목을 새로 도입하는 건 이 항목의 범위를 넘는
    // 별도 작업이라고 판단해, 되돌리고 위 cacheKey 기반 불변식을 그대로
    // 유지하기로 했다.
    testWidgets('medium complexity(300x300) 외부 URL 은 단일 요청만 만든다',
        (tester) async {
      const externalUrl =
          'https://img.youtube.com/vi/progressive-dup-1/mqdefault.jpg';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: externalUrl,
            width: 300,
            height: 300,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      expect(
        images.length,
        1,
        reason: '변환이 적용되지 않는 외부 URL 은 progressive 단계를 나눠도 URL '
            '이 전부 같아지므로 단일 요청으로 축약해야 한다. 지금은 서로 다른 '
            '캐시 키로 ${images.length}번 요청됨: '
            '${images.map((w) => w.cacheKey).toList()}',
      );
      expect(images.single.imageUrl, externalUrl);
    });

    testWidgets('width/height 미지정(splash 케이스) 외부 URL 도 단일 요청만 만든다',
        (tester) async {
      const externalUrl =
          'https://img.youtube.com/vi/progressive-dup-2/mqdefault.jpg';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(imageUrl: externalUrl),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      expect(
        images.length,
        1,
        reason: 'width/height 미지정이면 기본값(400x400)으로 medium '
            'complexity 가 되어 progressive 가 켜진다 — splash 케이스도 '
            '외부 URL 이면 단일 요청이어야 한다. 지금은 '
            '${images.length}번 요청됨: ${images.map((w) => w.cacheKey).toList()}',
      );
      expect(images.single.imageUrl, externalUrl);
    });

    testWidgets('같은 원본 URL 이 서로 다른 캐시 키로 중복 요청되면 안 된다',
        (tester) async {
      const externalUrl =
          'https://img.youtube.com/vi/progressive-dup-3/mqdefault.jpg';

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: externalUrl,
            width: 300,
            height: 300,
          ),
        ),
      );
      await settle(tester);

      final cacheKeys = loadedImages(tester).map((w) => w.cacheKey).toSet();
      expect(
        cacheKeys.length,
        1,
        reason: '같은 원본 바이트를 서로 다른 캐시 키로 여러 번 받으면 안 된다: '
            '$cacheKeys',
      );
    });
  });

  group('timeout Timer 는 dispose 시 취소된다 (Timer 누수 방지)', () {
    // 배경: _buildCachedNetworkImage 의 30초 타임아웃 Timer 는 원래
    // (이 브랜치 이전부터) 로컬 변수였다 — State 필드가 아니어서 dispose() 가
    // 절대 참조할 수 없었다. CDN 밖 medium/high 이미지가 progressive 단계 없이
    // 이 경로(단일 요청)를 타게 되면서 이 결함의 노출 빈도가 커졌다. 필드로
    // 옮기고 dispose/URL 변경 시 취소하도록 고쳤다 — 이 테스트는 그 취소가
    // 실제로 일어나는지 직접 검증한다.
    testWidgets(
      '비-CDN medium 이미지: 타임아웃 전에 위젯이 사라져도 pending Timer 가 남지 않는다',
      (tester) async {
        // 이 파일의 공통 setUp 은 모든 테스트에서 disableTimeoutForTest 를
        // 켜 둔다(pending-timer 오탐 방지). 이 테스트만은 반대로 실제 Timer 가
        // 걸리고 취소되는지를 검증해야 하므로 명시적으로 끈다.
        PicnicCachedNetworkImage.disableTimeoutForTest = false;

        await tester.pumpWidget(
          buildTestApp(
            const PicnicCachedNetworkImage(
              imageUrl: 'https://img.youtube.com/vi/timeout-leak/mqdefault.jpg',
              width: 300,
              height: 300,
            ),
          ),
        );
        await settle(tester);

        // effectiveTimeout(기본 30초) 이 지나기 전에 트리를 통째로 교체한다 —
        // 사용자가 30초 이내에 화면을 떠나는 상황과 동일하다.
        await tester.pumpWidget(buildTestApp(const SizedBox.shrink()));
        await tester.pump(const Duration(seconds: 1));
        drainExpectedExceptions(tester);

        // 여기서 테스트 본문이 끝나면 flutter_test 프레임워크 자신이
        // "A Timer is still pending" 불변식을 검사한다(TestWidgetsFlutterBinding
        // ._verifyInvariants). _imageTimeoutTimer 가 dispose 에서 취소되지
        // 않았다면 이 지점에서 프레임워크가 테스트를 실패시킨다 — 이 테스트
        // 자체가 pending-timer 검출기다. 30초를 실제로 기다리지 않고도(가짜
        // 시간이 아니라 진짜 Duration(seconds: 1) 만 흘렸다) 검증되는 이유는,
        // 검사 대상이 "타임아웃이 발화했는가" 가 아니라 "Timer 가 아직
        // 스케줄러에 등록돼 있는가" 이기 때문이다.
      },
    );
  });

  group('imageUrl 이 바뀔 때 (리스트 셀 재활용)', () {
    testWidgets('새 URL 로 렌더링해야 한다 (이전 URL 캐시를 버려야 함)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/first.jpg',
            width: 100,
            height: 100,
            lazyLoadingStrategy: LazyLoadingStrategy.none,
          ),
        ),
      );
      await settle(tester);

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/second.jpg',
            width: 100,
            height: 100,
            lazyLoadingStrategy: LazyLoadingStrategy.none,
          ),
        ),
      );
      await settle(tester);

      final images = loadedImages(tester);
      expect(images, isNotEmpty);
      for (final image in images) {
        expect(image.imageUrl, contains('second.jpg'),
            reason: 'URL 변경 후에는 이전 URL(_cachedUrls 캐시)이 아닌 새 URL 을 로드해야 한다');
      }
    });

    testWidgets('이미 보이는 상태에서 URL 이 바뀌어도 새 이미지를 로드해야 한다',
        (tester) async {
      // 인스턴스 고유 키에서는 Element 가 재사용되므로 VisibilityDetector 가
      // 가시성 "변화" 콜백을 다시 주지 않는다. didUpdateWidget 의 재트리거가
      // 없으면 새 이미지는 영영 로드되지 않는다(영구 shimmer).
      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/visible-first.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);

      final before = loadedImages(tester);
      expect(before, isNotEmpty, reason: '최초 로딩은 시작되어야 한다');

      await tester.pumpWidget(
        buildTestApp(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/visible-second.jpg',
            width: 100,
            height: 100,
          ),
        ),
      );
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedExceptions(tester);

      final after = loadedImages(tester);
      expect(after, isNotEmpty,
          reason: '이미 보이는 위젯의 URL 이 바뀌면 새 이미지 로딩이 시작되어야 한다 '
              '(비어 있으면 = 영구 shimmer 회귀)');
      for (final image in after) {
        expect(image.imageUrl, contains('visible-second.jpg'));
      }
    });
  });
}
