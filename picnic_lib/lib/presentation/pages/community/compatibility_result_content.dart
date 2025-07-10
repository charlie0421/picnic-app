import 'dart:ui';

import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilityResultContent extends ConsumerStatefulWidget {
  const CompatibilityResultContent({
    super.key,
    required this.compatibility,
    required this.isSaving,
    required this.onSave,
    required this.onShare,
    required this.onOpenCompatibility,
  });

  final CompatibilityModel compatibility;
  final bool isSaving;
  final Future<Future<bool>> Function(CompatibilityModel) onSave;
  final Future<Future<bool>> Function(CompatibilityModel) onShare;
  final Function(String) onOpenCompatibility;

  @override
  ConsumerState<CompatibilityResultContent> createState() =>
      _CompatibilityResultContentState();
}

class _CompatibilityResultContentState
    extends ConsumerState<CompatibilityResultContent> {
  late final ExpansibleController _styleController;
  late final ExpansibleController _activityController;
  late final ExpansibleController _tipController;
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
      GlobalKey<LoadingOverlayWithIconState>();

  // 🔧 스크롤 중 우발적 구매 방지 - 강화된 연타 방지
  DateTime? _lastStarPurchaseTime;
  static const Duration _purchaseCooldown =
      Duration(seconds: 1); // 300ms -> 1초로 증가

  @override
  void initState() {
    super.initState();
    _styleController = ExpansibleController();
    _activityController = ExpansibleController();
    _tipController = ExpansibleController();
  }

  // 🔒 구매 확인 다이얼로그 - 우발적 구매 방지
  Future<void> _showPurchaseConfirmDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(
                AppLocalizations.of(context)
                    .compatibility_purchase_confirm_title,
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context).compatibility_purchase_confirm_message,
            style: getTextStyle(AppTypo.body14R, AppColors.grey700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: getTextStyle(AppTypo.body14R, AppColors.grey500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
              child: Text(
                AppLocalizations.of(context).confirm,
                style: getTextStyle(AppTypo.body14B, Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _processPurchase();
    }
  }

  // 🎯 실제 구매 처리 로직
  Future<void> _processPurchase() async {
    _loadingKey.currentState?.show();
    try {
      widget.onOpenCompatibility(widget.compatibility.id);
    } finally {
      if (mounted) {
        _loadingKey.currentState?.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String language = getLocaleLanguage();

    if (widget.compatibility.localizedResults?.isEmpty ?? true) {
      return Center(
        child: Text(
          AppLocalizations.of(context).compatibility_result_not_found,
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    final localizedResult = widget.compatibility.getLocalizedResult(language) ??
        widget.compatibility.localizedResults?.values.firstOrNull;

    if (localizedResult == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).compatibility_result_not_found,
          style: getTextStyle(AppTypo.body14R, AppColors.grey500),
        ),
      );
    }

    final style = localizedResult.details?.style;
    final activities = localizedResult.details?.activities;
    final tips = localizedResult.tips;

    return LoadingOverlayWithIcon(
      key: _loadingKey,
      iconAssetPath: 'assets/app_icon_128.png',
      enableScale: true,
      enableFade: true,
      enableRotation: false,
      minScale: 0.98,
      maxScale: 1.02,
      showProgressIndicator: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!(widget.compatibility.isPaid ?? false))
            Stack(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      if (style != null) _buildStyleSection(style),
                      SizedBox(height: 36),
                      if (activities != null)
                        _buildActivitiesSection(activities),
                      SizedBox(height: 36),
                      if (tips.isNotEmpty) _buildTipsSection(tips),
                      if (!widget.isSaving)
                        ShareSection(
                          saveButtonText: AppLocalizations.of(context).save,
                          shareButtonText: AppLocalizations.of(context).share,
                          onSave: () => widget.onSave(widget.compatibility),
                          onShare: () => widget.onShare(widget.compatibility),
                        ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              BubbleBox(
                                backgroundColor: AppColors.grey00,
                                elevation: 2,
                                shape: BubbleShapeBorder(
                                  border: BubbleBoxBorder(
                                    color: AppColors.grey300,
                                    width: 1.5,
                                    style: BubbleBoxBorderStyle.solid,
                                  ),
                                  radius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  position: const BubblePosition.center(0),
                                  direction: BubbleDirection.bottom,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      package: 'picnic_lib',
                                      'assets/icons/store/star_100.png',
                                      width: 36,
                                    ),
                                    Text(
                                      '100',
                                      style: getTextStyle(
                                        AppTypo.body16B,
                                        AppColors.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                constraints: BoxConstraints(
                                  minWidth: 240,
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // 🔧 강화된 연타 방지
                                    if (_lastStarPurchaseTime != null) {
                                      final timeSince = DateTime.now()
                                          .difference(_lastStarPurchaseTime!);
                                      if (timeSince < _purchaseCooldown) {
                                        return;
                                      }
                                    }
                                    _lastStarPurchaseTime = DateTime.now();

                                    // 🔒 구매 확인 다이얼로그 표시
                                    await _showPurchaseConfirmDialog();
                                  },
                                  child: Text(AppLocalizations.of(context)
                                      .fortune_purchase_by_star_candy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            if (style != null) _buildStyleSection(style),
            SizedBox(height: 36),
            if (activities != null) _buildActivitiesSection(activities),
            SizedBox(height: 36),
            if (tips.isNotEmpty) _buildTipsSection(tips),
            if (!widget.isSaving)
              ShareSection(
                saveButtonText: AppLocalizations.of(context).save,
                shareButtonText: AppLocalizations.of(context).share,
                onSave: () => widget.onSave(widget.compatibility),
                onShare: () => widget.onShare(widget.compatibility),
              ),
            SizedBox(height: 16),
          ],
        ],
      ),
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

  Widget _buildStyleSection(StyleDetails style) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: SizedBox(
          height: 28,
          child: Row(
            children: [
              SvgPicture.asset(
                package: 'picnic_lib',
                'assets/images/fortune/fortune_style.svg',
                width: 24,
                colorFilter: ColorFilter.mode(
                  AppColors.primary500,
                  BlendMode.srcIn,
                ),
              ),
              UnderlinedText(
                text:
                    ' ${AppLocalizations.of(context).compatibility_style_title}',
                textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
                underlineGap: 1.5,
              ),
            ],
          ),
        ),
        children: [
          InkWell(
            onTap: () => _styleController.collapse(),
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
                    AppLocalizations.of(context).compatibility_idol_style,
                    style.idolStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildStyleItem(
                    context,
                    AppLocalizations.of(context).compatibility_user_style,
                    style.userStyle,
                  ),
                  const SizedBox(height: 12),
                  _buildStyleItem(
                    context,
                    AppLocalizations.of(context).compatibility_couple_style,
                    style.coupleStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(ActivitiesDetails activities) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/images/fortune/fortune_activities.svg',
              width: 24,
              colorFilter: ColorFilter.mode(
                AppColors.primary500,
                BlendMode.srcIn,
              ),
            ),
            UnderlinedText(
              text:
                  ' ${AppLocalizations.of(context).compatibility_activities_title}',
              textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
              underlineGap: 1.5,
            ),
          ],
        ),
        children: [
          InkWell(
            onTap: () => _activityController.collapse(),
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
                    style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTipsSection(List<String> tips) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/images/fortune/fortune_tips.svg',
              width: 24,
              colorFilter: ColorFilter.mode(
                AppColors.primary500,
                BlendMode.srcIn,
              ),
            ),
            UnderlinedText(
              text: ' ${AppLocalizations.of(context).compatibility_tips_title}',
              textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
              underlineGap: 1.5,
            ),
          ],
        ),
        children: [
          InkWell(
            onTap: () => _tipController.collapse(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tips.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Text('✔️ ${tips[index]}',
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
    );
  }
}
