import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/dialogs/fullscreen_dialog.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/util.dart';

// 상수 정의
class RewardDialogConstants {
  static const double imageRadius = 24;
  static const double topSectionHeight = 400;
  static const double closeButtonSize = 48;
  static const Duration transitionDuration = Duration(milliseconds: 300);
}

enum RewardType { overview, location, size_guide }

showRewardDialog(BuildContext context, RewardModel data) {
  return showFullScreenDialog(
    context: context,
    builder: (context) => RewardDialog(data: data),
  );
}

class RewardDialog extends StatefulWidget {
  final RewardModel data;

  const RewardDialog({super.key, required this.data});

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  @override
  Widget build(BuildContext context) {
    return FullScreenDialog(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildTopSection(),
                const SizedBox(height: 67),
                ...RewardType.values.map((type) {
                  return Column(
                    children: [
                      RewardSection(
                        type: type,
                        data: widget.data,
                      ),
                      if (type != RewardType.values.last)
                        const SizedBox(height: 68),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
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
                imageUrl: widget.data.thumbnail ?? '',
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width.toInt(),
                height: MediaQuery.of(context).size.width.toInt(),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 48,
              margin: EdgeInsets.symmetric(horizontal: 30.cw),
              child: VoteCommonTitle(
                title: getLocaleTextFromJson(widget.data.title!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RewardSection extends StatelessWidget {
  final RewardType type;
  final RewardModel data;

  const RewardSection({
    super.key,
    required this.type,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 12),
          padding: EdgeInsets.symmetric(horizontal: 24.cw, vertical: 53),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(RewardDialogConstants.imageRadius),
            border: Border.all(color: AppColors.primary500, width: 1.5),
          ),
          child: Column(children: _buildSectionContent(context)),
        ),
        Positioned(
          top: 0,
          left: 40.cw,
          child: Image.asset(
            'assets/images/reward_${type.name}.png',
            height: 24,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSectionContent(BuildContext context) {
    final locale = Intl.getCurrentLocale();
    List<Widget> widgets = [];

    switch (type) {
      case RewardType.overview:
        if (data.overviewImages != null) {
          widgets.addAll(_buildImageList(context, data.overviewImages));
        }
        break;

      case RewardType.location:
        if (data.location?[locale] != null) {
          final locationData = data.location![locale];
          // Map 이미지 처리
          if (locationData['map'] != null) {
            final mapImages = locationData['map'].cast<String>();
            if (mapImages.isNotEmpty) {
              widgets.addAll(_buildImageList(
                context,
                [mapImages.first],
                BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(RewardDialogConstants.imageRadius),
                  border: Border.all(
                    color: AppColors.primary500,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
              ));
              if (mapImages.length > 1) {
                widgets.addAll(_buildImageList(context, mapImages.sublist(1)));
              }
            }
          }

          if (locationData['address'] != null) {
            widgets.add(const SizedBox(height: 24));
            widgets.addAll(_buildTextAddress(
              context,
              locationData['address'].cast<String>(),
              getTextStyle(AppTypo.body16B, AppColors.grey900),
            ));
          }

          if (locationData['images'] != null) {
            widgets.add(const SizedBox(height: 24));
            widgets.addAll(_buildImageList(
              context,
              locationData['images'].cast<String>(),
            ));
          }

          if (locationData['desc'] != null) {
            widgets.add(const SizedBox(height: 24));
            widgets.addAll(_buildTextList(
              locationData['desc'].cast<String>(),
              getTextStyle(AppTypo.body16B, AppColors.grey900),
            ));
          }
        }
        break;

      case RewardType.size_guide:
        if (data.sizeGuide?[locale] != null) {
          for (final guide in data.sizeGuide![locale]) {
            if (guide['image'] != null) {
              widgets.addAll(_buildSizeGuideImageList(
                context,
                guide['image'].cast<String>(),
              ));
            }

            if (guide['desc'] != null) {
              widgets.add(const SizedBox(height: 24));
              final descList = guide['desc'].cast<String>();
              if (descList.isNotEmpty) {
                widgets.addAll(_buildTextList(
                  [descList.first],
                  getTextStyle(AppTypo.body16B, AppColors.grey900),
                ));
                if (descList.length > 1) {
                  widgets.addAll(_buildTextList(
                    descList.sublist(1),
                    getTextStyle(AppTypo.body16R, AppColors.grey900),
                  ));
                }
              }
            }
            widgets.add(const SizedBox(height: 24));
          }
        }
        break;
    }

    return widgets;
  }

  List<Widget> _buildImageList(
    BuildContext context,
    List<String>? images, [
    BoxDecoration? decoration,
  ]) {
    if (images == null) return [];

    final imageSize = MediaQuery.of(context).size.width - 100;

    return images.asMap().entries.map((entry) {
      final i = entry.key;
      final image = entry.value;
      return Column(
        children: [
          Container(
            decoration: decoration,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(RewardDialogConstants.imageRadius),
              child: PicnicCachedNetworkImage(
                imageUrl: image,
                width: imageSize.toInt(),
                height: imageSize.toInt(),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (i != images.length - 1) const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  List<Widget> _buildSizeGuideImageList(
      BuildContext context, List<String>? images) {
    if (images == null) return [];

    return images.asMap().entries.map((entry) {
      final i = entry.key;
      final image = entry.value;
      return Column(
        children: [
          SizedBox(
            child: PicnicCachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
            ),
          ),
          if (i != images.length - 1) const SizedBox(height: 12),
        ],
      );
    }).toList();
  }

  List<Widget> _buildTextList(List<String>? texts, [TextStyle? style]) {
    if (texts == null) return [];

    return texts
        .map((text) => Text(
              text,
              style: style ?? getTextStyle(AppTypo.body16R, AppColors.grey900),
              textAlign: TextAlign.center,
            ))
        .toList();
  }

  List<Widget> _buildTextAddress(
    BuildContext context,
    List<String>? texts, [
    TextStyle? style,
  ]) {
    if (texts == null) return [];

    return texts
        .map((text) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Text(
                    '· $text',
                    style: style ??
                        getTextStyle(AppTypo.body16R, AppColors.grey900),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: () => copyToClipboard(context, text),
                  child: Text(
                    'COPY',
                    style: getTextStyle(AppTypo.body16B, AppColors.primary500),
                  ),
                ),
              ],
            ))
        .toList();
  }
}
