import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

// ---------------------------------------------------------------------------
// 이 파일 전용 헬퍼
// ---------------------------------------------------------------------------

/// 이 다이얼로그의 모든 텍스트 스타일은 이 함수를 통과한다.
///
/// `AppTypo` 의 enum 항목들은 `(size, weight, 1.5, 0)` 으로 적혀 있지만 생성자는
/// `(size, weight, letterSpacing, height)` 다. 즉 **모든 토큰이 letterSpacing
/// 1.5 / height 0** 을 싣고 있고, `getTextStyle` 은 `// height: typo.height` 가
/// 주석 처리돼 있다. 여기서만 로컬로 덮어써서 가로 폭 ~10% 를 되찾고 실제 행간을
/// 준다.
///
/// `style.dart` 의 토큰을 전역으로 고치면 안 된다 — Shorebird OTA 패치로 앱의
/// 모든 화면이 리플로우된다.
TextStyle _t(AppTypo typo, Color color, {double height = 1.25}) =>
    getTextStyle(typo, color).copyWith(letterSpacing: 0, height: height);

/// 예시 문구의 `__MONTH__` 계열 플레이스홀더를 **대소문자 무관하게** 치환한다.
///
/// bn / bn_BD / fil / th / vi ARB 는 `__Month__` · `__the_month_after_next__`
/// 처럼 대소문자가 어긋난 토큰을 싣고 있어서, 기존의 대소문자 구분
/// `String.replaceAll` 로는 치환이 일어나지 않고 사용자에게 24자 토큰이 그대로
/// 노출됐다. 기존 문구에 대한 버그 픽스이지 새 문구가 아니다.
String _fillMonth(String s, String token, String value) =>
    s.replaceAll(RegExp(RegExp.escape(token), caseSensitive: false), value);

/// 섹션 구분선. `thickness` 를 명시해야 한다 — 예전 코드의
/// `Divider(color: ..., height: 12.h)` 는 11.7px 를 예약하고 sub-pixel 잉크를
/// 그렸다(앱 어디에도 `DividerThemeData` 가 없다).
const Widget _hairline = Divider(
  color: AppColors.grey200,
  thickness: 1,
  height: 1,
);

/// 레이블 위 / 값 아래로 쌓은 정의쌍. 표 대신 쓰는 유일한 행 형태다.
///
/// 폭이 293px(393dp 기준) 로 예전 표 셀(122~126px)의 2.3배라서 ko/en 은 줄바꿈이
/// 사라지고, bn/fil 은 가운데 정렬된 단어 조각 대신 정상적으로 아래로 흐른다.
Widget _pair(String label, String value, {bool expiry = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _t(AppTypo.caption12M, AppColors.grey500, height: 1.20)),
      const SizedBox(height: 4),
      Text(
        value,
        style: _t(
          AppTypo.body14M,
          expiry ? AppColors.point900 : AppColors.grey900,
          height: 1.35,
        ),
      ),
    ],
  ),
);

/// 정책 불릿. ARB 에 리터럴로 박혀 있는 `- ` 접두사는 **렌더 시점에** 떼고 실제
/// 점을 그린다(ARB 는 건드리지 않는다).
Widget _bullet(String raw) {
  final text = raw.replaceFirst(RegExp(r'^\s*[-•·]\s*'), '');
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppColors.grey400,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: _t(AppTypo.caption12R, AppColors.grey600, height: 1.45),
          ),
        ),
      ],
    ),
  );
}

