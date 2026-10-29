// Run on owned test devices with VERIFY_FOLD_TRANSITION=true. At each
// SERVICE_UI RESIZE marker switch between a cover and an unfolded window.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/vote/store_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_widget.dart';
import 'package:picnic_lib/presentation/widgets/navigator/bottom/menu_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/purchase_star_candy.dart';

import '../../../picnic_lib/test/helpers/foldable_test_app.dart';
import '../../../picnic_lib/test/helpers/mock_supabase.dart';
import '../../../picnic_lib/test/helpers/test_environment.dart';
import '../../test/helpers/current_service_test_app.dart';

Size window(WidgetTester tester) =>
    tester.view.physicalSize / tester.view.devicePixelRatio;
double keyboard(WidgetTester tester) =>
    tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
Future<void> frames(WidgetTester tester, [int count = 15]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }
}

Future<void> capture(WidgetTester tester, String label) async {
  debugPrint(
      'SERVICE_UI CAPTURE $label window=${window(tester)} keyboard=${keyboard(tester)}');
  await frames(tester, 35);
}

Future<void> fold(WidgetTester tester, String label) async {
  expect(const bool.fromEnvironment('VERIFY_FOLD_TRANSITION'), isTrue);
  final before = window(tester);
  debugPrint('SERVICE_UI RESIZE $label from=$before');
  final end = DateTime.now().add(const Duration(seconds: 90));
  while (window(tester) == before && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(window(tester).width > 600, before.width <= 600);
  await frames(tester);
  debugPrint('SERVICE_UI RESIZED $label ${window(tester)}');
}

Finder menu(int index) =>
    find.byWidgetPredicate((w) => w is MenuItem && w.index == index);

const _imageHosts = {'img.youtube.com', 'yt3.googleusercontent.com'};
final _observedImageHosts = <String>{};
final _unexpectedRequests = <String>[];

/// Network images are served by a local fixture server. No external image
/// service, analytics or backend receives these device-test requests.
class _LocalImages extends HttpOverrides {
  _LocalImages(this.uri);
  final Uri uri;
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _ImageClient(super.createHttpClient(context), uri);
}

class _ImageClient extends Fake implements HttpClient {
  _ImageClient(this.client, this.uri);
  final HttpClient client;
  final Uri uri;
  @override
  Future<HttpClientRequest> getUrl(Uri original) => openUrl('GET', original);
  @override
  Future<HttpClientRequest> openUrl(String method, Uri original) {
    _observedImageHosts.add(original.host);
    if (method != 'GET' || !_imageHosts.contains(original.host)) {
      _unexpectedRequests.add('$method ${original.host}');
      throw StateError('Unexpected external request: $method ${original.host}');
    }
    return client.getUrl(uri);
  }

  @override
  set autoUncompress(bool value) => client.autoUncompress = value;
  @override
  void close({bool force = false}) => client.close(force: force);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  HttpOverrides? previous;
  setUpAll(() async {
    initTestColors();
    final image = await rootBundle.load('assets/app_icon_128.png');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(image.buffer.asUint8List());
      await request.response.close();
    });
    previous = HttpOverrides.current;
    HttpOverrides.global =
        _LocalImages(Uri.parse('http://127.0.0.1:${server.port}/image.png'));
  });
  tearDownAll(() async {
    HttpOverrides.global = previous;
    await server.close(force: true);
    expect(_unexpectedRequests, isEmpty);
    expect(_observedImageHosts.difference(_imageHosts), isEmpty);
  });
  setUp(resetFoldableTestPlugins);
  tearDown(() {
    expectNoServiceMutation();
    tearDownMockSupabase();
  });

  for (final scale in [1.0, 2.6]) {
    testWidgets('current service native folds and vote input, text $scale',
        (tester) async {
      tester.testTextInput.unregister();
      addTearDown(tester.testTextInput.register);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
      await setupMockSupabaseWithAuth(serviceFixtures(),
          userId: 'test-user-id');
      await tester.pumpWidget(
          currentServiceTestApp(textScale: scale, deviceAssets: true));
      await frames(tester, 25);
      await tester.tap(menu(2));
      await frames(tester);
      final media = tester.element(find.byType(VideoListItem));
      await capture(tester, 'media-$scale-before');
      await fold(tester, 'media-$scale');
      expect(tester.element(find.byType(VideoListItem)), same(media));
      await capture(tester, 'media-$scale-after');

      await tester.tap(menu(3));
      await frames(tester);
      final store = tester.element(find.byType(StorePage));
      final price = find.byKey(const Key('purchase-price-cta'));
      await tester.scrollUntilVisible(price, 120,
          scrollable: find
              .descendant(
                  of: find.byType(PurchaseStarCandy),
                  matching: find.byType(Scrollable))
              .first);
      await tester.ensureVisible(price);
      await frames(tester);
      expect(price.hitTestable(), findsOneWidget);
      await capture(tester, 'store-$scale-before');
      await fold(tester, 'store-$scale');
      expect(tester.element(find.byType(StorePage)), same(store));
      await tester.ensureVisible(price);
      await frames(tester);
      expect(price.hitTestable(), findsOneWidget);
      await capture(tester, 'store-$scale-after');

      await tester.tap(find.byType(ProfileImageContainer).first);
      await frames(tester);
      expect(find.byType(MyPage), findsOneWidget);
      final profile = tester.element(find.byType(MyPage));
      await capture(tester, 'mypage-$scale-before');
      await fold(tester, 'mypage-$scale');
      expect(tester.element(find.byType(MyPage)), same(profile));
      expect(find.text(serviceNickname), findsOneWidget);
      await capture(tester, 'mypage-$scale-after');
      Navigator.of(tester.element(find.byType(MyPage))).pop();
      await frames(tester);

      await tester.tap(menu(1));
      await frames(tester);
      expect(find.byType(VoteInfoCard), findsWidgets);
      await capture(tester, 'vote-list-$scale');
      await tester.tap(find.byType(VoteInfoCard).first);
      await frames(tester);
      expect(find.byType(VoteDetailPage), findsOneWidget);
      await tester.scrollUntilVisible(find.byType(VoteItemWidget), 120,
          scrollable: find
              .descendant(
                  of: find.byType(VoteDetailPage),
                  matching: find.byType(Scrollable))
              .first);
      final row = find.byType(VoteItemWidget).first;
      await tester.ensureVisible(row);
      await frames(tester);
      await capture(tester, 'vote-detail-$scale');
      await tester.tap(row);
      await frames(tester);
      final dialog = find.byType(VotingDialog);
      expect(dialog, findsOneWidget);
      final input =
          find.descendant(of: dialog, matching: find.byType(TextField));
      final editable = tester.widget<EditableText>(
          find.descendant(of: input, matching: find.byType(EditableText)));
      await tester.ensureVisible(input);
      await tester.tap(input);
      final end = DateTime.now().add(const Duration(seconds: 30));
      while (keyboard(tester) == 0 && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      tester
          .state<EditableTextState>(
              find.descendant(of: input, matching: find.byType(EditableText)))
          .updateEditingValue(const TextEditingValue(
              text: '10', selection: TextSelection.collapsed(offset: 2)));
      await frames(tester);
      expect(keyboard(tester), greaterThan(0));
      expect(editable.controller.text, '10');
      expect(tester.getRect(input).bottom,
          lessThanOrEqualTo(window(tester).height - keyboard(tester) + 1));
      await capture(tester, 'vote-keyboard-$scale');
      for (var transition = 0; transition < 2; transition++) {
        final selection = editable.controller.selection;
        await fold(tester, 'vote-input-$scale-$transition');
        expect(editable.controller.text, '10');
        expect(editable.controller.selection, selection);
        await tester.ensureVisible(input);
        await frames(tester);
        await tester.tap(input);
        final keyboardDeadline =
            DateTime.now().add(const Duration(seconds: 15));
        while (keyboard(tester) == 0 &&
            DateTime.now().isBefore(keyboardDeadline)) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(keyboard(tester), greaterThan(0),
            reason: 'The vote field must reopen the OS keyboard after folding');
        tester
            .state<EditableTextState>(
                find.descendant(of: input, matching: find.byType(EditableText)))
            .updateEditingValue(const TextEditingValue(
                text: '101', selection: TextSelection.collapsed(offset: 3)));
        await frames(tester);
        expect(editable.controller.text, '101');
        expect(tester.getRect(input).bottom,
            lessThanOrEqualTo(window(tester).height - keyboard(tester) + 1));
        await capture(tester, 'vote-resumed-$scale-$transition');
        tester
            .state<EditableTextState>(
                find.descendant(of: input, matching: find.byType(EditableText)))
            .updateEditingValue(const TextEditingValue(
                text: '10', selection: TextSelection.collapsed(offset: 2)));
        await frames(tester);
      }
      // Short windows intentionally give the close strip's height to the
      // input while the keyboard is open. The barrier remains an exit.
      await tester.tapAt(const Offset(10, 10));
      await frames(tester);
      expect(dialog, findsNothing);
      expect(keyboard(tester), 0);
      expect(find.byType(VoteDetailPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester);
    });
  }
}
