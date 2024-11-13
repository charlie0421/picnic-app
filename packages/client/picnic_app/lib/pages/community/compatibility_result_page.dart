import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'dart:io';

import 'package:picnic_app/util/ui.dart';

class CompatibilityResultScreen extends ConsumerStatefulWidget {
  const CompatibilityResultScreen({
    super.key,
    required this.compatibilityId,
  });

  final String compatibilityId;

  @override
  ConsumerState<CompatibilityResultScreen> createState() =>
      _CompatibilityResultScreenState();
}

class _CompatibilityResultScreenState
    extends ConsumerState<CompatibilityResultScreen> {
  final GlobalKey _printKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCompatibility();
  }

  Future<void> _loadCompatibility() async {
    final compatibility = ref.read(compatibilityProvider);
    if (compatibility == null || compatibility.id != widget.compatibilityId) {
      try {
        await ref.read(compatibilityProvider.notifier).refreshCompatibility();
      } catch (e) {
        logger.e('Error loading compatibility', error: e);
      }
    }
  }

  Future<void> _captureAndSaveImage() async {
    try {
      // Capture the widget as an image
      RenderRepaintBoundary boundary =
          _printKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Get the app's local directory
        final directory = await getApplicationDocumentsDirectory();
        final imagePath =
            '${directory.path}/compatibility_${DateTime.now().millisecondsSinceEpoch}.png';

        // Write the file
        final file = File(imagePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지가 저장되었습니다: $imagePath')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compatibility = ref.watch(compatibilityProvider);

    if (compatibility == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${compatibility.artist.name['ko']}님과의 궁합'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _captureAndSaveImage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _printKey,
          child: switch (compatibility.status) {
            CompatibilityStatus.pending => const _LoadingView(),
            CompatibilityStatus.error => _ErrorView(
                error: compatibility.errorMessage ?? '알 수 없는 오류가 발생했습니다.',
              ),
            CompatibilityStatus.completed => _ResultView(
                compatibility: compatibility,
              ),
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> {
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _isTopBannerLoaded = false;
  bool _isBottomBannerLoaded = false;
  int _remainingSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAds();
    _startTimer();
  }

  @override
  void dispose() {
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _loadAds() {
    _topBannerAd = BannerAd(
      adUnitId: isAndroid()
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isTopBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();

    _bottomBannerAd = BannerAd(
      adUnitId: isAndroid()
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBottomBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isTopBannerLoaded && _topBannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _topBannerAd!.size.width.toDouble(),
              height: _topBannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _topBannerAd!),
            ),
          const SizedBox(height: 24),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
            value: _remainingSeconds / 30,
          ),
          const SizedBox(height: 24),
          Text(
            '궁합을 분석하고 있습니다...\n(${_remainingSeconds}초)',
            style: getTextStyle(AppTypo.body16B, AppColors.grey900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요',
            style: getTextStyle(AppTypo.body14M, AppColors.grey600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_isBottomBannerLoaded && _bottomBannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bottomBannerAd!.size.width.toDouble(),
              height: _bottomBannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bottomBannerAd!),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.point900,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: getTextStyle(AppTypo.body14M, AppColors.grey900),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 궁합 점수
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${compatibility.compatibilityScore}%',
                    style: getTextStyle(
                      AppTypo.title18B,
                      _getScoreColor(compatibility.compatibilityScore ?? 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    compatibility.compatibilitySummary ?? '',
                    textAlign: TextAlign.center,
                    style: getTextStyle(AppTypo.body16M, AppColors.grey900),
                  ),
                ],
              ),
            ),
          ),

          // 스타일 분석
          if (compatibility.style != null) ...[
            _buildSection(
              title: '스타일 분석',
              icon: Icons.style,
              child: Column(
                children: [
                  _buildDetailItem(
                    '${compatibility.artist.name['ko']}님의 스타일',
                    compatibility.style!.idol_style,
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    '당신의 스타일',
                    compatibility.style!.user_style,
                  ),
                  const Divider(height: 24),
                  _buildDetailItem(
                    '커플 스타일 제안',
                    compatibility.style!.couple_style,
                  ),
                ],
              ),
            ),
          ],

          // 추천 활동
          if (compatibility.activities != null) ...[
            _buildSection(
              title: '추천 활동',
              icon: Icons.local_activity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...compatibility.activities!.recommended.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: AppColors.primary500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activity,
                              style: getTextStyle(
                                  AppTypo.body14M, AppColors.grey900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (compatibility.activities!.description.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      compatibility.activities!.description,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // 궁합 높이기 팁
          if (compatibility.tips != null && compatibility.tips!.isNotEmpty)
            _buildSection(
              title: '궁합 높이기 팁',
              icon: Icons.tips_and_updates,
              child: Column(
                children: compatibility.tips!
                    .map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: AppColors.primary500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: getTextStyle(
                                    AppTypo.body14M, AppColors.grey900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary500),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: getTextStyle(AppTypo.body14B, AppColors.grey900),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: getTextStyle(AppTypo.body14M, AppColors.grey900),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.primary500;
    if (score >= 80) return const Color(0xFFFF9500);
    if (score >= 70) return const Color(0xFF34C759);
    return AppColors.grey600;
  }
}
