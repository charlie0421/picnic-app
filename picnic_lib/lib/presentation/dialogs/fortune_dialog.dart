import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/community/fortune.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/dialogs/fullscreen_dialog.dart';
import 'package:picnic_lib/presentation/providers/community/fortune_provider.dart';
import 'package:picnic_lib/ui/style.dart';

showFortuneDialog(int artistId, int year) {
  final context = navigatorKey.currentContext;
  return showFullScreenDialog(
    context: context!,
    builder: (context) => FortunePage(artistId: artistId, year: year),
  );
}

class FortunePage extends ConsumerStatefulWidget {
  final int artistId;
  final int year;

  const FortunePage({super.key, required this.artistId, required this.year});

  @override
  ConsumerState createState() => _FortunePageState();
}

class _FortunePageState extends ConsumerState<FortunePage> {
  bool _showMonthly = false;
  final GlobalKey _saveKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  bool _isSaving = false;

  // ExpansionTile Controllers
  final overallController = ExpansionTileController();
  final luckyController = ExpansionTileController();
  final adviceController = ExpansionTileController();
  final Map<int, ExpansionTileController> monthControllers = {};
  bool _wasOverallExpanded = false;
  bool _wasLuckyExpanded = false;
  bool _wasAdviceExpanded = false;
  final Map<int, bool> _wasMonthExpanded = {};

  @override
  void initState() {
    super.initState();
    // Initialize monthly controllers
    for (int i = 1; i <= 12; i++) {
      monthControllers[i] = ExpansionTileController();
    }
  }

  // ExpansionTile 상태 저장 메서드
  void _saveExpansionStates() {
    try {
      if (_showMonthly) {
        for (int i = 1; i <= 12; i++) {
          _wasMonthExpanded[i] = monthControllers[i]?.isExpanded ?? false;
        }
      } else {
        _wasOverallExpanded = overallController.isExpanded;
        _wasLuckyExpanded = luckyController.isExpanded;
        _wasAdviceExpanded = adviceController.isExpanded;
      }
    } catch (e, s) {
      logger.e('Error while saving expansion states $e', stackTrace: s);
    }
  }

  // 모든 ExpansionTile 펼치기
  void _expandAll() {
    try {
      if (_showMonthly) {
        monthControllers.forEach((_, controller) => controller.expand());
      } else {
        overallController.expand();
        luckyController.expand();
        adviceController.expand();
      }
    } catch (e, s) {
      logger.e('Error while expanding all $e', stackTrace: s);
    }
  }

  // ExpansionTile 상태 복원
  void _restoreExpansionStates() {
    try {
      if (_showMonthly) {
        monthControllers.forEach((month, controller) {
          if (_wasMonthExpanded[month] ?? false) {
            controller.expand();
          } else {
            controller.collapse();
          }
        });
      } else {
        if (_wasOverallExpanded) {
          overallController.expand();
        } else {
          overallController.collapse();
        }
        if (_wasLuckyExpanded) {
          luckyController.expand();
        } else {
          luckyController.collapse();
        }
        if (_wasAdviceExpanded) {
          adviceController.expand();
        } else {
          adviceController.collapse();
        }
      }
    } catch (e, s) {
      logger.e('Error while restoring expansion states $e', stackTrace: s);
    }
  }