Future<void> showUsagePolicyDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const Material(
        color: Colors.transparent,
        child: UsagePolicyPopup(),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

class UsagePolicyPopup extends ConsumerWidget {
  const UsagePolicyPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final isLoggedIn = isSupabaseLoggedSafely;

    return LargePopupWidget(
      // 링크(스토어 파우치 카드)와 팝업 헤더가 서로 다른 문구를 쓰고 있었다.
      // 같은 화면을 지칭하므로 하나로 통일한다.
      titleWidget: VoteCommonTitle(
        title: localizations.expiring_bonus_candy_guide,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          // 셸 밖의 24px '닫기' 행 + 카드 좌우 2px 테두리(2x2)를 미리 빼서
          // 팝업 전체가 화면의 0.82 를 절대 넘지 않게 한다.
          maxHeight: MediaQuery.sizeOf(context).height * 0.82 - 28,
        ),
        child: isLoggedIn
            ? ref.watch(expireBonusProvider).when(
                data: (data) => _buildPolicyContent(
                  context,
                  data,
                  ref.watch(walletSummaryProvider),
                ),
                loading: () => _buildLoading(),
                // 보너스 조회 실패가 다이얼로그 전체를 대체하지 않는다. 코튼캔디
                // 규칙 · 소멸 시점 · 예시 · 정책은 그대로 보이고, 실패는 보너스
                // 카드 안에서만 말한다.
                error: (error, stack) => _buildPolicyContent(
                  context,
                  null,
                  ref.watch(walletSummaryProvider),
                  bonusLoadFailed: true,
                ),
              )
            : _buildPolicyContent(context, null, null),
      ),
    );
  }

  /// 보너스 조회 중. `Column(min)` 이 있어야 카드가 0.82H 짜리 빈 상자가 되지
  /// 않고 내용에 붙는다(`Center` 는 bounded 제약을 받으면 꽉 채운다).
  Widget _buildLoading() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: SizedBox(
            width: 28.w,
            height: 28.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary500,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildPolicyContent(
    BuildContext context,
    List<Map<String, dynamic>?>? expiringData,
    AsyncValue<WalletSummaryModel>? walletState, {
    bool bonusLoadFailed = false,
  }) {
    final localizations = AppLocalizations.of(context);
    final rows = _sortedBonusRows(expiringData);

    return Padding(
      // top / bottom 은 의도적으로 **스케일하지 않은 정수**다.
      // - 64: 셸의 타이틀 칩은 하드코딩 48px 인데 `60.h` 는 splitScreenMode 때문에
      //   700dp 미만 기기에서 47.1px 로 줄어 칩과 겹친다.
      // - 56: 셸이 `BorderRadius.circular(120.r)` 로 antiAlias 클립한다. 바닥에서
      //   d 만큼 위의 코너 침범량은 R - sqrt(R^2 - (R-d)^2) 이고, 411.4dp 에서
      //   d=48 은 25.5px(가로 패딩 25.1px)로 0.4px 모자란다. d=56 은 19.9px.
      //   이 패딩은 스크롤 뷰 **밖**이라 어떤 스크롤 위치에서도 글자가 코너
      //   웨지로 들어가지 않는다.
      padding: EdgeInsets.fromLTRB(24.w, 64, 24.w, 56),
      child: _ScrollFadeBody(
        children: [
          if (walletState != null) ...[
            _buildHero(context, expiringData, walletState),
            const SizedBox(height: 16),
          ],
          _buildCottonCard(context),
          // 두 재화 카드는 한 쌍이라 일부러 좁게 붙인다.
          const SizedBox(height: 8),
          _buildBonusCard(context, rows, bonusLoadFailed: bonusLoadFailed),
          // '지금' 과 '규칙' 의 경계.
          const SizedBox(height: 24),
          _hairline,
          // 세 공개 블록에 모두 키를 준다. 히어로는 지갑 상태에 따라 붙었다
          // 떨어지므로 Column 의 자식 수가 바뀌는데, 키가 없으면 위치 기반
          // 매칭이 어긋나 펼침 상태가 옆 블록으로 옮겨갈 수 있다.
          _Disclosure(
            key: const Key('bonus-expiry-rules-section'),
            title: localizations.bonus_candy_expiration_time_title,
            // 보여줄 개인 소멸 예정 행이 없으면(비로그인 · 조회 실패 · 예정 없음)
            // 이 매뉴얼이 곧 답이다.
            initiallyExpanded: rows.isEmpty,
            children: _timingRuleChildren(context),
          ),
          _hairline,
          _Disclosure(
            key: const Key('bonus-expiry-example-section'),
            title: localizations.bonus_candy_example_title,
            children: _exampleChildren(context),
          ),
          _hairline,
          // 오너가 정책을 항상 보이게 하고 싶다면 여기 `initiallyExpanded: true`
          // 한 줄이 전부다(레이아웃은 그대로).
          _Disclosure(
            key: const Key('candy-policy-section'),
            title: localizations.bonus_candy_policy_title,
            children: _policyChildren(context),
          ),
        ],
      ),
    );
  }

  /// `prediction_month` 오름차순으로 정렬한 소멸 예정 행. null 행은 버린다.
  List<Map<String, dynamic>> _sortedBonusRows(
    List<Map<String, dynamic>?>? expiringData,
  ) {
    if (expiringData == null) return const [];
    final rows = expiringData.whereType<Map<String, dynamic>>().toList();
    rows.sort(
      (a, b) => (a['prediction_month']?.toString() ?? '').compareTo(
        b['prediction_month']?.toString() ?? '',
      ),
    );
    return rows;
  }

  /// `오늘 만료 : 코튼캔디 N + 보너스 스타캔디 N`
  ///
  /// 보너스 스타캔디는 **오늘 실제로 소멸되는 금액이 있을 때만** 붙는다.
  /// 보너스 만료는 매월 15일 00:00 (KST) 이므로(`computeBonusExpiry`), 달력에서
  /// 15일을 하드코딩하는 대신 서버가 준 소멸 예정 데이터에서 "이번 달 몫이
  /// 오늘 만료되는가"를 판정한다 — 경계 규칙이 서버와 어긋날 수 없게.
  Widget _buildHero(
    BuildContext context,
    List<Map<String, dynamic>?>? expiringData,
    AsyncValue<WalletSummaryModel> walletState,
  ) {
    final localizations = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,###');
    final cotton = switch (walletState) {
      AsyncData(:final value) => value.cottonExpiringAmount,
      _ => BigInt.zero,
    };
    final bonus = bonusExpiringToday(expiringData);
    // 0 에 긴급 강조색을 쓰지 않는다.
    final urgent = cotton > BigInt.zero || bonus > 0;

    final text = bonus > 0
        ? localizations.expiring_today_cotton_and_bonus(
            numberFormat.format(cotton.toInt()),
            numberFormat.format(bonus),
          )
        : localizations.expiring_today_cotton_only(
            numberFormat.format(cotton.toInt()),
          );

    final Widget slot = walletState.when(
      data: (_) => Text(
        text,
        style: urgent
            ? _t(AppTypo.body16B, AppColors.grey900, height: 1.30)
            : _t(AppTypo.body14M, AppColors.grey600, height: 1.35),
      ),
      loading: () => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 16.w,
          height: 16.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary500,
          ),
        ),
      ),
      error: (error, stackTrace) => Text(
        localizations.wallet_load_failed,
        style: _t(AppTypo.body14M, AppColors.grey600, height: 1.35),
      ),
    );

    return Row(
      key: const Key('expiry-today-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SvgPicture.asset(
            'assets/icons/information_style=fill.svg',
            package: 'picnic_lib',
            width: 16.w,
            height: 16.w,
            colorFilter: ColorFilter.mode(
              urgent ? AppColors.point900 : AppColors.grey400,
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(child: slot),
      ],
    );
  }

  /// 코튼캔디 카드. 개인 데이터가 아니라 **규칙**을 말하므로 지갑 상태와
  /// 무관하게(로딩 · 실패 · 비로그인 포함) 항상 렌더한다.
  Widget _buildCottonCard(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      key: const Key('cotton-candy-section'),
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/store/currency_cotton_candy.png',
                width: 20.w,
                height: 20.w,
                package: 'picnic_lib',
              ),
              SizedBox(width: 8.w),
              // 12개 로케일이 영어 'Cotton Candy' 를 렌더한다 — Expanded 필수.
              Expanded(
                child: Text(
                  localizations.wallet_cotton_candy,
                  style: _t(AppTypo.body14B, AppColors.primary500, height: 1.20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizations.cotton_candy_daily_expiry_notice,
            style: _t(AppTypo.body14R, AppColors.grey600, height: 1.45),
          ),
        ],
      ),
    );
  }

  /// 보너스 스타캔디 카드 — 코튼캔디 카드의 형제. 배경색과 강조색만 다르다.
  Widget _buildBonusCard(
    BuildContext context,
    List<Map<String, dynamic>> rows, {
    required bool bonusLoadFailed,
  }) {
    final localizations = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,###');

    return Container(
      key: const Key('bonus-star-candy-section'),
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        // 하드코딩 0xFFFFF1F7 대신 토큰. point500(#FFA9BD) 을 흰 배경 위 14% 로
        // 얹으면 같은 분홍으로 읽힌다(정확히 같은 값은 아니고, 의도한 근사치다).
        color: AppColors.point500.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 파우치 카드 · 적립 영수증과 같은 아이콘으로 맞춘다.
              Image.asset(
                'assets/icons/store/currency_bonus_star_candy.png',
                width: 20.w,
                height: 20.w,
                package: 'picnic_lib',
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  localizations.wallet_bonus_star_candy,
                  style: _t(AppTypo.body14B, AppColors.point900, height: 1.20),
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2:1 로 나눈다. Row 의 flex 배분은 "Flexible 이 안 쓴 공간을
                    // Expanded 가 먹는" 방식이 아니라 flex 비율대로 자르는
                    // 방식이므로, 1:1 로 두면 40px 밖에 필요 없는 금액이 절반을
                    // 쥐고 날짜가 1.3x 배율에서 두 줄로 접힌다.
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${rows[i]['prediction_month']}-15 (KST)',
                        style: _t(
                          AppTypo.caption12M,
                          AppColors.grey600,
                          height: 1.20,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // 잔액은 절대 잘라 쓰지 않는다 — 줄여서 보여준다.
                    // Flexible 이 아니라 Expanded 여야 금액이 카드 오른쪽 끝에
                    // 붙는다(Flexible 은 남는 공간을 뒤에 흘려버린다).
                    Expanded(
                      flex: 1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          numberFormat.format(rows[i]['expiring_amount'] ?? 0),
                          style: _t(
                            AppTypo.body14B,
                            AppColors.point900,
                            height: 1.20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (bonusLoadFailed) ...[
            const SizedBox(height: 12),
            Text(
              localizations.bonus_candy_expiration_policy_load_fail,
              style: _t(AppTypo.body14M, AppColors.grey600, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  /// 소멸 시점 안내 — 예전 표의 **헤더 셀이 행 레이블**이 된다. 그룹마다
  /// 반복하므로 모든 행이 스스로를 설명하고, bn/fil 에서 줄바꿈이 나도 무해하다.
  List<Widget> _timingRuleChildren(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      _pair(
        l.bonus_candy_expiration_policy_earn_period,
        l.bonus_candy_earn_period_1_to_14,
      ),
      _pair(
        l.bonus_candy_expiration_policy_expiration_date,
        l.bonus_candy_expiration_next_month,
        expiry: true,
      ),
      _hairline,
      const SizedBox(height: 12),
      _pair(
        l.bonus_candy_expiration_policy_earn_period,
        l.bonus_candy_earn_period_15_to_end,
      ),
      _pair(
        l.bonus_candy_expiration_policy_expiration_date,
        l.bonus_candy_expiration_month_after_next,
        expiry: true,
      ),
    ];
  }

  List<Widget> _exampleChildren(BuildContext context) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final currentMonth = now.month.toString();
    final nextMonth = (now.month % 12 + 1).toString();
    final afterNextMonth = (now.month % 12 + 2).toString();

    // 긴 토큰부터 치환한다.
    String fill(String raw) {
      var s = _fillMonth(raw, '__THE_MONTH_AFTER_NEXT__', afterNextMonth);
      s = _fillMonth(s, '__NEXT_MONTH__', nextMonth);
      return _fillMonth(s, '__MONTH__', currentMonth);
    }

    return [
      _pair(l.bonus_candy_example_earn_date, fill(l.bonus_candy_example_1_earn)),
      _pair(
        l.bonus_candy_example_expiration_date,
        fill(l.bonus_candy_example_1_expire),
        expiry: true,
      ),
      _hairline,
      const SizedBox(height: 12),
      _pair(l.bonus_candy_example_earn_date, fill(l.bonus_candy_example_2_earn)),
      _pair(
        l.bonus_candy_example_expiration_date,
        fill(l.bonus_candy_example_2_expire),
        expiry: true,
      ),
    ];
  }

  List<Widget> _policyChildren(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      _bullet(l.bonus_candy_policy_1),
      _bullet(l.bonus_candy_policy_2),
      _bullet(l.bonus_candy_policy_3),
    ];
  }
}

/// 하나뿐인 스크롤 영역 + 바닥 페이드.
///
/// `ConstrainedBox` 가 높이 상한을 정하고, `Stack` 이 loose bounded 제약을
/// 넘기므로 `SingleChildScrollView` 는 `min(내용, 상한)` 으로 **내용에 붙는다**.
/// 예전 구조(`Column(max)` + `Expanded`)는 로그아웃 상태에서도 카드를 658px 로
/// 고정해 157px 의 흰 여백을 남겼다.
///
/// 페이드는 실제로 뒤에 가려진 내용이 있을 때만 보인다. 안드로이드/iOS 의
/// `MaterialScrollBehavior` 는 스크롤바를 그리지 않아서(`return child`) 이게
/// 유일하게 가능한 '아래에 더 있다' 신호다.
class _ScrollFadeBody extends StatefulWidget {
  const _ScrollFadeBody({required this.children});

  final List<Widget> children;

  @override
  State<_ScrollFadeBody> createState() => _ScrollFadeBodyState();
}

class _ScrollFadeBodyState extends State<_ScrollFadeBody> {
  static const double _fadeHeight = 32;

  final ScrollController _controller = ScrollController();
  final ValueNotifier<bool> _hasMore = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _controller.dispose();
    _hasMore.dispose();
    super.dispose();
  }

  /// 항상 프레임 이후로 미룬다 — 스크롤 메트릭은 레이아웃 중에도 바뀌고,
  /// 그 시점에 리스너를 더럽히면 assert 로 죽는다.
  void _syncLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = _controller.hasClients &&
          _controller.position.hasContentDimensions &&
          _controller.position.extentAfter > 1.0;
      if (_hasMore.value != next) _hasMore.value = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncLater();

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (_) {
            _syncLater();
            return false;
          },
          child: SingleChildScrollView(
            controller: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _fadeHeight,
          child: IgnorePointer(
            child: ValueListenableBuilder<bool>(
              valueListenable: _hasMore,
              builder: (context, hasMore, _) => AnimatedOpacity(
                opacity: hasMore ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.grey00.withValues(alpha: 0),
                        AppColors.grey00,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 파일 안에서만 쓰는 작은 접기/펼치기.
///
/// `ExpansionTile` 을 쓰지 않는다: `ListTileTheme` / `ExpansionTileTheme` 상속을
/// 끌고 오고, 앱의 SVG 아이콘 세트와 맞지 않는 MaterialIcons 셰브런을 싣고,
/// (Flutter 3.41 의 `Expansible` 경로에서) 접힌 본문을 `Offstage` +
/// `TickerMode(false)` 로 감싸서 `find.text` 와 스크린리더에서 사라지게 만든다.
class _Disclosure extends StatefulWidget {
  const _Disclosure({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<_Disclosure> createState() => _DisclosureState();
}

class _DisclosureState extends State<_Disclosure> {
  late bool _open = widget.initiallyExpanded;
  final GlobalKey _bodyKey = GlobalKey();

  void _toggle() {
    setState(() => _open = !_open);
    if (!_open) return;
    // 새로 드러난 내용을 화면 안으로 끌어온다 — "내 내용을 잘라먹었다" 는
    // 인식을 직접 공격하는 부분.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _bodyKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Container(
              // minHeight 여야 한다 — 2.0x 텍스트 배율의 bn 에서 제목이 줄바꿈
              // 되면 고정 48 은 세로로 넘친다.
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: _t(AppTypo.body14B, AppColors.grey900, height: 1.20),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: SvgPicture.asset(
                      'assets/icons/arrow_down_style=line.svg',
                      package: 'picnic_lib',
                      width: 16.w,
                      height: 16.w,
                      colorFilter: ColorFilter.mode(
                        _open ? AppColors.grey500 : AppColors.grey400,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _open
              // 본문에 좌측 들여쓰기를 주지 않는다 — 값에 293px 전체가 필요하다.
              // 종속 관계는 레이블의 grey500 색으로 표현한다.
              ? Padding(
                  key: _bodyKey,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

/// 오늘(KST) 소멸되는 보너스 스타캔디 금액. 소멸일이 아니면 0.
///
/// 보너스 만료는 매월 15일 00:00 (KST) 이다(`computeBonusExpiry`). 달력 15일을
/// 코드에 박는 대신 서버가 준 월별 소멸 예정 데이터에서 "이번 달 몫"을 찾아
/// 판정하므로, 서버가 규칙을 바꾸면 화면도 따라간다.
int bonusExpiringToday(
  List<Map<String, dynamic>?>? expiringData, {
  DateTime? nowUtc,
}) {
  if (expiringData == null) return 0;
  final kstNow = (nowUtc ?? DateTime.now().toUtc()).add(
    const Duration(hours: 9),
  );
  if (kstNow.day != 15) return 0;
  final thisMonth =
      '${kstNow.year.toString().padLeft(4, '0')}-'
      '${kstNow.month.toString().padLeft(2, '0')}';
  for (final row in expiringData) {
    if (row == null) continue;
    if (row['prediction_month']?.toString() != thisMonth) continue;
    final amount = row['expiring_amount'];
    if (amount is num) return amount.toInt();
    return int.tryParse(amount?.toString() ?? '') ?? 0;
  }
  return 0;
}
