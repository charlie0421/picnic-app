import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class CandyBoostBanner extends ConsumerWidget {
  const CandyBoostBanner({super.key, required this.creative});
  final PromotionCreativeModel creative;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final image = creative.localizedImage(locale)!;
    final title = creative.localizedTitle(locale)!;
    return GestureDetector(
      onTap: creative.link == null
          ? null
          : () async {
              final uri = Uri.parse(creative.link!);
              if (uri.scheme == 'http' || uri.scheme == 'https') {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                await AppInitializer.handleDeepLink(ref, creative.link!);
              }
            },
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.centerLeft,
        children: [
          PicnicCachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xD9A52D5E),
                  Color(0xA6D94D7D),
                  Color(0x00000000),
                ],
                stops: [0, 0.48, 0.82],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: getTextStyle(AppTypo.title18B, Colors.white).copyWith(
                  shadows: const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 5,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