  Future<void> _handleSave() async {
    try {
      await ShareUtils.saveImage(
        _saveKey,
        onStart: () {
          setState(() => _isSaving = true);
          OverlayLoadingProgress.start(context, color: AppColors.primary500);

          _saveExpansionStates();

          _expandAll();
        },
        onComplete: () {
          _restoreExpansionStates();
          OverlayLoadingProgress.stop();
          setState(() {
            _isSaving = false;
          });
        },
      );
    } catch (e, s) {
      logger.e('Error while capturing and saving $e', stackTrace: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fortuneAsync = ref.watch(getFortuneProvider(
      artistId: widget.artistId,
      year: widget.year,
      language: getLocaleLanguage(),
    ));

    return FullScreenDialog(
      child: fortuneAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink))),
        error: (error, stackTrace) => _buildError(error),
        data: (fortune) => DefaultTabController(
          length: 2,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  key: _saveKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopSection(fortune),
                      _buildHeaderSection(fortune),
                      TabBar(
                        labelColor: AppColors.grey900,
                        labelStyle:
                            getTextStyle(AppTypo.body14B, AppColors.grey900),
                        unselectedLabelStyle:
                            getTextStyle(AppTypo.body14R, AppColors.grey600),
                        unselectedLabelColor: AppColors.grey600,
                        indicatorColor: AppColors.grey900,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        onTap: (index) =>
                            setState(() => _showMonthly = index == 1),
                        tabs: [
                          Tab(text: S.of(context).fortune_total_title),
                          Tab(text: S.of(context).fortune_monthly),
                        ],
                      ),
                      _showMonthly
                          ? _buildMonthlyFortune(fortune)
                          : _buildOverallFortune(fortune),
                      if (!_isSaving)
                        ShareSection(
                          saveButtonText: S.of(context).save,
                          shareButtonText: S.of(context).share,
                          onSave: _handleSave,
                          onShare: () async {
                            if (_isSaving) return;
                            ShareUtils.shareToSocial(
                              _shareKey,
                              message: Intl.message(
                                  'compatibility_share_message',
                                  args: [
                                    getLocaleTextFromJson(fortune.artist.name)
                                  ]),
                              hashtag: S.of(context).fortune_share_hashtag,
                              downloadLink: await createBranchLink(
                                  getLocaleTextFromJson(fortune.artist.name),
                                  '${Environment.appLinkPrefix}/community/fortune/${widget.artistId}'),
                              onStart: () {
                                OverlayLoadingProgress.start(context,
                                    color: AppColors.primary500);
                                setState(() => _isSaving = true);
                              },
                              onComplete: () {
                                OverlayLoadingProgress.stop();
                                setState(() => _isSaving = false);
                              },
                            );
                          },
                        ),
                      SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallFortune(FortuneModel fortune) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: ExpansionTile(
              controller: overallController,
              initiallyExpanded: true,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                '🔮 ${S.of(context).fortune_total_title}',
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
              children: [
                InkWell(
                  onTap: () => overallController.collapse(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAspectSection('💝 ${S.of(context).fortune_honor}',
                            fortune.aspects.honor),
                        _buildAspectSection(
                            '💼 ${S.of(context).fortune_career}',
                            fortune.aspects.career),
                        _buildAspectSection(
                            '💪 ${S.of(context).fortune_health}',
                            fortune.aspects.health),
                        _buildAspectSection('💰 ${S.of(context).fortune_money}',
                            fortune.aspects.finances),
                        _buildAspectSection(
                            '👥 ${S.of(context).fortune_relationship}',
                            fortune.aspects.relationships),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: ExpansionTile(
              controller: luckyController,
              initiallyExpanded: false,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                '✨ ${S.of(context).fortune_lucky_keyword}',
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
              children: [
                InkWell(
                  onTap: () => luckyController.collapse(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildLuckyRow(S.of(context).fortune_lucky_days,
                            fortune.lucky.days.join(', ')),
                        _buildLuckyRow(S.of(context).fortune_lucky_color,
                            fortune.lucky.colors.join(', ')),
                        _buildLuckyRow(
                            S.of(context).fortune_lucky_number,
                            fortune.lucky.numbers
                                .map((e) => e.toString())
                                .join(', ')),
                        _buildLuckyRow(S.of(context).fortune_lucky_direction,
                            fortune.lucky.directions.join(', ')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: ExpansionTile(
              controller: adviceController,
              initiallyExpanded: false,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                '💡 ${S.of(context).fortune_advice}',
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
              children: [
                InkWell(
                  onTap: () => adviceController.collapse(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: fortune.advice
                          .map((advice) => Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: getTextStyle(
                                        AppTypo.caption12B, AppColors.grey900),
                                  ),
                                  Expanded(
                                    child: Text(
                                      advice,
                                      style: getTextStyle(AppTypo.caption12B,
                                          AppColors.grey900),
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFortune(FortuneModel fortune) {
    final sortedMonthlyFortunes = List.of(fortune.monthlyFortunes)
      ..sort((a, b) => a.month.compareTo(b.month));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sortedMonthlyFortunes.map((monthData) {
          return Card(
            elevation: 2,
            child: ExpansionTile(
              controller: monthControllers[monthData.month],
              initiallyExpanded: false,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                getMonthName(monthData.month),
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              ),
              children: [
                InkWell(
                  onTap: () => monthControllers[monthData.month]?.collapse(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthData.summary,
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.point900),
                        ),
                        const SizedBox(height: 12),
                        _buildMonthlyAspect('💝', monthData.honor),
                        _buildMonthlyAspect('💼', monthData.career),
                        _buildMonthlyAspect('💪', monthData.health),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopSection(FortuneModel fortune) {
    final screenWidth = MediaQuery.of(context).size.width;

    return RepaintBoundary(
      key: _shareKey,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          SizedBox(
            width: screenWidth,
            height: screenWidth,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.7, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: PicnicCachedNetworkImage(
                imageUrl: fortune.artist.image ?? '',
                fit: BoxFit.cover,
                width: (screenWidth * 1.1),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SvgPicture.asset(
                  package: 'picnic_lib',
                  'assets/icons/fortune/fortune_teller_title.svg',
                  width: 283.cw,
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      package: 'picnic_lib',
                      'assets/icons/play_style=fill.svg',
                      width: 16.cw,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                          AppColors.primary500, BlendMode.srcIn),
                    ),
                    SizedBox(width: 8),
                    Text(
                      getLocaleTextFromJson(fortune.artist.name),
                      style:
                          getTextStyle(AppTypo.title18B, AppColors.primary500)
                              .copyWith(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Transform.rotate(
                      angle: 3.14,
                      child: SvgPicture.asset(
                        package: 'picnic_lib',
                        'assets/icons/play_style=fill.svg',
                        width: 16.cw,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          AppColors.primary500,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(FortuneModel fortune) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 0),
            child: Text(
              fortune.overallLuck,
              style: getTextStyle(AppTypo.body14R, AppColors.grey900),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/fortune/quote_open.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey900, BlendMode.srcIn),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 0,
            child: SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/fortune/quote_close.svg',
              width: 20,
              colorFilter: ColorFilter.mode(AppColors.grey900, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(dynamic error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 60),
        const SizedBox(height: 16),
        Text(
          S.of(context).message_error_occurred,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAspectSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyAspect(String emoji, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              content,
              style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyRow(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  String getMonthName(int month) {
    switch (month) {
      case 1:
        return S.of(context).fortune_month1;
      case 2:
        return S.of(context).fortune_month2;
      case 3:
        return S.of(context).fortune_month3;
      case 4:
        return S.of(context).fortune_month4;
      case 5:
        return S.of(context).fortune_month5;
      case 6:
        return S.of(context).fortune_month6;
      case 7:
        return S.of(context).fortune_month7;
      case 8:
        return S.of(context).fortune_month8;
      case 9:
        return S.of(context).fortune_month9;
      case 10:
        return S.of(context).fortune_month10;
      case 11:
        return S.of(context).fortune_month11;
      case 12:
        return S.of(context).fortune_month12;
      default:
        return '';
    }
  }
}
