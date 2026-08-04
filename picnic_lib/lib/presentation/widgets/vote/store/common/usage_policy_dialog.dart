import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/fullscreen_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

const _kstOffset = Duration(hours: 9);

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

/// **블록 경계** 구분선 — 공개 블록과 공개 블록 사이에만 쓴다.
///
/// `thickness` 를 명시해야 한다 — 예전 코드의
/// `Divider(color: ..., height: 12.h)` 는 11.7px 를 예약하고 sub-pixel 잉크를
/// 그렸다(앱 어디에도 `DividerThemeData` 가 없다).
const Widget _hairline = Divider(
  color: AppColors.grey300,
  thickness: 1,
  height: 1,
);

/// **블록 안** 규칙 그룹 구분선.
///
/// 블록 경계선과 같은 굵기 · 같은 색 · 같은 폭으로 그리면 펼친 본문에서 두 단계
/// 위계가 납작해져 "구분 없는 행의 나열" 로 읽힌다. 그래서 한 단계 밝은 grey200
/// 에 왼쪽 들여쓰기를 줘서 종속 관계를 만든다.
Widget _groupLine() =>
    Divider(color: AppColors.grey200, thickness: 1, height: 1, indent: 16.w);

/// 레이블 위 / 값 아래로 쌓은 정의쌍. 표 대신 쓰는 유일한 행 형태다.
///
/// 폭이 293px(393dp 기준) 로 예전 표 셀(122~126px)의 2.3배라서 ko/en 은 줄바꿈이
/// 사라지고, bn/fil 은 가운데 정렬된 단어 조각 대신 정상적으로 아래로 흐른다.
///
/// 세로 간격은 이 파일 전체에서 **스케일하지 않은 정수**다: 화면이 짧아졌다고
/// 행간까지 줄면 밀도만 올라가서 이번 리디자인이 고치려는 문제로 되돌아간다.
/// 반대로 가로 간격은 폭을 따라가야 하므로 `.w` 를 붙인다. 두 축의 단위가 다른
/// 건 실수가 아니라 이 규칙 때문이다.
Widget _pair(String label, String value, {bool expiry = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: _t(AppTypo.caption12M, AppColors.grey500, height: 1.20),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        // 소멸 시점 · 소멸일은 이 다이얼로그에서 가장 중요한 값이다. 강조는
        // 색이 아니라 **굵기**로 준다 — point900(#EB4A71) 은 흰 배경에서
        // 3.65:1 이고 14px 는 WCAG 의 large-text 기준(18.66px bold) 아래라
        // 4.5:1 이 적용되므로 값에 쓰면 AA 미달이다. 분홍은 의미를 나르는
        // 섹션 강조(카드 레이블)에만 남긴다.
        style: _t(
          expiry ? AppTypo.body14B : AppTypo.body14M,
          AppColors.grey900,
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
  return showFullScreenDialog(
    context: context,
    builder: (_) => const UsagePolicyPopup(),
  );
}

class UsagePolicyPopup extends ConsumerWidget {
  const UsagePolicyPopup({super.key, this.exampleReferenceDate});

  /// 골든처럼 예시 월을 재현해야 하는 호출자만 기준일을 고정한다.
  final DateTime? exampleReferenceDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final isLoggedIn = isSupabaseLoggedSafely;

    return FullScreenDialog(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              // 오른쪽 닫기 버튼과 같은 폭을 왼쪽에도 비워 제목을 화면 중심에
              // 고정한다.
              padding: const EdgeInsets.fromLTRB(64, 24, 64, 16),
              child: Center(
                child: VoteCommonTitle(
                  title: localizations.expiring_bonus_candy_guide,
                ),
              ),
            ),
            Expanded(
              child: isLoggedIn
                  ? ref
                        .watch(expireBonusProvider)
                        .when(
                          data: (data) => _buildPolicyContent(
                            context,
                            data,
                            ref.watch(walletSummaryProvider),
                          ),
                          loading: () => _buildLoading(),
                          // 보너스 조회 실패가 다이얼로그 전체를 대체하지 않는다.
                          // 코튼캔디 규칙 · 소멸 시점 · 예시 · 정책은 그대로
                          // 보이고, 실패는 보너스 카드 안에서만 말한다.
                          error: (error, stack) => _buildPolicyContent(
                            context,
                            null,
                            ref.watch(walletSummaryProvider),
                            bonusLoadFailed: true,
                          ),
                        )
                  : _buildPolicyContent(context, null, null),
            ),
          ],
        ),
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
      padding: EdgeInsets.zero,
      child: _ScrollBody(
        // 좌우 · 아래 여백을 스크롤 콘텐츠에 포함해 마지막 정책 문장까지
        // 화면 경계와 충분한 간격을 유지한다.
        contentPadding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 36),
        children: [
          if (walletState != null) ...[
            Text(
              localizations.expiry_quantity_title,
              style: _t(AppTypo.body16B, AppColors.grey900, height: 1.25),
            ),
            const SizedBox(height: 4),
            Text(
              localizations.expiry_quantity_description,
              style: _t(AppTypo.caption12R, AppColors.grey500, height: 1.35),
            ),
            const SizedBox(height: 12),
            _buildExpiryTable(
              context,
              rows,
              walletState,
              bonusLoadFailed: bonusLoadFailed,
            ),
            const SizedBox(height: 24),
          ],
          Text(
            localizations.expiry_policy_guide,
            style: _t(AppTypo.body16B, AppColors.grey900, height: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.expiry_policy_description,
            style: _t(AppTypo.caption12R, AppColors.grey500, height: 1.35),
          ),
          const SizedBox(height: 12),
          _buildCottonCard(context),
          const SizedBox(height: 8),
          _buildBonusPolicyCard(context),
          const SizedBox(height: 24),
          _buildExampleCard(
            context,
            (exampleReferenceDate ?? DateTime.now()).toUtc().add(_kstOffset),
          ),
          _hairline,
          _PolicySection(
            key: const Key('candy-policy-section'),
            title: localizations.bonus_candy_policy_title,
            children: _policyChildren(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryTable(
    BuildContext context,
    List<Map<String, dynamic>> rows,
    AsyncValue<WalletSummaryModel> walletState, {
    required bool bonusLoadFailed,
  }) {
    final l = AppLocalizations.of(context);
    final format = NumberFormat('#,###');
    final cotton = switch (walletState) {
      AsyncData(:final value) => format.format(
        value.cottonExpiringAmount.toInt(),
      ),
      _ => null,
    };

    Widget cell(
      String text, {
      TextAlign align = TextAlign.left,
      bool bold = false,
    }) => Text(
      text,
      textAlign: align,
      style: _t(
        bold ? AppTypo.body14B : AppTypo.caption12M,
        bold ? AppColors.grey900 : AppColors.grey600,
        height: 1.25,
      ),
    );

    Widget row({
      required String icon,
      required String currency,
      required String date,
      required String amount,
      required Color color,
      Key? key,
    }) => Container(
      key: key,
      color: color,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Image.asset(
                  icon,
                  package: 'picnic_lib',
                  width: 20.w,
                  height: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(child: cell(currency, bold: true)),
              ],
            ),
          ),
          Expanded(flex: 4, child: cell(date)),
          Expanded(
            flex: 2,
            child: cell(amount, align: TextAlign.right, bold: true),
          ),
        ],
      ),
    );

    final body = <Widget>[];
    if (cotton != null) {
      body.add(
        row(
          key: const Key('cotton-expiry-row'),
          icon: 'assets/icons/store/currency_cotton_candy.png',
          currency: l.wallet_cotton_candy,
          date: l.expiry_tonight_at_midnight,
          amount: cotton,
          color: AppColors.primary500.withValues(alpha: 0.10),
        ),
      );
    } else {
      body.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: walletState.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => cell(l.wallet_load_failed),
          ),
        ),
      );
    }
    for (final item in rows) {
      body.add(
        row(
          icon: 'assets/icons/store/currency_bonus_star_candy.png',
          currency: l.wallet_bonus_star_candy,
          date: '${item['prediction_month']}-15',
          amount: format.format(item['expiring_amount'] ?? 0),
          color: AppColors.point500.withValues(alpha: 0.14),
        ),
      );
    }
    if (bonusLoadFailed) {
      body.add(
        Padding(
          padding: const EdgeInsets.all(12),
          child: cell(l.bonus_candy_expiration_policy_load_fail),
        ),
      );
    }

    return ClipRRect(
      key: const Key('expiry-quantity-table'),
      borderRadius: BorderRadius.circular(12.r),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: AppColors.grey200)),
        child: Column(
          children: [
            Container(
              color: AppColors.grey100,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: cell(l.expiry_quantity_currency, bold: true),
                  ),
                  Expanded(
                    flex: 4,
                    child: cell(l.expiry_quantity_date, bold: true),
                  ),
                  Expanded(
                    flex: 2,
                    child: cell(
                      l.expiry_quantity_amount,
                      align: TextAlign.right,
                      bold: true,
                    ),
                  ),
                ],
              ),
            ),
            ...body,
          ],
        ),
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
                  style: _t(
                    AppTypo.body14B,
                    AppColors.primary500,
                    height: 1.20,
                  ),
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
  Widget _buildBonusPolicyCard(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      key: const Key('bonus-expiry-rules-section'),
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
                  localizations.bonus_star_candy_expiration_guide,
                  style: _t(AppTypo.body14B, AppColors.point900, height: 1.20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            key: const Key('bonus-policy-summary'),
            localizations.bonus_expiry_policy_summary,
            style: _t(AppTypo.caption12R, AppColors.grey600, height: 1.55),
          ),
        ],
      ),
    );
  }

  List<Widget> _exampleChildren(BuildContext context, DateTime now) {
    final l = AppLocalizations.of(context);
    final currentMonth = now.month.toString();
    final nextMonth = DateTime.utc(now.year, now.month + 1).month.toString();
    final afterNextMonth = DateTime.utc(
      now.year,
      now.month + 2,
    ).month.toString();

    // 긴 토큰부터 치환한다.
    String fill(String raw) {
      var s = _fillMonth(raw, '__THE_MONTH_AFTER_NEXT__', afterNextMonth);
      s = _fillMonth(s, '__NEXT_MONTH__', nextMonth);
      return _fillMonth(s, '__MONTH__', currentMonth);
    }

    return [
      _pair(
        l.bonus_candy_example_earn_date,
        fill(l.bonus_candy_example_1_earn),
      ),
      _pair(
        l.bonus_candy_example_expiration_date,
        fill(l.bonus_candy_example_1_expire),
        expiry: true,
      ),
      _groupLine(),
      const SizedBox(height: 12),
      _pair(
        l.bonus_candy_example_earn_date,
        fill(l.bonus_candy_example_2_earn),
      ),
      _pair(
        l.bonus_candy_example_expiration_date,
        fill(l.bonus_candy_example_2_expire),
        expiry: true,
      ),
    ];
  }

  Widget _buildExampleCard(BuildContext context, DateTime now) {
    final l = AppLocalizations.of(context);
    final values = _exampleChildren(context, now)
        .whereType<Padding>()
        .map((padding) => padding.child)
        .whereType<Column>()
        .map((column) => column.children.whereType<Text>().last.data ?? '')
        .toList();

    Widget exampleRow(Key key, String earn, String expire) => Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              earn,
              style: _t(AppTypo.caption12R, AppColors.grey600, height: 1.35),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '→',
              style: _t(AppTypo.body14B, AppColors.primary500, height: 1.0),
            ),
          ),
          Expanded(
            child: Text(
              expire,
              style: _t(AppTypo.caption12B, AppColors.grey900, height: 1.35),
            ),
          ),
        ],
      ),
    );

    return Container(
      key: const Key('bonus-expiry-example-section'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.bonus_candy_example_title,
            style: _t(AppTypo.body14B, AppColors.grey900, height: 1.2),
          ),
          const SizedBox(height: 6),
          exampleRow(const Key('bonus-example-row-1'), values[0], values[1]),
          exampleRow(const Key('bonus-example-row-2'), values[2], values[3]),
        ],
      ),
    );
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

