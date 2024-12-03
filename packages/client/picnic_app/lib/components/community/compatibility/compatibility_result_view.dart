import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/underlined_text.dart';
import 'package:picnic_app/components/common/underlined_widget.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_tip_card.dart';
import 'package:picnic_app/components/community/compatibility/fortune_divider.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/ui/style.dart';

class CompatibilityResultView extends ConsumerWidget {
  CompatibilityResultView({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;
  final styleController = ExpansionTileController();
  final activityController = ExpansionTileController();
  final tipController = ExpansionTileController();

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
        SizedBox(
          height: 36,
        ),
        _buildHeaderSection(localizedResult),
        FortuneDivider(color: AppColors.grey00),

        if (style != null) ...[
          Card(
            elevation: 2,
            child: ExpansionTile(
              controller: styleController,
              initiallyExpanded: true,
              shape: const Border(),
              collapsedShape: const Border(),
              title: SizedBox(
                height: 28,
                child: Row(
                  children: [
                    UnderlinedWidget(
                      underlineGap: 2,
                      child: SvgPicture.asset(
                        'assets/images/fortune/fortune_style.svg',
                        width: 24,
                        colorFilter: ColorFilter.mode(
                          AppColors.primary500,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    UnderlinedText(
                      text: ' ${S.of(context).compatibility_style_title}',
                      textStyle:
                          getTextStyle(AppTypo.body16B, AppColors.grey900),
                      underlineGap: 1.5,
                    ),
                  ],
                ),
              ),
              children: [
                InkWell(
                  onTap: () => styleController.collapse(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Activities Section
        if (activities != null) ...[
          Card(
            elevation: 2,
            child: ExpansionTile(
              controller: activityController,
              initiallyExpanded: true,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Row(
                children: [
                  UnderlinedWidget(
                    underlineGap: 2,
                    child: SvgPicture.asset(
                      'assets/images/fortune/fortune_activities.svg',
                      width: 24,
                      colorFilter: ColorFilter.mode(
                        AppColors.primary500,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  UnderlinedText(
                    text: ' ${S.of(context).compatibility_activities_title}',
                    textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
                    underlineGap: 1.5,
                  ),
                ],
              ),
              children: [
                InkWell(
                  onTap: () => activityController.collapse(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activities.recommended.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            return Text('✔️ ${activities.recommended[index]}',
                                style: getTextStyle(
                                  AppTypo.caption12B,
                                  AppColors.grey900,
                                ));
                          },
                        ),
                        Text(
                          activities.description.trim(),
                          style: getTextStyle(
                              AppTypo.caption12R, AppColors.grey900),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],

        // Tips Section
        if (localizedResult.tips.isNotEmpty) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              controller: tipController,
              initiallyExpanded: true,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Row(
                children: [
                  UnderlinedWidget(
                    underlineGap: 2,
                    child: SvgPicture.asset(
                      'assets/images/fortune/fortune_tips.svg',
                      width: 24,
                      colorFilter: ColorFilter.mode(
                        AppColors.primary500,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  UnderlinedText(
                    text: ' ${S.of(context).compatibility_tips_title}',
                    textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
                    underlineGap: 1.5,
                  ),
                ],
              ),
              children: [
                InkWell(
                  onTap: () => tipController.collapse(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: localizedResult.tips.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return Text('✔️ ${localizedResult.tips[index]}',
                                style: getTextStyle(
                                  AppTypo.caption12B,
                                  AppColors.grey900,
                                ));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(LocalizedCompatibility localizedResult) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 0),
            constraints: const BoxConstraints(minHeight: 60),
            child: Center(
              child: Text(
                localizedResult.compatibilitySummary,
                style: getTextStyle(AppTypo.body14R, AppColors.grey00),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            child: SvgPicture.asset(
              'assets/icons/fortune/quote_open.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey00, BlendMode.srcIn),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 0,
            child: SvgPicture.asset(
              'assets/icons/fortune/quote_close.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey00, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}
