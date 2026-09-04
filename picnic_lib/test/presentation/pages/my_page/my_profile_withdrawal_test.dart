import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_providers.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// 성공 경로에서 my_profile 이 부르는 provider 호출을 **순서 그대로** 기록한다.
class _RecordingNavigationInfo extends MockNavigationInfo {
  _RecordingNavigationInfo(super.initial, this.calls);

  final List<String> calls;

  @override
  void setBottomNavigationIndex(int index) {
    calls.add('setBottomNavigationIndex($index)');
    super.setBottomNavigationIndex(index);
  }

  @override
  void setResetStackMyPage() {
    calls.add('setResetStackMyPage');
    super.setResetStackMyPage();
  }
}

class _RecordingUserInfo extends MockUserInfo {
  _RecordingUserInfo(super.profile, this.calls);

  final List<String> calls;

  @override
  Future<void> logout() async {
    calls.add('logout');
    // 진짜 logout 은 AuthService().signOut() 과 setBottomNavigationIndex(0) 을
    // 함께 부른다. 여기서 재려는 것은 **my_profile 이 부르는 순서**라서 그
    // 내부 호출까지 로그에 섞이면 단언이 UserInfo 구현 세부에 묶인다.
    // 로그아웃 후 상태만 그대로 흉내 낸다.
    state = const AsyncValue.data(null);
  }
}

