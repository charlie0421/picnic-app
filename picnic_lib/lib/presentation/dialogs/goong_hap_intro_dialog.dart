import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/ui/style.dart';

/// Shows the Goong-Hap introduction dialog explaining Korean traditional compatibility culture.
void showGoongHapIntroDialog() {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    useRootNavigator: false,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: const Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(24),
            child: GoongHapIntroContent(),
          ),
        ),
      );
    },
  );
}

class GoongHapIntroContent extends StatelessWidget {
  const GoongHapIntroContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              _buildHeader(l10n),
              // Wave divider
              _buildWaveDivider(),
              // Content sections (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  child: _buildContent(l10n),
                ),
              ),
              // Close button
              _buildCloseButton(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500,
            AppColors.secondary500,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative emojis
          const Positioned(
            top: 0,
            left: 0,
            child: Text('✨', style: TextStyle(fontSize: 20)),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: Text('💜', style: TextStyle(fontSize: 16)),
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            child: Text('⭐', style: TextStyle(fontSize: 14)),
          ),
          // Title content - 한글 → 중국어 → 영어 순서 (국제화 X)
          Center(
            child: Column(
              children: [
                // 한글 궁합 (가장 큼)
                Text(
                  '궁합',
                  style: getTextStyle(AppTypo.title18B, Colors.white).copyWith(
                    fontSize: 28,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                // 중국어 宮合
                Text(
                  '宮合',
                  style: getTextStyle(AppTypo.body16B, Colors.white.withValues(alpha: 0.9)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                // 영어 Goong-Hap
                Text(
                  'Goong-Hap',
                  style: getTextStyle(AppTypo.body14R, Colors.white.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.goong_hap_subtitle} 💫',
                  style: getTextStyle(
                    AppTypo.body14R,
                    Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveDivider() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: ClipPath(
        clipper: WaveClipper(),
        child: Container(
          height: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          // Tradition section
          _buildInfoSection(
              icon: '🏯',
              iconBgColor: AppColors.primary500.withValues(alpha: 0.2),
              title: l10n.goong_hap_tradition_title,
              description: l10n.goong_hap_tradition_desc,
            ),
            const SizedBox(height: 16),
            // K-POP section
            _buildInfoSection(
              icon: '🎤',
              iconBgColor: AppColors.secondary500.withValues(alpha: 0.2),
              title: l10n.goong_hap_kpop_title,
              description: '${l10n.goong_hap_kpop_desc} 🌟',
            ),
            const SizedBox(height: 16),
            // Fun section
            _buildInfoSection(
              icon: '💕',
              iconBgColor: AppColors.point500.withValues(alpha: 0.2),
              title: l10n.goong_hap_fun_title,
              description: '${l10n.goong_hap_fun_desc} 😆',
            ),
            const SizedBox(height: 16),
            // Zodiac section
            _buildInfoSection(
              icon: '🐲',
              iconBgColor: Colors.amber.withValues(alpha: 0.2),
              title: l10n.goong_hap_zodiac_title,
              description: l10n.goong_hap_zodiac_desc,
            ),
            const SizedBox(height: 16),
            // Zodiac animals list
            _buildZodiacAnimals(l10n),
            const SizedBox(height: 16),
            // Notice
            _buildNotice(l10n),
          ],
        ),
    );
  }

  Widget _buildInfoSection({
    required String icon,
    required Color iconBgColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: getTextStyle(AppTypo.body14B, AppColors.grey900),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZodiacAnimals(AppLocalizations l10n) {
    final animals = [
      l10n.goong_hap_zodiac_rat,
      l10n.goong_hap_zodiac_ox,
      l10n.goong_hap_zodiac_tiger,
      l10n.goong_hap_zodiac_rabbit,
      l10n.goong_hap_zodiac_dragon,
      l10n.goong_hap_zodiac_snake,
      l10n.goong_hap_zodiac_horse,
      l10n.goong_hap_zodiac_sheep,
      l10n.goong_hap_zodiac_monkey,
      l10n.goong_hap_zodiac_rooster,
      l10n.goong_hap_zodiac_dog,
      l10n.goong_hap_zodiac_pig,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            l10n.goong_hap_zodiac_subtitle,
            style: getTextStyle(AppTypo.caption12B, AppColors.grey700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: animals.map((animal) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  animal,
                  style: getTextStyle(AppTypo.caption10R, AppColors.grey600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Text(
        '🔮 ${l10n.goong_hap_notice} ✨',
        style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          l10n.goong_hap_close_button,
          style: getTextStyle(AppTypo.body14B, Colors.white),
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);

    // Create wave effect
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
