import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebDownloadSection extends ConsumerWidget {
  const WebDownloadSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isMobile) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 상단 앱 정보 섹션
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Download Picnic App',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Experience the full features on your mobile device',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // 스크린샷 스와이퍼 섹션
              Expanded(
                flex: 3,
                child: Swiper(
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/web/screenshot_${index + 1}.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                  itemCount: 3,
                  scale: 0.9,
                  viewportFraction: 0.85,
                  autoplay: true,
                  autoplayDelay: 5000,
                  duration: 800,
                  curve: Curves.easeInOutCubic,
                  pagination: SwiperPagination(
                    margin: const EdgeInsets.only(bottom: 16),
                    builder: DotSwiperPaginationBuilder(
                      activeColor: Theme.of(context).primaryColor,
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      size: 8.0,
                      activeSize: 10.0,
                    ),
                  ),
                  control: SwiperControl(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    iconPrevious: Icons.chevron_left_rounded,
                    iconNext: Icons.chevron_right_rounded,
                    size: 24,
                  ),
                ),
              ),

              // 하단 다운로드 섹션
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AnimatedScale(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: 'https://picnic.fan/download.html',
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _AnimatedScale(
                      child: _StoreButton(
                        icon: 'assets/web/app-store-badge.png',
                        url: 'https://apps.apple.com/app/id6504887262',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _AnimatedScale(
                      child: _StoreButton(
                        icon: 'assets/web/google-play-badge.png',
                        url:
                            'https://play.google.com/store/apps/details?id=io.iconcasting.picnic.app&pcampaignid=web_share',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedScale extends StatefulWidget {
  final Widget child;

  const _AnimatedScale({required this.child});

  @override
  State<_AnimatedScale> createState() => _AnimatedScaleState();
}

class _AnimatedScaleState extends State<_AnimatedScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final String icon;
  final String url;

  const _StoreButton({
    required this.icon,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            icon,
            height: 48,
          ),
        ),
      ),
    );
  }
}
