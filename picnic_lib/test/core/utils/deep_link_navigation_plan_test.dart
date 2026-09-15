import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/deep_link_navigation_plan.dart';
import 'package:picnic_lib/enums.dart';

/// The portal-routing decision behind [DeepLinkHandler], isolated so every
/// portal combination is covered without building a portal.
void main() {
  DeepLinkNavigationPlan planFor(
    PortalType current, {
    PortalType fallback = PortalType.vote,
    bool keepScreen = false,
  }) =>
      DeepLinkNavigationPlanner.plan(
        currentPortal: current,
        fallbackPortal: fallback,
        usePushKeepScreen: keepScreen,
      );

  group('already inside the target portal', () {
    test('a vote link from the vote portal never switches portal', () {
      // PICNIC-2693: switching rebuilt the stack from the vote home page,
      // which is the "start screen" users reported landing on.
      final plan = planFor(PortalType.vote);

      expect(plan.switchToPortal, isNull);
      expect(plan.push, DeepLinkPushTarget.vote);
    });

    test('a notice link from the vote portal keeps the current screen', () {
      final plan = planFor(PortalType.vote, keepScreen: true);

      expect(plan.switchToPortal, isNull);
      expect(plan.push, DeepLinkPushTarget.voteKeepScreen);
    });
  });

  group('portals that push onto their own stack', () {
    test('the community portal pushes without switching', () {
      final plan = planFor(PortalType.community);

      expect(plan.switchToPortal, isNull);
      expect(plan.push, DeepLinkPushTarget.community);
    });

    test('the pic portal pushes without switching', () {
      final plan = planFor(PortalType.pic);

      expect(plan.switchToPortal, isNull);
      expect(plan.push, DeepLinkPushTarget.pic);
    });

    test('the novel portal pushes without switching', () {
      final plan = planFor(PortalType.novel);

      expect(plan.switchToPortal, isNull);
      expect(plan.push, DeepLinkPushTarget.novel);
    });

    test('keepScreen does not override a portal-owned push target', () {
      final plan = planFor(PortalType.community, keepScreen: true);

      expect(plan.push, DeepLinkPushTarget.community);
    });
  });

  group('portals that must switch first', () {
    test('the goonghap portal switches to the fallback portal', () {
      final plan = planFor(PortalType.goongHap);

      expect(plan.switchToPortal, PortalType.vote);
      expect(plan.push, DeepLinkPushTarget.vote);
    });

    test('the mypage portal switches to the fallback portal', () {
      final plan = planFor(PortalType.mypage);

      expect(plan.switchToPortal, PortalType.vote);
      expect(plan.push, DeepLinkPushTarget.vote);
    });

    test('a switch still honours keepScreen', () {
      final plan = planFor(PortalType.goongHap, keepScreen: true);

      expect(plan.switchToPortal, PortalType.vote);
      expect(plan.push, DeepLinkPushTarget.voteKeepScreen);
    });
  });
}
