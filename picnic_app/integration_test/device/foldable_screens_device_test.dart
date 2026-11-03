// Local fixtures only. Run with --dart-define=VERIFY_FOLD_TRANSITION=true and
// change the owned simulator/emulator window at each FOLD_UI RESIZE marker.
// If RESUME_REQUEST reports keyboard=0 after an iOS display change, tap the
// visible input through the simulator UI to verify native editing can resume.
import 'dart:io';
import 'dart:math' as math;
import 'package:picnic_lib/presentation/common/navigator_key.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/common/comment/comment_list.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
import 'package:picnic_lib/presentation/pages/vote/home_page.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/providers/popup_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/popup_carousel.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_carousel.dart';

import '../../../picnic_lib/test/helpers/foldable_test_app.dart';
import '../../../picnic_lib/test/helpers/mock_supabase.dart';
import '../../../picnic_lib/test/helpers/test_environment.dart';

Size window(WidgetTester tester) =>
    tester.view.physicalSize / tester.view.devicePixelRatio;
double keyboard(WidgetTester tester) =>
    tester.view.viewInsets.bottom / tester.view.devicePixelRatio;

Future<void> frames(WidgetTester tester, [int count = 15]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(tester.takeException(), isNull);
}

Future<void> hold(WidgetTester tester, String label) async {
  debugPrint(
      'FOLD_UI FEATURES ${MediaQuery.of(navigatorKey.currentContext!).displayFeatures} padding=${MediaQuery.paddingOf(navigatorKey.currentContext!)}');
  debugPrint(
      'FOLD_UI CAPTURE $label window=${window(tester)} keyboard=${keyboard(tester)}');
  await frames(tester, 40);
}

