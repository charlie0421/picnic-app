import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';
import 'package:picnic_lib/presentation/common/common_banner.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_home_page.dart';
import 'package:picnic_lib/presentation/providers/banner_list_provider.dart';
import 'package:picnic_lib/presentation/providers/celeb_list_provider.dart';
import 'package:picnic_lib/presentation/providers/gallery_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/pixel_probe.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _CelebList extends AsyncCelebList {
  @override
  Future<List<CelebModel>?> build() async => [
        CelebModel.fromJson({
          'id': 1,
          'name_ko': '지민',
          'name_en': 'Jimin',
          'thumbnail': null,
        }),
      ];
}

class _MyCelebList extends AsyncMyCelebList {
  @override
  Future<List<CelebModel>?> build() async => const [];
}

class _CelebGalleryList extends AsyncCelebGalleryList {
  @override
  Future<List<GalleryModel>> build(int celebId) async => const [];
}

/// 배너가 영원히 로딩 상태에 머무르는 override.
class _PendingBannerList extends AsyncBannerList {
  @override
  Future<List<BannerModel>> build({required String location}) =>
      Completer<List<BannerModel>>().future;
}

/// 테스트가 직접 loading -> data 를 넘길 수 있는 override.
///
/// 위젯 트리를 새로 pump 하면 Riverpod 이 override 를 갈아끼우지 않아 상태가
/// 그대로 남는다. 한 트리 안에서 completer 를 완료시켜야 실제 전환이 재현된다.
class _ControllableBannerList extends AsyncBannerList {
  _ControllableBannerList(this.completer);

  final Completer<List<BannerModel>> completer;

  @override
  Future<List<BannerModel>> build({required String location}) =>
      completer.future;
}

BannerModel _banner(int id) => BannerModel.fromJson({
      'id': id,
      'title': {'ko': ''},
      'thumbnail': 'https://example.com/thumb$id.jpg',
      'image': {'ko': 'https://example.com/img$id.jpg'},
      'duration': 3000,
      'link': null,
    });

/// 실기기 논리 해상도(포인트).
const _devices = <String, Size>{
  'iPhone SE 2/3 (375x667)': Size(375, 667),
  'iPhone 13 mini (375x812)': Size(375, 812),
  'iPhone 14 (390x844)': Size(390, 844),
  'iPhone 16 (393x852)': Size(393, 852),
  'iPhone 17 Pro (402x874)': Size(402, 874),
  'iPhone 17 Pro Max (440x956)': Size(440, 956),
  'small Android (360x640)': Size(360, 640),
};

/// 픽셀 검사가 페이지를 정확히 잡도록 테스트가 직접 심는 캡처 경계.
const Key _boundary = ValueKey('pic_home_capture_boundary');

void _useDevice(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = size * 3.0;
  addTearDown(tester.view.reset);
}

/// 프로덕션과 동일한 ScreenUtil 기준으로 pic 홈을 띄운다.
///
/// 하네스 기본값([kLegacyTestDesignSize] = 375x812, splitScreenMode 없음)은 실제
/// 앱(393x892 + splitScreenMode)과 달라 `.w` / `.h` / `.r` 환산이 어긋난다. 이
/// 회귀는 스켈레톤의 자연 높이(= 전부 `.h` / `.w` 환산값의 합)에 직접 좌우되므로
/// 기준이 다르면 앱에 존재하지 않는 기하를 재게 된다. 실제로 하네스 기본값으로
/// 재면 iPhone 17 Pro 에서 프로덕션 302px 대신 324px 이 나온다.
///
/// 시간은 진행시키지 않는다. Shimmer 는 initState 에서 forward() 를 걸므로 이
/// 프레임은 애니메이션 0 지점 — 그라디언트 창이 자식 왼쪽 바깥에 있어 마스크가
/// 자식 전체를 baseColor 하나로 칠한다. 픽셀 단언이 위상에 흔들리지 않는다.
Future<void> _pumpPicHome(
  WidgetTester tester, {
  required List<dynamic> bannerOverride,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      const RepaintBoundary(key: _boundary, child: PicHomePage()),
      designSize: kAppDesignSize,
      splitScreenMode: kAppSplitScreenMode,
      extraOverrides: [
        asyncCelebListProvider.overrideWith(_CelebList.new),
        asyncMyCelebListProvider.overrideWith(_MyCelebList.new),
        asyncCelebGalleryListProvider.overrideWith(_CelebGalleryList.new),
        ...bannerOverride,
      ],
    ),
  );
  // 마이크로태스크로 끝나는 mock future 들이 풀리도록만 프레임을 돌린다.
  // Duration 을 주면 셔머 위상이 움직여 픽셀 단언이 흔들린다.
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpLoadingBanner(WidgetTester tester) => _pumpPicHome(
      tester,
      bannerOverride: [
        asyncBannerListProvider.overrideWith(_PendingBannerList.new),
      ],
    );

