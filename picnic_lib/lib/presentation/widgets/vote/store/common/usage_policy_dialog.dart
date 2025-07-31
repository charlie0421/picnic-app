import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
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
      title: localizations.bonus_candy_expiration_policy_title,
      content: expireBonusResult.when(
        data: (data) => _buildPolicyContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('소멸 예정 보너스 정보를 불러오는데 실패했습니다.')),
      ),
    );
  }

  Widget _buildPolicyContent(
      BuildContext context, List<Map<String, dynamic>?>? expiringData) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final day = now.day;

    DateTime earnStartDate;
    DateTime earnEndDate;
    DateTime expirationDate;

    if (day <= 15) {
      earnStartDate = DateTime(now.year, now.month, 1);
      earnEndDate = DateTime(now.year, now.month, 15);
      expirationDate = DateTime(now.year, now.month + 1, 15);
    } else {
      earnStartDate = DateTime(now.year, now.month, 16);
      earnEndDate = DateTime(
          now.year, now.month, DateUtils.getDaysInMonth(now.year, now.month));
      expirationDate = DateTime(now.year, now.month + 2, 15);
    }

    final dateFormat = DateFormat('M/d', localizations.localeName);
    final expirationDateFormat = DateFormat('M/d', localizations.localeName);

    final exampleText = localizations.bonus_candy_expiration_policy_example(
      dateFormat.format(earnStartDate),
      dateFormat.format(earnEndDate),
      expirationDateFormat.format(expirationDate),
    );

    final policies = [
      localizations.bonus_candy_expiration_policy_target_title,
      localizations.bonus_candy_expiration_policy_target_description,
      localizations.bonus_candy_expiration_policy_date_title,
      localizations.bonus_candy_expiration_policy_date_description,
      localizations.bonus_candy_expiration_policy_rules_title,
      localizations.bonus_candy_expiration_policy_rule1,
      localizations.bonus_candy_expiration_policy_rule2,
      localizations.bonus_candy_expiration_policy_example_title,
      exampleText,
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.only(
          top: 60.h,
          bottom: 30.h,
          left: 24.w,
          right: 24.w,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expiringData != null && expiringData.isNotEmpty) ...[
                ...expiringData
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${e!['prediction_month']}-15: ',
                                style: getTextStyle(
                                  AppTypo.body14B,
                                  AppColors.point900,
                                ),
                              ),
                              Text(
                                '${e['expiring_amount'] ?? 0}',
                                style: getTextStyle(
                                  AppTypo.body14B,
                                  AppColors.point900,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                SizedBox(height: 16.h),
              ],
              ...policies.map((policy) {
                final isTitle = policy.endsWith(':');
                return Padding(
                  padding: EdgeInsets.only(bottom: isTitle ? 4.h : 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isTitle)
                        Text(
                          '• ',
                          style: getTextStyle(
                            AppTypo.body14R,
                            AppColors.grey800,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          policy,
                          style: getTextStyle(
                            isTitle ? AppTypo.body14B : AppTypo.body14R,
                            AppColors.grey800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