/// PICNIC-2520 회귀 테스트.
///
/// delete-user Edge Function 이 500 을 돌려주면 예전에는 예외가
/// `onPressed: () => _deleteAccount()` 안에서 사라져 화면에 아무 변화가 없었다.
/// 사용자는 "버튼이 비활성" 이라고 인지했고, 응답을 기다리는 동안 계속 다시
/// 탭할 수 있었다. 두 가지를 못 박는다 — 실패 피드백과 중복 탭 차단.
///
/// 뒤이은 리뷰에서 드러난 두 번째 결함도 함께 고정한다. 버튼만 잠그면 요청이
/// 떠 있는 동안 scrim·드래그·시스템 뒤로가기로 시트를 닫을 수 있고, 그러면
/// 늦게 도착한 성공 응답의 pop 이 **시트가 아니라 그 아래 라우트**를 닫는다.
void main() {
  final l10n = AppLocalizationsKo();
  late void Function() restore;

  setUp(() async {
    initTestColors();
    // _deleteAccount 는 currentUser / currentSession 이 있어야 실제 요청까지
    // 간다. 없으면 조용히 early-return 이라 테스트가 무의미해진다.
    await setupMockSupabaseWithAuth(
      {'user_profiles': <dynamic>[]},
      userId: 'test-user-id',
    );
    restore = suppressImageErrors();
  });

  tearDown(() {
    testWithdrawalHttpClient = null;
    restore();
    tearDownMockSupabase();
  });

  /// 마이프로필 → "회원탈퇴" 메뉴 → 탈퇴 확인 모달까지 연다.
  ///
  /// [recordInto] 를 주면 navigation/user provider 를 호출 기록용 notifier 로
  /// 갈아 끼운다. [buildTestApp] 이 이미 같은 provider 를 override 하고 있어
  /// `extraOverrides` 로는 넣을 수 없고(riverpod 이 "Tried to override a
  /// provider twice within the same container" 로 막는다), 중첩 ProviderScope
  /// 는 새 컨테이너라 재정의가 허용된다. `_deleteAccount` 가
  /// `ProviderScope.containerOf(context)` 로 잡는 컨테이너도 이 중첩 스코프다.
  Future<void> openWithdrawalSheet(
    WidgetTester tester, {
    List<String>? recordInto,
  }) async {
    // 기본 테스트 표면 800x600 은 세로가 짧다. 바텀시트가 받는 높이는 화면의
    // 9/16 뿐이라 모달 Column 이 그대로 오버플로해서, 정작 재려는 것보다
    // 레이아웃 예외가 먼저 터진다. 그래서 **세로만** 늘린다 — 폭을 줄이면
    // 이번엔 프로필 페이지의 닉네임 Row 가 가로로 넘친다. 둘 다 프로덕션
    // 기하(393x892)가 아니라 하네스 기하 탓이다.
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(
      recordInto == null
          ? const MyProfilePage()
          : ProviderScope(
              overrides: [
                navigationInfoProvider.overrideWith(
                  () => _RecordingNavigationInfo(
                      MockData.navigation(), recordInto),
                ),
                userInfoProvider.overrideWith(
                  () => _RecordingUserInfo(MockData.userProfile(), recordInto),
                ),
              ],
              child: const MyProfilePage(),
            ),
    ));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));

    final withdrawMenu = find.text(l10n.label_mypage_withdrawal);
    await tester.scrollUntilVisible(
      withdrawMenu,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpAndIgnoreErrors(tester);

    await tester.tap(withdrawMenu);
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));

    expect(find.text(l10n.dialog_withdraw_title), findsOneWidget);
  }

  /// 모달 안 첫 번째 버튼 = 확인("탈퇴하기"). 진행 중에는 라벨이 로딩
  /// 인디케이터로 바뀌므로 텍스트가 아니라 위치로 찾는다.
  Finder confirmButton() => find
      .descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(MaterialButton),
      )
      .first;

  Finder sheetProgressIndicator() => find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(CircularProgressIndicator),
      );

  /// 안드로이드 시스템 뒤로가기.
  Future<void> pressSystemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));
  }

  group('MyProfilePage 회원탈퇴', () {
    testWidgets('delete-user 가 실패하면 오류 다이얼로그를 띄운다',
        (WidgetTester tester) async {
      // 핸들러 안에서 expect 를 부르면 실패가 요청 에러로 둔갑해 그대로
      // 오류 다이얼로그 경로를 타 버린다. URL 은 기록만 하고 밖에서 단언한다.
      Uri? requestedUrl;
      testWithdrawalHttpClient = MockClient((request) async {
        requestedUrl = request.url;
        return http.Response('{"error":"Account deletion failed"}', 500);
      });

      await openWithdrawalSheet(tester);

      await tester.tap(find.text(l10n.dialog_withdraw_button_ok));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(requestedUrl?.path, '/functions/v1/delete-user',
          reason: 'Edge Function 호출까지 도달해야 한다');
      expect(find.text(l10n.withdrawal_failed), findsOneWidget);
    });

    testWidgets('요청이 끝날 때까지 확인 버튼을 잠그고 로딩을 보여준다',
        (WidgetTester tester) async {
      final gate = Completer<http.Response>();
      var callCount = 0;
      testWithdrawalHttpClient = MockClient((request) {
        callCount++;
        return gate.future;
      });

      await openWithdrawalSheet(tester);
      expect(tester.widget<MaterialButton>(confirmButton()).onPressed,
          isNotNull,
          reason: '평상시에는 확인 버튼이 활성이어야 한다');
      expect(sheetProgressIndicator(), findsNothing);

      await tester.tap(find.text(l10n.dialog_withdraw_button_ok));
      await pumpAndIgnoreErrors(tester);

      expect(tester.widget<MaterialButton>(confirmButton()).onPressed, isNull,
          reason: '요청 중에는 중복 탭이 막혀야 한다');
      expect(sheetProgressIndicator(), findsOneWidget);

      // 응답 전에 다시 눌러도 두 번째 요청이 나가지 않는다.
      await tester.tap(confirmButton(), warnIfMissed: false);
      await pumpAndIgnoreErrors(tester);
      expect(callCount, 1);

      gate.complete(http.Response('{"error":"Account deletion failed"}', 500));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.text(l10n.withdrawal_failed), findsOneWidget);
      expect(sheetProgressIndicator(), findsNothing);
      expect(tester.widget<MaterialButton>(confirmButton()).onPressed,
          isNotNull,
          reason: '실패 후에는 버튼 상태가 복구돼야 한다');
    });

    testWidgets('성공하면 시트만 닫고 그 아래 라우트는 남긴다',
        (WidgetTester tester) async {
      final calls = <String>[];
      testWithdrawalHttpClient = MockClient(
          (request) async => http.Response('{"success":true}', 200));

      await openWithdrawalSheet(tester, recordInto: calls);

      await tester.tap(find.text(l10n.dialog_withdraw_button_ok));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(BottomSheet), findsNothing, reason: '시트는 닫혀야 한다');
      expect(find.byType(MyProfilePage), findsOneWidget,
          reason: '시트 아래 라우트는 그대로 살아 있어야 한다');
      expect(calls,
          ['setBottomNavigationIndex(0)', 'logout', 'setResetStackMyPage'],
          reason: '성공 경로의 호출 순서는 고정이다');
      expect(find.text(l10n.withdrawal_success), findsOneWidget);
    });

    testWidgets('요청 전에는 시스템 뒤로가기로 시트가 닫힌다',
        (WidgetTester tester) async {
      await openWithdrawalSheet(tester);

      await pressSystemBack(tester);

      expect(find.byType(BottomSheet), findsNothing,
          reason: 'PopScope 가드는 in-flight 구간만 덮어야 한다');
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('요청 중에는 뒤로가기·scrim·드래그로 시트를 닫을 수 없다',
        (WidgetTester tester) async {
      final gate = Completer<http.Response>();
      testWithdrawalHttpClient = MockClient((request) => gate.future);
      addTearDown(() {
        if (!gate.isCompleted) {
          gate.complete(http.Response('{"error":"gate"}', 500));
        }
      });

      await openWithdrawalSheet(tester);

      await tester.tap(find.text(l10n.dialog_withdraw_button_ok));
      await pumpAndIgnoreErrors(tester);
      expect(sheetProgressIndicator(), findsOneWidget,
          reason: '요청이 떠 있어야 이 테스트가 의미를 갖는다');

      await pressSystemBack(tester);
      expect(find.byType(BottomSheet), findsOneWidget,
          reason: '요청 중 뒤로가기로 닫히면 늦게 온 응답이 엉뚱한 라우트를 닫는다');
      expect(sheetProgressIndicator(), findsOneWidget);

      // scrim 탭. barrier 는 route 설정으로 막고, 실제 탭도 시트 **밖**을
      // 눌러야 의미가 있으므로 지점이 시트 밖인지 먼저 확인한다.
      const scrimPoint = Offset(400, 20);
      expect(
          ModalRoute.of(tester.element(find.byType(BottomSheet)))!
              .barrierDismissible,
          isFalse);
      expect(tester.getRect(find.byType(BottomSheet)).contains(scrimPoint),
          isFalse,
          reason: '탭 지점이 시트 밖(= scrim 영역)이어야 한다');
      await tester.tapAt(scrimPoint);
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 400));
      expect(find.byType(BottomSheet), findsOneWidget,
          reason: '요청 중 scrim 탭으로도 닫히면 안 된다');

      // 드래그는 탭으로 재현하기 어렵고, 드래그 종료는 maybePop 이 아니라
      // Navigator.pop 을 직접 불러 PopScope 로도 못 막는다 —
      // showModalBottomSheet 인자로 꺼져 있는지 구조로 고정한다.
      expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).enableDrag,
          isFalse);

      gate.complete(http.Response('{"error":"Account deletion failed"}', 500));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));
      expect(find.text(l10n.withdrawal_failed), findsOneWidget);
      expect(find.byType(MyProfilePage), findsOneWidget);
    });

    testWidgets('지연된 200 이 오기 전 시트가 최상단에서 밀려나도 다른 라우트를 닫지 않는다',
        (WidgetTester tester) async {
      final calls = <String>[];
      final gate = Completer<http.Response>();
      testWithdrawalHttpClient = MockClient((request) => gate.future);
      addTearDown(() {
        if (!gate.isCompleted) {
          gate.complete(http.Response('{"error":"gate"}', 500));
        }
      });

      await openWithdrawalSheet(tester, recordInto: calls);

      await tester.tap(find.text(l10n.dialog_withdraw_button_ok));
      await pumpAndIgnoreErrors(tester);
      expect(sheetProgressIndicator(), findsOneWidget);

      // 잠금은 UI 경로(버튼·back·scrim·drag)를 모두 막지만 라우트는
      // 프로그램적으로도 밀려날 수 있다. Navigator.pop 은 PopScope 를 거치지
      // 않으므로 그 상태를 그대로 만든다 — 이게 pop 직전 isCurrent 확인이
      // 필요한 이유다.
      navigatorKey.currentState!.pop();
      // 퇴장 애니메이션(200ms) 도중이라 시트 element 는 아직 mounted 다. 즉
      // `context.mounted` 만으로는 걸러낼 수 없는 창을 정확히 겨냥한다.
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 50));
      expect(find.byType(BottomSheet), findsOneWidget,
          reason: '아직 퇴장 중이어야 isCurrent 방어를 재는 의미가 있다');

      gate.complete(http.Response('{"success":true}', 200));
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 500));

      expect(find.byType(MyProfilePage), findsOneWidget,
          reason: '늦게 도착한 성공 응답이 프로필 라우트를 닫으면 안 된다');
      expect(calls,
          ['setBottomNavigationIndex(0)', 'logout', 'setResetStackMyPage'],
          reason: '시트 이탈 여부와 무관하게 성공 처리 순서는 그대로다');
      expect(find.text(l10n.withdrawal_success), findsOneWidget);
    });
  });
}
