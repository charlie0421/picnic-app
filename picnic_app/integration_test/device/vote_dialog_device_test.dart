// PICNIC-2695 실기기 확인용 하네스.
//
// 위젯 테스트는 가짜 텍스트 입력을 쓰기 때문에 "iOS 숫자 키패드가 실제로
// 내려가는가" 를 증명하지 못한다. 이 통합 테스트는 실기기/시뮬레이터의 실제
// 엔진 위에서 진짜 소프트 키보드를 띄우고, 팝업을 닫은 뒤 키보드 인셋이 0 으로
// 돌아오는지를 관찰한다. 백엔드에는 접속하지 않는다 — 다이얼로그만 직접
// 마운트하고 필요한 provider 만 스텁한다.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';

class _MockNavigationInfo extends NavigationInfo {
  @override
  Navigation build() => const Navigation(
        portalType: PortalType.vote,
        showPortal: true,
        showTopMenu: true,
        showBottomNavigation: true,
        voteBottomNavigationIndex: 0,
      );

  @override
  void setPortal(PortalType portalType) {
    state = state.copyWith(portalType: portalType);
  }
}

class _MockUserInfo extends UserInfo {
  @override
  Future<UserProfilesModel?> build() async => UserProfilesModel(
        id: 'device-harness-user',
        nickname: 'DeviceHarness',
        avatarUrl: null,
        isAdmin: false,
        isSuperAdmin: false,
        starCandy: 1000,
        starCandyBonus: 0,
        jmaCandy: 0,
      );
}

class _MockAppSetting extends AppSetting {
  @override
  Setting build() => const Setting(
        themeMode: ThemeMode.light,
        language: 'ko',
        area: 'all',
        postAnonymousMode: false,
      );
}

class _MockGlobalMediaQuery extends GlobalMediaQuery {
  @override
  MediaQueryData build() => const MediaQueryData(
        size: Size(375, 812),
        padding: EdgeInsets.only(top: 44, bottom: 34),
        devicePixelRatio: 3.0,
      );
}

class _MockCommunityStateInfo extends CommunityStateInfo {
  @override
  CommunityState build() => const CommunityState();
}

WalletSummaryModel _walletWith(int star) => WalletSummaryModel(
      contractVersion: 'wallet.v1',
      star: BigInt.from(star),
      bonus: BigInt.zero,
      cotton: BigInt.zero,
      cottonExpiringAmount: BigInt.zero,
      cottonNextExpiresAt: null,
      snapshotAt: DateTime.utc(2026, 9, 15),
    );

/// 마지막으로 만들어진 지갑 노티파이어. 잔액 부족 분기를 재현할 때 테스트가
/// 프레임 경계 없이 상태를 낮추려고 잡아 둔다.
_StaticWalletSummary? _lastWallet;

class _StaticWalletSummary extends WalletSummary {
  @override
  Future<WalletSummaryModel> build() async {
    _lastWallet = this;
    return _walletWith(1000);
  }

  @override
  Future<void> refresh() async {}

  /// 서버가 더 적은 잔액을 돌려준 상황. 프레임을 돌리지 않고 부르면 제출
  /// 버튼은 직전 빌드 기준으로 아직 활성인 채 제출 경로만 잔액 부족을 본다 —
  /// 이슈의 "간간히" 에 해당하는 경합이다.
  void drainTo(int star) => state = AsyncData(_walletWith(star));
}

VoteModel _vote() => VoteModel.fromJson({
      'id': 1,
      'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
      'vote_category': 'birthday',
      'main_image': null,
      'wait_image': null,
      'result_image': null,
      'vote_content': null,
      'vote_item': null,
      'created_at': null,
      'visible_at': null,
      'start_at':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'stop_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'is_ended': false,
      'is_upcoming': false,
      'is_partnership': false,
      'partner': null,
      'reward': null,
    });

VoteItemModel _voteItem() => VoteItemModel.fromJson({
      'id': 1,
      'vote_total': 1000,
      'vote_id': 1,
      'artist': {
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
      },
      'artist_group': null,
    });

