import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// 로딩 상태에 머무르는 override — 캐러셀의 loading 브랜치를 고정한다.
class PendingActiveFeaturedVotes extends AsyncActiveFeaturedVotes {
  @override
  Future<List<FeaturedVoteEntry>> build() =>
      Completer<List<FeaturedVoteEntry>>().future;
}

/// 실기기 논리 해상도(포인트). iOS 최소 지원(15.4)에 들어오는 최소 기기부터
/// 현행 최대 기기까지 커버한다.
const _devices = <String, Size>{
  'iPhone SE 2/3 (375x667)': Size(375, 667),
  'iPhone 13 mini (375x812)': Size(375, 812),
  'iPhone 14 (390x844)': Size(390, 844),
  'iPhone 16 (393x852)': Size(393, 852),
  'iPhone 17 Pro (402x874)': Size(402, 874),
  'iPhone 17 Pro Max (440x956)': Size(440, 956),
  'small Android (360x640)': Size(360, 640),
};

/// HomeFeaturedVoteCarousel._height — 캐러셀이 자식에게 물려주는 뷰포트 높이.
const double kCarouselViewportHeight = 372;

void main() {
  late void Function() restoreImages;

  setUp(() {
    initTestColors();
    restoreImages = suppressImageErrors();
  });

  tearDown(() => restoreImages());

  group('HomeFeaturedVoteCarousel loading placeholder', () {
    // 회귀 방지: 캐러셀은 로딩 플레이스홀더에 고정 높이(_height=372) 뷰포트를
    // tight 하게 물려준다. 자연 높이가 그보다 큰 스켈레톤을 넣으면
    // "A RenderFlex overflowed by N pixels on the bottom" 이 나면서 하단이
    // 잘린다(실제로 iPhone 17 Pro 에서 131px). 어떤 지원 기기/텍스트 배율에서도
    // 플레이스홀더가 뷰포트 안에 들어가야 한다.
    for (final entry in _devices.entries) {
      for (final textScale in <double>[1.0, 1.3]) {
        testWidgets('fits ${entry.key} at textScale $textScale', (
          tester,
        ) async {
          final size = entry.value;
          tester.view.devicePixelRatio = 3.0;
          tester.view.physicalSize = size * 3.0;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.reset);
          addTearDown(
            tester.platformDispatcher.clearTextScaleFactorTestValue,
          );

          await tester.pumpWidget(
            buildTestApp(
              const HomeFeaturedVoteCarousel(),
              extraOverrides: [
                asyncActiveFeaturedVotesProvider.overrideWith(
                  PendingActiveFeaturedVotes.new,
                ),
              ],
            ),
          );
          await tester.pump();

          expect(find.byType(HomeFeaturedVoteCarousel), findsOneWidget);
          // 축소해서 오버플로를 피하는 것도 회귀다 — 뷰포트를 그대로 채워야 한다.
          expect(
            tester.getSize(find.byType(HomeFeaturedVoteCarousel)).height,
            kCarouselViewportHeight,
          );
          expect(
            tester.takeException(),
            isNull,
            reason:
                'loading placeholder overflowed the carousel viewport on '
                '${entry.key} @ textScale $textScale',
          );
        });
      }
    }
  });
}
