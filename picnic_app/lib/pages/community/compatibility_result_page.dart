import 'dart:ui';

import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/underlined_text.dart';
import 'package:picnic_app/components/common/underlined_widget.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_error.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/components/community/compatibility/fortune_divider.dart';
import 'package:picnic_app/components/common/share_section.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/vote_share_util.dart';

class CompatibilityResultPage extends ConsumerStatefulWidget {
  const CompatibilityResultPage({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  ConsumerState<CompatibilityResultPage> createState() =>
      _CompatibilityResultPageState();
}

class _CompatibilityResultPageState
    extends ConsumerState<CompatibilityResultPage> {
  final GlobalKey _printKey = GlobalKey();
  final styleController = ExpansionTileController();
  final activityController = ExpansionTileController();
  final tipController = ExpansionTileController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      await ref
          .read(compatibilityProvider.notifier)
          .setCompatibility(widget.compatibility);

      if (widget.compatibility.isPending) {
        ref.read(compatibilityLoadingProvider.notifier).state = true;
      }

      if (widget.compatibility.isCompleted) {
        await _refreshData();
      }
    } catch (e, stack) {
      logger.e('Error initializing data', error: e, stackTrace: stack);
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    try {
      await ref
          .read(compatibilityProvider.notifier)
          .loadCompatibility(widget.compatibility.id);
    } catch (e, stack) {
      logger.e('Error refreshing compatibility data',
          error: e, stackTrace: stack);
    }
  }

  void _updateNavigation() {
    Future(() {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: TopRightType.board,
            showBottomNavigation: false,
            pageTitle: Intl.message('compatibility_page_title'),
          );
    });
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

  Widget _buildResultContent(CompatibilityModel compatibility) {
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
    final tips = localizedResult.tips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 36),
        _buildHeaderSection(localizedResult),
        FortuneDivider(color: AppColors.grey00),
        if (!(compatibility.isPaid ?? false))
          Stack(
            children: [
              Column(
                children: [
                  if (style != null) _buildStyleSection(style),
                  SizedBox(height: 36),
                  if (activities != null) _buildActivitiesSection(activities),
                  SizedBox(height: 36),
                  if (tips.isNotEmpty) _buildTipsSection(tips),
                  SizedBox(height: 36),
                ],
              ),
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(height: 32),
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
                                )),
                            SizedBox(height: 8),
                            Container(
                              constraints: BoxConstraints(
                                minWidth: 240,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  showSimpleDialog(
                                    title: S
                                        .of(context)
                                        .fortune_lack_of_star_candy_title,
                                    content: S
                                        .of(context)
                                        .fortune_lack_of_star_candy_message,
                                    onOk: () {
                                      // Add payment logic here
                                    },
                                  );
                                  // Add payment logic here
                                },
                                child: Text(S
                                    .of(context)
                                    .fortune_purchase_by_star_candy),
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              constraints: BoxConstraints(
                                minWidth: 240,
                              ),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                    padding: WidgetStateProperty.all(
                                        EdgeInsets.symmetric(
                                            horizontal: 32.cw, vertical: 0)),
                                    backgroundColor: WidgetStateProperty.all(
                                        AppColors.mint500),
                                    foregroundColor: WidgetStateProperty.all(
                                        AppColors.grey900),
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                            color: AppColors.primary500,
                                            width: 1,
                                            style: BorderStyle.solid),
                                      ),
                                    ),
                                    textStyle: WidgetStateProperty.all(
                                      getTextStyle(
                                        AppTypo.caption12B,
                                        AppColors.grey00,
                                      ),
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                onPressed: () {
                                  // Add payment logic here
                                },
                                child: Text(
                                    S.of(context).fortune_purchase_by_one_click,
                                    style: TextStyle(color: AppColors.grey900)),
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
          SizedBox(height: 36),
        ],
      ],
    );
  }

  Widget _buildStyleSection(StyleDetails style) {
    return Card(
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
                textStyle: getTextStyle(AppTypo.body16B, AppColors.grey900),
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
    );
  }

  Widget _buildActivitiesSection(ActivitiesDetails activities) {
    return Card(
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

  @override
  Widget build(BuildContext context) {
    final compatibilityState = ref.watch(compatibilityProvider);

    return compatibilityState.when(
      data: (compatibility) {
        if (compatibility == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary500.withOpacity(.7),
                  AppColors.mint500.withOpacity(.7),
                ],
              ),
            ),
            child: Column(
              children: [
                RepaintBoundary(
                  key: _printKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 20,
                        child: SvgPicture.asset(
                          'assets/images/fortune/picnic_logo.svg',
                          width: 78,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 16),
                      CompatibilityInfo(
                        artist: compatibility.artist,
                        ref: ref,
                        birthDate: compatibility.birthDate,
                        birthTime: compatibility.birthTime,
                        compatibility: compatibility,
                      ),
                      if (compatibility.hasError)
                        CompatibilityErrorView(
                          error: compatibility.errorMessage ??
                              S.of(context).error_unknown,
                        )
                      else if (compatibility.isCompleted)
                        _buildResultContent(compatibility)
                    ],
                  ),
                ),
                if (compatibility.isCompleted &&
                    compatibility.localizedResults != null) ...[
                  const SizedBox(height: 16),
                  ShareSection(
                    saveButtonText: S.of(context).save,
                    shareButtonText: S.of(context).share,
                    onSave: () => _handleSave(compatibility),
                    onShare: () => _handleShare(compatibility),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.of(context).compatibility_status_error,
              style: getTextStyle(AppTypo.body14M, AppColors.point500),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _refreshData,
              child: Text(S.of(context).label_retry),
            ),
          ],
        ),
      ),
    );
  }

  Future<Future<bool>> _handleSave(CompatibilityModel compatibility) async {
    return ShareUtils.captureAndSaveImage(
      _printKey,
      onStart: () {
        if (!mounted) return;
      },
      onComplete: () {
        if (!mounted) return;
      },
    );
  }

  Future<Future<bool>> _handleShare(CompatibilityModel compatibility) async {
    logger.i('Share to Twitter');
    return ShareUtils.shareToTwitter(
      _printKey,
      message: getLocaleTextFromJson(compatibility.artist.name),
      hashtag:
          '#Picnic #Vote #PicnicApp #${S.of(context).compatibility_page_title}',
      context,
      onStart: () {
        if (!mounted) return;
      },
      onComplete: () {
        if (!mounted) return;
      },
    );
  }
}
