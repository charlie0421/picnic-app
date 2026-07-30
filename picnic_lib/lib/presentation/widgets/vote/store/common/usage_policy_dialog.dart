import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_panel.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

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
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: isLoggedIn
            ? ref
                  .watch(expireBonusProvider)
                  .when(
                    data: (data) => _buildPolicyContent(
                      context,
                      data,
                      ref.watch(walletSummaryProvider),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        localizations.bonus_candy_expiration_policy_load_fail,
                      ),
                    ),
                  )
            : _buildPolicyContent(context, null, null),
      ),
    );
  }

  Widget _buildPolicyContent(
    BuildContext context,
    List<Map<String, dynamic>?>? expiringData,
    AsyncValue<WalletSummaryModel>? walletState,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
      ).copyWith(top: 60.h, bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (walletState != null) ...[
            _buildTodayExpirySummary(context, expiringData, walletState),
            SizedBox(height: 12.h),
            _buildCottonStateSection(context, walletState),
            SizedBox(height: 20.h),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBonusStarCandySection(context, expiringData),
                  SizedBox(height: 20.h),
                  // 정책은 배경 없이 최하단.
                  _buildPolicyDetailsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `오늘 만료 : 코튼캔디 N + 보너스 스타캔디 N`
  ///
  /// 보너스 스타캔디는 **오늘 실제로 소멸되는 금액이 있을 때만** 붙는다.
  /// 보너스 만료는 매월 15일 00:00 (KST) 이므로(`computeBonusExpiry`), 달력에서
  /// 15일을 하드코딩하는 대신 서버가 준 소멸 예정 데이터에서 "이번 달 몫이
  /// 오늘 만료되는가"를 판정한다 — 경계 규칙이 서버와 어긋날 수 없게.
  Widget _buildTodayExpirySummary(
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

    final text = bonus > 0
        ? localizations.expiring_today_cotton_and_bonus(
            numberFormat.format(cotton.toInt()),
            numberFormat.format(bonus),
          )
        : localizations.expiring_today_cotton_only(
            numberFormat.format(cotton.toInt()),
          );

    return Text(
      text,
      key: const Key('expiry-today-summary'),
      style: getTextStyle(AppTypo.body14B, AppColors.grey800),
    );
  }

  Widget _buildCottonStateSection(
    BuildContext context,
    AsyncValue<WalletSummaryModel> walletState,
  ) {
    return walletState.when(
      data: (wallet) => _buildCottonExpirySection(context, wallet),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text(
        AppLocalizations.of(context).wallet_load_failed,
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildCottonExpirySection(
    BuildContext context,
    WalletSummaryModel wallet,
  ) {
    final localizations = AppLocalizations.of(context);
    // "다음 만료" 줄은 제거(오너 스펙). 코튼캔디는 매일 자정에 소멸되므로
    // 날짜를 나열하는 대신 규칙 한 줄로 안내한다.
    final expiry = localizations.cotton_candy_daily_expiry_notice;

    return Container(
      key: const Key('cotton-candy-section'),
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.1),
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
              Text(
                localizations.wallet_cotton_candy,
                style: getTextStyle(AppTypo.body14B, AppColors.primary500),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            expiry,
            textAlign: TextAlign.left,
            style: getTextStyle(AppTypo.caption12M, AppColors.grey700),
          ),
        ],
      ),
    );
  }

  /// 보너스 스타캔디 구역 — 코튼캔디 구역의 형제. 배경색만 다르게 두고,
  /// 기존에 정책 본문에 흩어져 있던 소멸 시점 안내와 예시를 이 안으로 모았다.
  Widget _buildBonusStarCandySection(
    BuildContext context,
    List<Map<String, dynamic>?>? expiringData,
  ) {
    final localizations = AppLocalizations.of(context);

    return Container(
      key: const Key('bonus-star-candy-section'),
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        // 코튼캔디 구역과 구분되는 배경 (파우치의 보너스 강조색 계열).
        color: const Color(0xFFFFF1F7),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/store/bonus.png',
                width: 20.w,
                height: 20.w,
                package: 'picnic_lib',
              ),
              SizedBox(width: 8.w),
              Text(
                localizations.wallet_bonus_star_candy,
                style: getTextStyle(AppTypo.body14B, AppColors.primary500),
              ),
            ],
          ),
          if (expiringData != null && expiringData.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildExpiringBonusRows(context, expiringData),
          ],
          SizedBox(height: 16.h),
          _buildPolicyItem(
            context,
            localizations.bonus_candy_expiration_time_title,
            isTitle: true,
          ),
          _buildSimplifiedExpirationTable(context),
          SizedBox(height: 16.h),
          _buildPolicyItem(
            context,
            localizations.bonus_candy_example_title,
            isTitle: true,
          ),
          _buildExampleTable(context),
        ],
      ),
    );
  }

  Widget _buildExpiringBonusRows(
    BuildContext context,
    List<Map<String, dynamic>?> expiringData,
  ) {
    final numberFormat = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...expiringData.map((e) {
            if (e == null) return const SizedBox.shrink();
            final amount = e['expiring_amount'] ?? 0;
            return Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${e['prediction_month']}-15 (KST)',
                    style: getTextStyle(AppTypo.caption12M, AppColors.grey700),
                  ),
                  Text(
                    numberFormat.format(amount),
                    style: getTextStyle(
                      AppTypo.caption12M,
                      AppColors.primary500,
                    ),
                  ),
                ],
              ),
            );
        }),
      ],
    );
  }

  /// 캔디 정책 — 배경 없이 최하단.
  Widget _buildPolicyDetailsSection(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      key: const Key('candy-policy-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPolicyItem(
          context,
          localizations.bonus_candy_policy_title,
          isTitle: true,
        ),
        _buildPolicyItem(context, localizations.bonus_candy_policy_1),
        _buildPolicyItem(context, localizations.bonus_candy_policy_2),
        _buildPolicyItem(context, localizations.bonus_candy_policy_3),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildSimplifiedExpirationTable(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          _buildTableRow(
            context,
            localizations.bonus_candy_expiration_policy_earn_period,
            localizations.bonus_candy_expiration_policy_expiration_date,
            isHeader: true,
          ),
          Divider(color: AppColors.grey300, height: 12.h),
          _buildCustomTableRow(
            context,
            localizations.bonus_candy_earn_period_1_to_14,
            localizations.bonus_candy_expiration_next_month,
          ),
          Divider(color: AppColors.grey300, height: 12.h),
          _buildCustomTableRow(
            context,
            localizations.bonus_candy_earn_period_15_to_end,
            localizations.bonus_candy_expiration_month_after_next,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTableRow(BuildContext context, String left, String right) {
    final style = getTextStyle(AppTypo.caption10SB, AppColors.grey800);
    final boldStyle = style.copyWith(fontWeight: FontWeight.bold);

    Widget buildRichText(String text) {
      final spans = <TextSpan>[];
      final parts = text.split(' ');
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isDatePart = part.contains('일') || part.contains('말일');

        // Add space if it's not the last part
        final textWithSpace = i < parts.length - 1 ? '$part ' : part;

        spans.add(
          TextSpan(text: textWithSpace, style: isDatePart ? boldStyle : style),
        );
      }
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: spans),
      );
    }

    final leftParts = left.split('~');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildRichText(leftParts[0].trim()),
                  if (leftParts.length > 1)
                    buildRichText('~ ${leftParts[1].trim()}'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: buildRichText(right),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTable(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final currentMonth = now.month.toString();
    final nextMonth = (now.month % 12 + 1).toString();
    final afterNextMonth = (now.month % 12 + 2).toString();

    final example1Earn = localizations.bonus_candy_example_1_earn.replaceAll(
      '__MONTH__',
      currentMonth,
    );
    final example1Expire = localizations.bonus_candy_example_1_expire
        .replaceAll('__NEXT_MONTH__', nextMonth);
    final example2Earn = localizations.bonus_candy_example_2_earn.replaceAll(
      '__MONTH__',
      currentMonth,
    );
    final example2Expire = localizations.bonus_candy_example_2_expire
        .replaceAll('__THE_MONTH_AFTER_NEXT__', afterNextMonth);

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          _buildTableRow(
            context,
            localizations.bonus_candy_example_earn_date,
            localizations.bonus_candy_example_expiration_date,
            isHeader: true,
          ),
          Divider(color: AppColors.grey300, height: 12.h),
          _buildExampleTableRow(context, example1Earn, example1Expire),
          Divider(color: AppColors.grey300, height: 12.h),
          _buildExampleTableRow(context, example2Earn, example2Expire),
        ],
      ),
    );
  }

  Widget _buildExampleTableRow(
    BuildContext context,
    String left,
    String right,
  ) {
    Widget buildRichText(String text) {
      final parts = text.split(' ');
      final spans = <TextSpan>[];

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        final isDate = RegExp(r'^\d+일$').hasMatch(part);
        spans.add(
          TextSpan(
            text: '$part ',
            style: getTextStyle(
              AppTypo.caption10SB,
              AppColors.grey800,
            ).copyWith(fontWeight: isDate ? FontWeight.bold : null),
          ),
        );
      }

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: spans),
      );
    }

    return Row(
      children: [
        Expanded(child: buildRichText(left)),
        Expanded(child: buildRichText(right)),
      ],
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    String left,
    String right, {
    bool isHeader = false,
  }) {
    final style = getTextStyle(
      isHeader ? AppTypo.body14B : AppTypo.caption12M,
      AppColors.grey800,
    );
    return Row(
      children: [
        Expanded(
          child: Text(left, style: style, textAlign: TextAlign.center),
        ),
        Expanded(
          child: Text(right, style: style, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildPolicyItem(
    BuildContext context,
    String text, {
    bool isTitle = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: getTextStyle(
          isTitle ? AppTypo.body14B : AppTypo.caption10SB,
          isTitle ? AppColors.grey800 : AppColors.grey700,
        ).copyWith(fontWeight: isTitle ? FontWeight.bold : null),
      ),
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
