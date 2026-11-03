import 'package:picnic_lib/enums.dart';

/// Which navigation call a deep link should end with.
enum DeepLinkPushTarget {
  /// `setCurrentPage` — pushes onto the shared vote stack.
  vote,

  /// `pushVotePageKeepScreen` — pushes without replacing the screen shell.
  voteKeepScreen,

  /// `setPicCurrentPage`.
  pic,

  /// `setNovelCurrentPage`.
  novel,

  /// `setCommunityCurrentPage`.
  community,
}

/// The portal routing decision for one deep link.
class DeepLinkNavigationPlan {
  const DeepLinkNavigationPlan({required this.push, this.switchToPortal});

  /// Portal to switch to before pushing, or `null` to stay where we are.
  ///
  /// A switch rebuilds the portal's page stack from its home page, so it is
  /// only ever worth doing when the link points somewhere else entirely.
  final PortalType? switchToPortal;

  final DeepLinkPushTarget push;
}

/// Decides how a deep link enters the navigation stack.
class DeepLinkNavigationPlanner {
  static DeepLinkNavigationPlan plan({
    required PortalType currentPortal,
    required PortalType fallbackPortal,
    required bool usePushKeepScreen,
  }) {
    switch (currentPortal) {
      case PortalType.community:
        return const DeepLinkNavigationPlan(
          push: DeepLinkPushTarget.community,
        );
      case PortalType.pic:
        return const DeepLinkNavigationPlan(push: DeepLinkPushTarget.pic);
      case PortalType.novel:
        return const DeepLinkNavigationPlan(push: DeepLinkPushTarget.novel);
      default:
        // Switching rebuilds the target portal from its home page, so we only
        // switch when we are not already there. Doing it unconditionally is
        // what sent vote-progress pushes to the start screen (PICNIC-2693).
        return DeepLinkNavigationPlan(
          switchToPortal:
              currentPortal == fallbackPortal ? null : fallbackPortal,
          push: usePushKeepScreen
              ? DeepLinkPushTarget.voteKeepScreen
              : DeepLinkPushTarget.vote,
        );
    }
  }
}