/// 하나뿐인 스크롤 영역 + 바닥 '아래에 더 있다' 신호.
///
/// 전체 화면 셸의 `Expanded` 가 높이 상한을 정하고, `Stack` 이 loose bounded
/// 제약을 넘기므로 `SingleChildScrollView` 는 내용이 짧으면 내용에 붙고 길면
/// 남은 화면 높이 안에서 스크롤한다.
///
/// 좌우 · 아래 여백은 [contentPadding] 으로 스크롤 뷰 안에 둔다.
///
/// 위·아래 흰 그라디언트와 아래 화살표는 실제로 가려진 내용이 있을 때만 켜져
/// 스크롤 가능성을 알린다.
class _ScrollBody extends StatefulWidget {
  const _ScrollBody({required this.children, required this.contentPadding});

  final List<Widget> children;
  final EdgeInsets contentPadding;

  @override
  State<_ScrollBody> createState() => _ScrollBodyState();
}

class _ScrollBodyState extends State<_ScrollBody> {
  static const double _bottomCueHeight = 56;
  static const double _topCueHeight = 32;

  final ScrollController _controller = ScrollController();

  /// `(위에 더 있다, 아래에 더 있다)`.
  final ValueNotifier<(bool, bool)> _edges = ValueNotifier<(bool, bool)>((
    false,
    false,
  ));