Widget _harness() => ProviderScope(
      overrides: [
        navigationInfoProvider.overrideWith(_MockNavigationInfo.new),
        userInfoProvider.overrideWith(_MockUserInfo.new),
        appSettingProvider.overrideWith(_MockAppSetting.new),
        globalMediaQueryProvider.overrideWith(_MockGlobalMediaQuery.new),
        communityStateInfoProvider.overrideWith(_MockCommunityStateInfo.new),
        walletSummaryProvider.overrideWith(_StaticWalletSummary.new),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 892),
        minTextAdapt: true,
        splitScreenMode: true,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('ko'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en')],
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (_) => VotingDialog(
                      voteModel: _vote(),
                      voteItemModel: _voteItem(),
                      portalType: VotePortal.vote,
                    ),
                  ),
                  child: const Text('open-voting-dialog'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

/// 실제 소프트 키보드가 차지한 화면 인셋. 테스트 바인딩이 주입한 값이 아니라
/// 엔진이 플랫폼에서 받아온 값이다.
double _keyboardInset(WidgetTester tester) =>
    tester.view.viewInsets.bottom / tester.view.devicePixelRatio;

Future<void> _settleFor(WidgetTester tester, Duration total) async {
  final end = DateTime.now().add(total);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Environment.initTestConfig(<String, dynamic>{
      'supabase': {
        'url': 'http://127.0.0.1:1',
        'anon_key': 'device-harness',
        'storage': {
          'url': 'http://127.0.0.1:1/storage/v1',
          'anon_key': 'device-harness',
        },
      },
      'theme': {
        'colors': {
          'primary': '0xFF9374FF',
          'secondary': '0xFF83FBC8',
          'sub': '0xFFCDFB5D',
          'point': '0xFFFFA9BD',
          'point_900': '0xFFEB4A71',
        },
      },
      'logging': {'level': 'off'},
    }, environment: 'test-local');
  });

  testWidgets('투표 팝업에 X 가 보이고, 키보드를 올린 뒤 X 로 닫으면 키보드가 내려간다', (
    tester,
  ) async {
    // 진짜 플랫폼 키보드를 쓰기 위해 테스트용 가짜 텍스트 입력을 떼어낸다.
    tester.testTextInput.unregister();
    addTearDown(tester.testTextInput.register);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-voting-dialog'));
    await tester.pumpAndSettle();
    expect(find.byType(VotingDialog), findsOneWidget);

    debugPrint('PICNIC2695 HOLD dialog-open');
    await _settleFor(tester, const Duration(seconds: 8));
    debugPrint('PICNIC2695 dialog opened, inset=${_keyboardInset(tester)}');

    // 키보드가 내려간 상태에서는 X 가 반드시 있어야 한다. 키보드가 올라오면
    // 본문 예산이 줄어 기기에 따라 X 가 양보할 수 있으므로(PICNIC-2694 가 확보한
    // 조작부 보장이 우선), 그 경우는 배리어 케이스가 따로 검증한다.
    final closeTarget = find.byKey(kLargePopupTopCloseKey);
    debugPrint(
      'PICNIC2695 close targets (keyboard down): '
      '${closeTarget.evaluate().length}',
    );
    expect(closeTarget, findsOneWidget, reason: '키보드가 없으면 우상단 X 가 있어야 한다');

    // 금액 입력을 눌러 실제 숫자 키패드를 올린다.
    final input = find.byType(TextFormField);
    expect(input, findsOneWidget);
    await tester.tap(input);
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));

    final insetWithKeyboard = _keyboardInset(tester);
    debugPrint('PICNIC2695 HOLD keyboard-up inset=$insetWithKeyboard');
    await _settleFor(tester, const Duration(seconds: 8));

    // 키패드를 내린 뒤 X 로 닫는다. 키보드가 올라온 동안 X 가 양보했다면
    // 여기서 돌아와 있어야 한다.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));
    if (find.byType(VotingDialog).evaluate().isEmpty) {
      // 배리어 탭이 팝업까지 닫았다면 다시 연다.
      await tester.tap(find.text('open-voting-dialog'));
      await tester.pumpAndSettle();
    }
    debugPrint(
      'PICNIC2695 close targets (keyboard back down): '
      '${closeTarget.evaluate().length}',
    );
    expect(closeTarget, findsOneWidget, reason: '키패드를 내리면 X 가 돌아와야 한다');
    await tester.tap(closeTarget);
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));

    final insetAfterClose = _keyboardInset(tester);
    debugPrint('PICNIC2695 HOLD after-close inset=$insetAfterClose');
    await _settleFor(tester, const Duration(seconds: 8));

    expect(
      find.byType(VotingDialog),
      findsNothing,
      reason: 'X 를 누르면 투표 팝업이 닫혀야 한다',
    );
    expect(
      insetWithKeyboard,
      greaterThan(0),
      reason: '입력을 탭하면 실제 소프트 키보드가 올라와야 한다 (인셋 > 0)',
    );
    expect(
      insetAfterClose,
      lessThan(1),
      reason: '팝업이 닫히면 실제 소프트 키보드도 내려가야 한다 (인셋 ≈ 0)',
    );
  });

  // 이슈가 말한 "투표 중간에 취소" 에 가장 가까운 경로. 금액을 채우고 키패드를
  // 올린 상태에서 제출을 누르는 순간 서버 잔액이 모자라면, 아직 포커스가 살아
  // 있는 입력 위로 오류 팝업이 뜬다. 그 뒤 팝업들을 닫을 때 키패드가 남는지 본다.
  testWidgets('잔액 부족 오류 팝업이 뜬 뒤에도 키패드가 정리된다', (tester) async {
    tester.testTextInput.unregister();
    addTearDown(tester.testTextInput.register);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-voting-dialog'));
    await tester.pumpAndSettle();

    // 전체 사용으로 먼저 금액을 채운다. 이 순서라야 한다 — 전체 사용은 스스로
    // 포커스를 해제하므로 키패드를 올린 뒤에 누르면 키패드가 사라진다.
    final checkAll = find.byType(Checkbox);
    if (checkAll.evaluate().isNotEmpty) {
      await tester.tap(checkAll.first);
    } else {
      await tester.tap(find.textContaining('전체').first);
    }
    await tester.pumpAndSettle();
    debugPrint('PICNIC2695 insufficient: amount filled');

    // 이제 입력을 눌러 실제 키패드를 올린다.
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));
    final insetWithKeyboard = _keyboardInset(tester);
    debugPrint('PICNIC2695 insufficient: keyboard up inset=$insetWithKeyboard');

    // 프레임을 돌리지 않고 잔액을 떨어뜨린 뒤 제출을 누른다.
    _lastWallet!.drainTo(0);
    await tester.tap(find.text('투표'));
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));

    final insetWithError = _keyboardInset(tester);
    debugPrint('PICNIC2695 HOLD error-dialog inset=$insetWithError');
    await _settleFor(tester, const Duration(seconds: 8));

    // 오류 팝업을 배리어로 닫는다 (확인 버튼은 자동으로 pop 하지 않는다).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));
    final insetAfterError = _keyboardInset(tester);
    debugPrint(
      'PICNIC2695 HOLD after-error-close inset=$insetAfterError '
      'votingDialogs=${find.byType(VotingDialog).evaluate().length}',
    );
    await _settleFor(tester, const Duration(seconds: 8));

    // 마지막으로 투표 팝업 자체를 닫는다.
    if (find.byType(VotingDialog).evaluate().isNotEmpty) {
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await _settleFor(tester, const Duration(seconds: 2));
    }
    final insetFinal = _keyboardInset(tester);
    debugPrint('PICNIC2695 insufficient: final inset=$insetFinal');

    expect(insetWithKeyboard, greaterThan(0), reason: '먼저 실제 키패드가 올라와야 한다');
    expect(
      insetWithError,
      lessThan(1),
      reason: '오류 팝업이 뜬 시점에 이미 키패드가 내려가 있어야 한다',
    );
    expect(
      insetAfterError,
      lessThan(1),
      reason: '오류 팝업을 닫아도 키패드가 입력으로 되돌아오면 안 된다 — 사용자에게는 '
          '"취소했는데 숫자 키패드가 사라지지 않는" 증상으로 보인다',
    );
    expect(insetFinal, lessThan(1), reason: '모두 닫은 뒤 키패드가 남아 있으면 안 된다');
  });

  testWidgets('키보드를 올린 뒤 배리어를 탭해 닫아도 키보드가 내려간다', (tester) async {
    tester.testTextInput.unregister();
    addTearDown(tester.testTextInput.register);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-voting-dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));
    final insetWithKeyboard = _keyboardInset(tester);
    debugPrint('PICNIC2695 barrier: keyboard up, inset=$insetWithKeyboard');

    // 팝업 바깥(최상단) 을 눌러 배리어 dismiss.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await _settleFor(tester, const Duration(seconds: 2));
    final insetAfterClose = _keyboardInset(tester);
    debugPrint('PICNIC2695 barrier: after close, inset=$insetAfterClose');

    expect(find.byType(VotingDialog), findsNothing);
    expect(insetWithKeyboard, greaterThan(0));
    expect(
      insetAfterClose,
      lessThan(1),
      reason: '배리어로 닫아도 실제 소프트 키보드가 내려가야 한다',
    );
  });
}
