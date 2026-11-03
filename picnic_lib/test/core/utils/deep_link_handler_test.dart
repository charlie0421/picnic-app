import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/deep_link_handler.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';

import '../../helpers/test_environment.dart';

/// Stand-in for whatever the user was already looking at. Its survival proves
/// the deep link did not reset the portal stack back to the start screen.
class _OpenPage extends StatelessWidget {
  const _OpenPage();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// PICNIC-2693: tapping a vote-progress push must land on the vote detail
/// page, not on the start screen.
void main() {
  late WidgetRef ref;

  setUpAll(initTestColors);

  Future<void> mountRef(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, widgetRef, _) {
            ref = widgetRef;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// Distinct per test so the 2s duplicate-deep-link guard never swallows one.
  var uniqueId = 1000;
  String voteDetailUrl() =>
      'https://applink.picnic.fan/vote/detail/${uniqueId++}';

  testWidgets('a vote detail deep link lands on the detail page immediately',
      (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());

    await DeepLinkHandler.handleDeepLink(ref, voteDetailUrl());

    final stack = ref.read(navigationInfoProvider).voteNavigationStack!;
    expect(
      stack.peek(),
      isA<VoteDetailPage>(),
      reason: 'the detail page must be on top before the next frame',
    );
  });

  testWidgets('a vote detail deep link keeps the pages already open',
      (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());

    await DeepLinkHandler.handleDeepLink(ref, voteDetailUrl());

    final stack = ref.read(navigationInfoProvider).voteNavigationStack!;
    expect(
      stack.items.whereType<_OpenPage>(),
      isNotEmpty,
      reason: 'switching to the start screen would discard the open page',
    );
  });

  testWidgets('an achieve deep link resolves to the achieve detail page',
      (tester) async {
    await mountRef(tester);

    await DeepLinkHandler.handleDeepLink(
      ref,
      '${voteDetailUrl()}?type=achieve',
    );

    final stack = ref.read(navigationInfoProvider).voteNavigationStack!;
    expect(stack.peek(), isA<VoteDetailAchievePage>());
  });

  testWidgets('a notice deep link still lands on the notice detail page',
      (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());

    await DeepLinkHandler.handleDeepLink(
      ref,
      'https://applink.picnic.fan/notice/${uniqueId++}',
    );

    final navigation = ref.read(navigationInfoProvider);
    expect(navigation.voteNavigationStack!.peek(), isA<NoticeDetailPage>());
    expect(
      navigation.voteNavigationStack!.items.whereType<_OpenPage>(),
      isNotEmpty,
    );
  });

  testWidgets('a vote deep link from another portal switches back to vote',
      (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setPortal(PortalType.goongHap);

    await DeepLinkHandler.handleDeepLink(ref, voteDetailUrl());

    final navigation = ref.read(navigationInfoProvider);
    expect(navigation.portalType, PortalType.vote);
    expect(
      navigation.voteNavigationStack!.peek(),
      isA<VoteDetailPage>(),
      reason: 'the user must not be parked on the vote home page',
    );
  });

  testWidgets('a malformed vote detail deep link changes nothing',
      (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());
    final lengthBefore =
        ref.read(navigationInfoProvider).voteNavigationStack!.length;

    await DeepLinkHandler.handleDeepLink(
      ref,
      'https://applink.picnic.fan/vote/detail',
    );

    final stack = ref.read(navigationInfoProvider).voteNavigationStack!;
    expect(stack.length, lengthBefore);
    expect(stack.peek(), isA<_OpenPage>());
  });

  testWidgets('a negative voteId is rejected', (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());
    final lengthBefore =
        ref.read(navigationInfoProvider).voteNavigationStack!.length;

    await DeepLinkHandler.handleDeepLink(
      ref,
      'https://applink.picnic.fan/vote/detail/-1',
    );

    final stack = ref.read(navigationInfoProvider).voteNavigationStack!;
    expect(stack.length, lengthBefore);
    expect(stack.peek(), isA<_OpenPage>());
  });

  testWidgets('a zero voteId is rejected', (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());

    await DeepLinkHandler.handleDeepLink(
      ref,
      'https://applink.picnic.fan/vote/detail/0',
    );

    expect(
      ref.read(navigationInfoProvider).voteNavigationStack!.peek(),
      isA<_OpenPage>(),
    );
  });

  testWidgets('a negative achieve voteId is rejected', (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());

    await DeepLinkHandler.handleDeepLink(
      ref,
      'https://applink.picnic.fan/vote/detail/-7?type=achieve',
    );

    expect(
      ref.read(navigationInfoProvider).voteNavigationStack!.peek(),
      isA<_OpenPage>(),
    );
  });

  testWidgets('a non-numeric voteId is rejected', (tester) async {
    await mountRef(tester);
    final notifier = ref.read(navigationInfoProvider.notifier);
    notifier.setCurrentPage(const _OpenPage());

    await DeepLinkHandler.handleDeepLink(
      ref,
      'https://applink.picnic.fan/vote/detail/abc',
    );

    expect(
      ref.read(navigationInfoProvider).voteNavigationStack!.peek(),
      isA<_OpenPage>(),
    );
  });
}
