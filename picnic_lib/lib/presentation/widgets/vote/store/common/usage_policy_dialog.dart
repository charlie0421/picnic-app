import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/ui/style.dart';

Future<void> showUsagePolicyDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const UsagePolicyPopup();
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
    final expireBonusResult = ref.watch(expireBonusProvider);

    return LargePopupWidget(
      titleWidget: VoteCommonTitle(
        title: localizations.expiring_soon_bonus_candy,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: expireBonusResult.when(
          data: (data) => _buildPolicyContent(context, data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
              child:
                  Text(localizations.bonus_candy_expiration_policy_load_fail)),
        ),
      ),
    );
  }

  Widget _buildPolicyContent(
      BuildContext context, List<Map<String, dynamic>?>? expiringData) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w).copyWith(
          top: 60.h,
          bottom: 24.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expiringData != null && expiringData.isNotEmpty) ...[
              _buildExpiringBonusSection(context, expiringData),
              SizedBox(height: 20.h),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: _buildPolicyDetailsSection(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringBonusSection(
      BuildContext context, List<Map<String, dynamic>?> expiringData) {
    final localizations = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,###');

    return Container(
      padding: EdgeInsets.all(16.r),
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
                'assets/icons/store/bonus.png',
                width: 24.w,
                height: 24.w,
                package: 'picnic_lib',
              ),
              SizedBox(width: 8.w),
              Text(
                localizations.expiring_soon_bonus_candy,
                style: getTextStyle(
                  AppTypo.body16B,
                  AppColors.primary500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...expiringData.map((e) {
            if (e == null) return const SizedBox.shrink();
            final amount = e['expiring_amount'] ?? 0;
            return Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${e['prediction_month']}-15',
                    style: getTextStyle(
                      AppTypo.body14R,
                      AppColors.grey700,
                    ),
                  ),
                  Text(
                    numberFormat.format(amount),
                    style: getTextStyle(
                      AppTypo.body14B,
                      AppColors.primary500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPolicyDetailsSection(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPolicyItem(
          context,
          localizations.bonus_candy_expiration_time_title,
          isTitle: true,
        ),
        SizedBox(height: 4.h),
        _buildSimplifiedExpirationTable(context),
        SizedBox(height: 12.h),
        SizedBox(height: 12.h),
        _buildPolicyItem(
          context,
          localizations.bonus_candy_policy_title,
          isTitle: true,
        ),
        _buildPolicyItem(context, localizations.bonus_candy_policy_1),
        _buildPolicyItem(context, localizations.bonus_candy_policy_2),
        _buildPolicyItem(context, localizations.bonus_candy_policy_3),
        _buildPolicyItem(
          context,
          localizations.bonus_candy_example_title,
          isTitle: true,
        ),
        SizedBox(height: 4.h),
        _buildExampleTable(context),
      ],
    );
  }

  Widget _buildSimplifiedExpirationTable(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
            localizations.bonus_candy_expiration_policy_earn_period,
            localizations.bonus_candy_expiration_policy_expiration_date,
            isHeader: true,
          ),
          Divider(color: AppColors.grey300, height: 12.h),
          _buildTableRow(
            context,
            localizations.bonus_candy_earn_period_1_to_15,
            localizations.bonus_candy_expiration_next_month,
          ),
          Divider(color: AppColors.grey300, height: 12.h),
          _buildTableRow(
            context,
            localizations.bonus_candy_earn_period_16_to_end,
            localizations.bonus_candy_expiration_month_after_next,
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTable(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
          _buildTableRow(
            context,
            localizations.bonus_candy_example_1_earn,
            localizations.bonus_candy_example_1_expire,
          ),
          Divider(color: AppColors.grey300, height: 12.h),
          _buildTableRow(
            context,
            localizations.bonus_candy_example_2_earn,
            localizations.bonus_candy_example_2_expire,
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, String left, String right,
      {bool isHeader = false}) {
    final style = getTextStyle(
      isHeader ? AppTypo.body14B : AppTypo.caption12M,
      AppColors.grey800,
    );
    return Row(
      children: [
        Expanded(child: Text(left, style: style, textAlign: TextAlign.center)),
        Expanded(child: Text(right, style: style, textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildPolicyItem(BuildContext context, String text,
      {bool isTitle = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: getTextStyle(
          isTitle ? AppTypo.body14B : AppTypo.caption12M,
          isTitle ? AppColors.grey800 : AppColors.grey700,
        ),
      ),
    );
  }
}