Future<void> resize(WidgetTester tester, String label) async {
  expect(const bool.fromEnvironment('VERIFY_FOLD_TRANSITION'), isTrue,
      reason: 'Run this fold verification with VERIFY_FOLD_TRANSITION=true');
  final initial = window(tester);
  debugPrint('FOLD_UI RESIZE $label from=$initial');
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (window(tester) == initial && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(window(tester), isNot(initial),
      reason: 'External fold transition required');
  await frames(tester);
  expect(window(tester).width > 600, initial.width <= 600,
      reason: 'The native transition must cross the content width cap');
  debugPrint('FOLD_UI RESIZED $label $initial -> ${window(tester)}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer images;
  late String imageUrl;
  setUpAll(() async {
    initTestColors();
    // Serve a real bundled image on loopback. No image/backend credentials.
    final logo = await rootBundle.load('assets/app_icon_128.png');
    images = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    images.listen((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(logo.buffer.asUint8List());
      await request.response.close();
    });
    imageUrl = 'http://127.0.0.1:${images.port}/banner.png';
  });
  tearDownAll(() => images.close(force: true));
  setUp(resetFoldableTestPlugins);
  tearDown(tearDownMockSupabase);

  testWidgets('populated home preserves its carousel through native folds',
      (tester) async {
    setupMockSupabase(foldableScreenFixtures(imageUrl: imageUrl));
    const home = HomePage();
    await tester.pumpWidget(
        buildFoldableTestApp(home, deviceAssets: true, overrides: [
      asyncActiveFeaturedVotesProvider.overrideWith(FoldableFeaturedVotes.new)
    ]));
    await frames(tester, 30);
    await hold(tester, 'home-banner');
    await tester.ensureVisible(find.byType(HomeFeaturedVoteCarousel));
    await frames(tester);
    final carousel = tester.element(find.byType(HomeFeaturedVoteCarousel));
    await hold(tester, 'home-vote');
    for (var i = 0; i < 2; i++) {
      await resize(tester, 'home-$i');
      expect(tester.element(find.byType(HomeFeaturedVoteCarousel)),
          same(carousel));
      expect(find.byType(ShareSection), findsWidgets);
      await hold(tester, 'home-fold-$i');
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
  });

  testWidgets('post comment keeps draft above native keyboard during fold',
      (tester) async {
    tester.testTextInput.unregister();
    addTearDown(tester.testTextInput.register);
    await setupMockSupabaseWithAuth(foldableScreenFixtures(imageUrl: imageUrl),
        userId: 'test-user-id');
    await tester.pumpWidget(buildFoldableTestApp(
        const PostViewPage('foldable-post', syncNavigation: false),
        deviceAssets: true));
    await frames(tester, 30);
    await hold(tester, 'post');
    final open = find.text(AppLocalizationsKo().post_comment_write_label);
    await tester.ensureVisible(open);
    await tester.tap(open);
    await frames(tester);
    final input = find.byType(TextFormField);
    expect(input, findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.text = '접은 뒤에도 유지되는 댓글 초안';
    final element = tester.element(input);
    await tester.tap(input);
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (keyboard(tester) == 0 && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(keyboard(tester), greaterThan(0));
    await frames(tester);
    expect(tester.getRect(input).bottom,
        lessThanOrEqualTo(window(tester).height - keyboard(tester) + 1));
    await hold(tester, 'comment-keyboard');
    // Capture the synchronous unfocus caller without mocking platform input.
    // iOS can close the input connection when the active display changes.
    final unfocusStacks = <String>[];
    final inputUnfocusStacks = <String>[];
    String? pendingUnfocusStack;
    final originalDebugPrint = debugPrint;
    final originalFocusDebug = debugFocusChanges;
    debugFocusChanges = true;
    debugPrint = (message, {wrapWidth}) {
      if (message?.contains('Unfocused node:') ?? false) {
        final stack = StackTrace.current.toString();
        unfocusStacks.add(stack);
        pendingUnfocusStack = stack;
        originalDebugPrint('FOLD_UI UNFOCUS_STACK $stack');
      } else if (pendingUnfocusStack != null &&
          (message?.startsWith('    primary focus was ${editable.focusNode}') ??
              false)) {
        inputUnfocusStacks.add(pendingUnfocusStack!);
        pendingUnfocusStack = null;
        originalDebugPrint('FOLD_UI INPUT_NODE_UNFOCUSED verified');
      } else if (!(message?.startsWith('FOCUS:') ?? false) &&
          !(message?.startsWith('    ') ?? false)) {
        originalDebugPrint(message, wrapWidth: wrapWidth);
      }
    };
    void restoreFocusDebug() {
      debugFocusChanges = originalFocusDebug;
      debugPrint = originalDebugPrint;
    }

    addTearDown(restoreFocusDebug);
    await resize(tester, 'comment-keyboard');
    expect(tester.element(input), same(element));
    expect(editable.controller.text, '접은 뒤에도 유지되는 댓글 초안');
    final sheet = tester.getRect(find.byType(CommentList));
    debugPrint('FOLD_UI SHEET $sheet');
    expect(
        sheet.top,
        greaterThanOrEqualTo(
            MediaQuery.paddingOf(navigatorKey.currentContext!).top +
                kToolbarHeight -
                1));
    final safe = MediaQuery.paddingOf(navigatorKey.currentContext!);
    debugPrint('FOLD_UI SAFE $safe');
    final safeWidth = window(tester).width - safe.horizontal;
    expect(sheet.width, closeTo(math.min(safeWidth, 600), 1));
    expect(sheet.center.dx, closeTo(safe.left + safeWidth / 2, 1));
    expect(tester.getRect(input).bottom,
        lessThanOrEqualTo(window(tester).height - keyboard(tester) + 1));
    await hold(tester, 'comment-fold');
    debugPrint('FOLD_UI FOCUS after-fold=${editable.focusNode.hasFocus}');
    restoreFocusDebug();
    if (Platform.isIOS && !editable.focusNode.hasFocus) {
      expect(unfocusStacks, isNotEmpty);
      expect(inputUnfocusStacks, isNotEmpty,
          reason: 'The closed connection must belong to the draft input');
      expect(
          unfocusStacks.every((stack) =>
              stack.contains('EditableTextState.connectionClosed') &&
              stack.contains('TextInput._handleTextInputInvocation') &&
              !stack.contains('_dismissKeyboard')),
          isTrue,
          reason: 'Only an observed iOS platform connection close is allowed');
      debugPrint('FOLD_UI PLATFORM_INPUT_CLOSED verified');
    } else {
      expect(editable.focusNode.hasFocus, isTrue,
          reason: 'fold must not clear the draft focus');
    }
    // Some simulator poses dismiss the native keyboard. Verify that editing
    // can resume in the new window, with the same controller and draft.
    if (keyboard(tester) == 0 || !editable.focusNode.hasFocus) {
      expect(input.hitTestable(), findsOneWidget);
      await tester.tap(input);
      await frames(tester);
      debugPrint('FOLD_UI RESUME_REQUEST focus=${editable.focusNode.hasFocus} '
          'input=${tester.getRect(input)} keyboard=${keyboard(tester)}');
      final reopenDeadline = DateTime.now().add(const Duration(seconds: 30));
      while (keyboard(tester) == 0 && DateTime.now().isBefore(reopenDeadline)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
    await frames(tester);
    expect(keyboard(tester), greaterThan(0));
    expect(editable.focusNode.hasFocus, isTrue);
    expect(editable.controller.text, '접은 뒤에도 유지되는 댓글 초안');
    expect(tester.getRect(input).bottom,
        lessThanOrEqualTo(window(tester).height - keyboard(tester) + 1));
    await hold(tester, 'comment-resume');
    FocusManager.instance.primaryFocus?.unfocus();
    await frames(tester, 20);
    expect(keyboard(tester), 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
  });

  testWidgets('large text popup can scroll to close before and after fold',
      (tester) async {
    setupMockSupabase(foldableScreenFixtures(imageUrl: imageUrl));
    await tester.pumpWidget(buildFoldableTestApp(const PopupCarousel(),
        textScale: 2.6,
        deviceAssets: true,
        overrides: [
          popupProvider.overrideWith((ref) async => const [
                Popup(
                    id: 9029,
                    title: {'ko': '화면이 바뀌어도 읽을 수 있는 안내'},
                    content: {'ko': '접거나 펼친 뒤에도 안내와 닫기 버튼을 확인할 수 있어야 합니다.'}),
              ])
        ]));
    await frames(tester);
    final close = find.text(AppLocalizationsKo().label_popup_close);
    await tester.ensureVisible(close);
    await frames(tester);
    expect(close.hitTestable(), findsOneWidget);
    await hold(tester, 'popup-large');
    await resize(tester, 'popup');
    await tester.ensureVisible(close);
    await frames(tester);
    expect(close.hitTestable(), findsOneWidget);
    await hold(tester, 'popup-fold');
    await tester.tap(close);
    await frames(tester);
    expect(close, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
  });
}
