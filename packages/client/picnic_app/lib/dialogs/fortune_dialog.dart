import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/dialogs/fullscreen_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/fortune.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

import '../providers/community/fortune_provider.dart';

class FortuneDialogConstants {
  static const double closeButtonSize = 48;
  static const Duration transitionDuration = Duration(milliseconds: 300);
}

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
  _FortunePageState createState() => _FortunePageState();
}

class _FortunePageState extends ConsumerState<FortunePage> {
  @override
  Widget build(BuildContext context) {
    final fortuneAsync = ref.watch(getFortuneProvider(
      artistId: widget.artistId,
      year: widget.year,
      language: Intl.getCurrentLocale(),
    ));

    return FullScreenDialog(
      child: fortuneAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
        ),
        error: (error, stackTrace) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ],
        ),
        data: (fortune) => Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopSection(fortune),
                  _buildHeaderSection(fortune),
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Colors.pink[400],
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: Colors.pink[400],
                          tabs: [
                            Tab(text: S.of(context).fortune_total_title),
                            Tab(text: S.of(context).fortune_monthly),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height -
                              400, // 상단 영역을 제외한 높이
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(
                                child: _buildOverallFortune(fortune),
                              ),
                              SingleChildScrollView(
                                child: _buildMonthlyFortune(fortune),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 50,
              right: 15,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: FortuneDialogConstants.closeButtonSize,
                  height: FortuneDialogConstants.closeButtonSize,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallFortune(FortuneModel fortune) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAspectSection(
              '💝 ${S.of(context).fortune_love}', fortune.aspects.love),
          _buildAspectSection(
              '💼 ${S.of(context).fortune_career}', fortune.aspects.career),
          _buildAspectSection(
              '💪 ${S.of(context).fortune_health}', fortune.aspects.health),
          _buildAspectSection(
              '💰 ${S.of(context).fortune_money}', fortune.aspects.finances),
          _buildAspectSection('👥 ${S.of(context).fortune_relationship}',
              fortune.aspects.relationships),
          const SizedBox(height: 20),
          _buildLuckySection(fortune),
          const SizedBox(height: 20),
          _buildAdviceSection(fortune),
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
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                getMonthName(monthData.month),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthData.summary,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.pink[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMonthlyAspect('💝', monthData.love),
                      _buildMonthlyAspect('💼', monthData.career),
                      _buildMonthlyAspect('💪', monthData.health),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderSection(FortuneModel fortune) {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary500,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        fortune.overallLuck,
        style: getTextStyle(AppTypo.body14B, AppColors.grey900),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTopSection(FortuneModel fortune) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          SizedBox.expand(
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
                width: MediaQuery.of(context).size.width.toInt(),
                height: MediaQuery.of(context).size.width.toInt(),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 48,
              margin: EdgeInsets.symmetric(horizontal: 30.cw),
              child: VoteCommonTitle(
                title:
                    '${getLocaleTextFromJson(fortune.artist.name)} ${Intl.message('fortune_title', args: [
                      fortune.year.toString()
                    ])}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
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
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckySection(FortuneModel fortune) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ ${S.of(context).fortune_lucky_keyword}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildLuckyRow(
              S.of(context).fortune_lucky_days, fortune.lucky.days.join(', ')),
          _buildLuckyRow(S.of(context).fortune_lucky_color,
              fortune.lucky.colors.join(', ')),
          _buildLuckyRow(S.of(context).fortune_lucky_number,
              fortune.lucky.numbers.map((e) => e.toString()).join(', ')),
          _buildLuckyRow(S.of(context).fortune_lucky_direction,
              fortune.lucky.directions.join(', ')),
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(content),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(FortuneModel fortune) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 ${S.of(context).fortune_advice}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...fortune.advice.map((advice) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
      ],
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
