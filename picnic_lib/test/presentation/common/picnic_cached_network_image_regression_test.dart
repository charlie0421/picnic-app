import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
