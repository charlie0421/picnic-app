import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class CandyBoostBanner extends ConsumerWidget {
  const CandyBoostBanner({super.key, required this.campaign});
  final ActivePromotionCampaignModel campaign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final creative = campaign.homeCreative!;
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
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: getTextStyle(AppTypo.title18B, Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