/// 남아 있는 예외를 전부 꺼내 돌려준다.
///
/// "예외를 그냥 비운다" 로 넘기면 이 테스트가 어떤 렌더 오류에도 실패하지 못하게
/// 되므로, 호출부가 목록을 직접 보고 판단한다.
List<Object> _drainExceptions(WidgetTester tester) {
  final errors = <Object>[];
  for (Object? error = tester.takeException();
      error != null;
      error = tester.takeException()) {
    errors.add(error);
  }
  return errors;
}

void main() {
  late void Function() restoreImages;

  setUp(() {
    initTestColors();
    restoreImages = suppressImageErrors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'celeb': [
        {'id': 1, 'name_ko': '지민', 'name_en': 'Jimin'},
      ],
      'celeb_bookmark_user': <dynamic>[],
      'pic_vote': <dynamic>[],
      'banner': <dynamic>[],
      'gallery': <dynamic>[],
    });
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
  });

  tearDown(() {
    PicnicCachedNetworkImage.disableTimeoutForTest = false;
    tearDownMockSupabase();
    restoreImages();
  });

  group('PicHomePage banner slot while the banner list loads', () {
    // 회귀 방지: 배너 자리에는 세로 리스트용 VoteCardSkeleton 이 들어가 있었다.
    // 자연 높이가 기기별 460~524px 로 고정인데 자리는 `화면폭 * 0.5`(360~440pt
    // 기기에서 180~220px)라, 로딩 중 매번 "A RenderFlex overflowed by N pixels
    // on the bottom" 이 나면서 아래가 잘렸다(iPhone 17 Pro 402x874 기준 302px,
    // 기기별 272~304px).
    //
    // 오버플로가 없다는 것만 재면 안 된다 — 플레이스홀더를 SizedBox.shrink 로
    // 지우거나 스크롤뷰로 감싸도 초록이 뜬다. 플레이스홀더가 배너 자리를 실제로
    // 채우는지를 함께 잰다.
    for (final entry in _devices.entries) {
      testWidgets('fills the banner slot without overflowing on ${entry.key}', (
        tester,
      ) async {
        _useDevice(tester, entry.value);
        await _pumpLoadingBanner(tester);

        final skeleton = find.byType(CommonBannerSkeleton);
        expect(
          skeleton,
          findsOneWidget,
          reason: '배너 로딩 자리에는 배너 모양 플레이스홀더가 있어야 한다',
        );

        final rect = tester.getRect(skeleton);
        expect(
          rect.width,
          closeTo(entry.value.width, 0.01),
          reason: '배너는 화면 폭을 꽉 채운다 — 플레이스홀더도 같아야 한다',
        );
        expect(
          rect.height,
          closeTo(entry.value.width / kPicHomeBannerAspectRatio, 0.01),
          reason: '플레이스홀더 높이는 배너 종횡비에서 나와야 한다 '
              '— 예전 `화면폭 * 0.5` 상자는 배너(폭 * 0.5625)보다 낮아, '
              '크기가 맞는 플레이스홀더를 넣었어도 자리가 틀렸다',
        );

        expect(
          _drainExceptions(tester).where(
            (e) => e.toString().contains('overflowed'),
          ),
          isEmpty,
          reason: '배너 플레이스홀더가 ${entry.key} 에서 자리를 넘쳤다',
        );
      });
    }

    // 자리만 맞고 아무것도 안 그리면(투명 스페이서) 사용자에겐 로딩 표시가 없는
    // 것과 같다. 실제로 칠해진 픽셀을 본다.
    testWidgets('paints a shimmering block, not an empty spacer', (
      tester,
    ) async {
      _useDevice(tester, const Size(402, 874));
      await _pumpLoadingBanner(tester);

      final probe = await capturePixels(tester, find.byKey(_boundary));
      final rect = tester.getRect(find.byType(CommonBannerSkeleton));

      expect(
        probe.at(rect.center),
        colorHex(AppColors.grey300),
        reason: '플레이스홀더 중앙이 셔머 베이스 색으로 칠해져 있어야 한다 '
            '— 흰색이면 빈 자리와 구분되지 않는다',
      );
      // 기준색은 반드시 셔머 베이스여야 한다. "배경색이 아닌 픽셀의 비율" 로
      // 재면 페이지 배경이 순백이 아닌 순간 무엇을 그리든 1.0 이 나와, 가운데
      // 2x2 점 하나만 찍어 놔도 초록이 뜬다(실제로 그렇게 통과했다).
      expect(
        probe.fractionNot(AppColors.grey300, rect.deflate(4)),
        lessThan(0.05),
        reason: '배너 자리는 이미지 한 장이 통째로 들어올 자리다 — 거의 전부가 '
            '셔머 베이스 색으로 칠해져 있어야 배너처럼 읽힌다',
      );
    });
  });

  group('PicHomePage banner slot loading -> loaded', () {
    // 오버플로가 사라져도 플레이스홀더가 배너와 다른 자리를 차지하면 데이터가
    // 도착하는 순간 아래 내용이 통째로 튄다. 수정 전 402x874 실측: 플레이스홀더
    // 상자 402x201 -> 배너 402x226.1, 즉 25.1px 점프(그리고 그 상자 안에서
    // VoteCardSkeleton 이 302px 넘쳤다).
    for (final entry in <String, Size>{
      'iPhone 17 Pro (402x874)': const Size(402, 874),
      'small Android (360x640)': const Size(360, 640),
    }.entries) {
      testWidgets('placeholder hands over to the banner in place on '
          '${entry.key}', (tester) async {
        _useDevice(tester, entry.value);
        final completer = Completer<List<BannerModel>>();
        await _pumpPicHome(
          tester,
          bannerOverride: [
            asyncBannerListProvider.overrideWith(
              () => _ControllableBannerList(completer),
            ),
          ],
        );

        final placeholderRect = tester.getRect(
          find.byType(CommonBannerSkeleton),
        );

        // 배너가 한 장이면 인디케이터가 없어 배너 영역 = AspectRatio 영역이다.
        // (여러 장이면 아래에 20px 짜리 인디케이터가 붙는다. 로딩 중에는 장수를
        // 알 수 없어 그 자리를 미리 잡아둘 수 없다 — 잡아두면 한 장짜리 배너가
        // 정반대 방향으로 튄다.)
        completer.complete([_banner(1)]);
        await tester.pump();
        await tester.pump();

        final banner = find.byType(CommonBanner);
        expect(banner, findsOneWidget);
        final bannerRect = tester.getRect(banner);

        expect(bannerRect.left, closeTo(placeholderRect.left, 0.01));
        expect(bannerRect.top, closeTo(placeholderRect.top, 0.01));
        expect(
          bannerRect.width,
          closeTo(placeholderRect.width, 0.01),
          reason: '데이터 도착 시 배너가 튀지 않으려면 두 사각형이 같아야 한다',
        );
        expect(
          bannerRect.height,
          closeTo(placeholderRect.height, 0.01),
          reason: '데이터 도착 시 아래 내용이 밀리지 않으려면 높이가 같아야 한다',
        );

        expect(
          _drainExceptions(tester).where(
            (e) => e.toString().contains('overflowed'),
          ),
          isEmpty,
        );
      });
    }
  });
}
