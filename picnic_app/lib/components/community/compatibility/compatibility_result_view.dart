import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_tip_card.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/ui/style.dart';

class CompatibilityResultView extends ConsumerWidget {
  const CompatibilityResultView({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String language = Intl.getCurrentLocale();

    if (compatibility.localizedResults?.isEmpty ?? true) {
      return Center(
        child: Text(
          S.of(context).compatibility_result_not_found,
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    final localizedResult = compatibility.getLocalizedResult(language) ??
        compatibility.localizedResults?.values.firstOrNull;

    if (localizedResult == null) {
      return Center(
        child: Text(
          S.of(context).compatibility_result_not_found,
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    final style = localizedResult.details?.style;
    final activities = localizedResult.details?.activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Section
        if (localizedResult.compatibilitySummary.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          color: AppColors.primary500),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).compatibility_summary_title,
                        style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizedResult.compatibilitySummary,
                    style: getTextStyle(AppTypo.body14R, AppColors.grey900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Style Section
        if (style != null) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.style_outlined,
                          color: AppColors.primary500),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).compatibility_style_title,
                        style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStyleItem(
                    context,
                    S.of(context).compatibility_idol_style,
                    style.idolStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildStyleItem(
                    context,
                    S.of(context).compatibility_user_style,
                    style.userStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildStyleItem(
                    context,
                    S.of(context).compatibility_couple_style,
                    style.coupleStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Activities Section
        if (activities != null) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_activity_outlined,
                          color: AppColors.primary500),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).compatibility_activities_title,
                        style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activities.description,
                    style: getTextStyle(AppTypo.body14R, AppColors.grey900),
                  ),
                  if (activities.recommended.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activities.recommended.map((activity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary500,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            activity,
                            style: getTextStyle(
                              AppTypo.body14M,
                              AppColors.grey00,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Tips Section
        if (localizedResult.tips.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: AppColors.primary500),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).compatibility_tips_title,
                        style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: localizedResult.tips.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return CompatibilityTipCard(
                        tip: localizedResult.tips[index],
                        index: index + 1,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStyleItem(BuildContext context, String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: getTextStyle(AppTypo.caption12M, AppColors.grey600),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: getTextStyle(AppTypo.body14R, AppColors.grey900),
        ),
      ],
    );
  }
}
