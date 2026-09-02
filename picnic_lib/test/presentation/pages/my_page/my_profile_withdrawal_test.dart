import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/l10n/app_localizations_ko.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// PICNIC-2520 회귀 테스트.
///
/// delete-user Edge Function 이 500 을 돌려주면 예전에는 예외가
/// `onPressed: () => _deleteAccount()` 안에서 사라져 화면에 아무 변화가 없었다.
/// 사용자는 "버튼이 비활성" 이라고 인지했고, 응답을 기다리는 동안 계속 다시
/// 탭할 수 있었다. 두 가지를 못 박는다 — 실패 피드백과 중복 탭 차단.
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
  Future<void> openWithdrawalSheet(WidgetTester tester) async {
    // 기본 테스트 표면 800x600 은 세로가 짧다. 바텀시트가 받는 높이는 화면의
    // 9/16 뿐이라 모달 Column 이 그대로 오버플로해서, 정작 재려는 것보다
    // 레이아웃 예외가 먼저 터진다. 그래서 **세로만** 늘린다 — 폭을 줄이면
    // 이번엔 프로필 페이지의 닉네임 Row 가 가로로 넘친다. 둘 다 프로덕션
    // 기하(393x892)가 아니라 하네스 기하 탓이다.
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(const MyProfilePage()));
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
  });
}