  @override
  void dispose() {
    _controller.dispose();
    _edges.dispose();
    super.dispose();
  }

  /// 항상 프레임 이후로 미룬다 — 스크롤 메트릭은 레이아웃 중에도 바뀌고,
  /// 그 시점에 리스너를 더럽히면 assert 로 죽는다.
  void _syncLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ready =
          _controller.hasClients && _controller.position.hasContentDimensions;
      final next = ready
          ? (
              _controller.position.extentBefore > 1.0,
              _controller.position.extentAfter > 1.0,
            )
          : (false, false);
      if (_edges.value != next) _edges.value = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncLater();

    return Stack(
      children: [
        // 공개 블록을 펼쳐서 **내용 높이**가 바뀔 때는 `ScrollMetricsNotification`
        // 만 온다. `ScrollNotification` 은 `LayoutChangedNotification` 의 하위
        // 타입이고 `ScrollMetricsNotification` 은 `Notification` 직속이라 둘은
        // 형제 관계다(scroll_position.dart:1157). 스크롤 알림만 듣던 예전
        // 코드에서는 펼친 직후 220px 가 화면 밖에 생겨도 신호가 뜨지 않았고,
        // 사용자가 손으로 끌어야 비로소 나타났다.
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _syncLater();
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _syncLater();
              return false;
            },
            child: SingleChildScrollView(
              controller: _controller,
              padding: widget.contentPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
          ),
        ),
        Positioned(
          key: const Key('scroll-cue-top'),
          left: 0,
          right: 0,
          top: 0,
          height: _topCueHeight,
          child: IgnorePointer(
            child: ValueListenableBuilder<(bool, bool)>(
              valueListenable: _edges,
              builder: (context, edges, _) => AnimatedOpacity(
                opacity: edges.$1 ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.grey00,
                        AppColors.grey00.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          key: const Key('scroll-cue-bottom'),
          left: 0,
          right: 0,
          bottom: 0,
          height: _bottomCueHeight,
          child: IgnorePointer(
            child: ValueListenableBuilder<(bool, bool)>(
              valueListenable: _edges,
              builder: (context, edges, _) => AnimatedOpacity(
                opacity: edges.$2 ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // 0.45 에서 이미 불투명해야 한다. 코너 웨지가 커지는
                      // 구간(바닥에서 ~30px 아래)이 반투명하게 남으면 곡선에
                      // 잘린 글자 조각이 그대로 보인다.
                      stops: const [0, 0.45, 1],
                      colors: [
                        AppColors.grey00.withValues(alpha: 0),
                        AppColors.grey00,
                        AppColors.grey00,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SvgPicture.asset(
                        'assets/icons/arrow_down_style=line.svg',
                        package: 'picnic_lib',
                        width: 20.w,
                        height: 20.w,
                        colorFilter: const ColorFilter.mode(
                          AppColors.grey400,
                          BlendMode.srcIn,
                        ),
                      ),
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

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: _t(AppTypo.body14B, AppColors.grey900, height: 1.20),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );
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
  final kstNow = (nowUtc ?? DateTime.now().toUtc()).add(_kstOffset);
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
