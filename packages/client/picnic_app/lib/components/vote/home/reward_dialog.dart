import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/reward.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class RewardDialog extends StatelessWidget {
  final RewardModel data;

  const RewardDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      logger.i('data: $data');
      return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              SingleChildScrollView(
                  child: Column(
                children: [
                  buildTopSection(context),
                  SizedBox(height: 67.w),
                  ...buildRewardSection('overview.png', data.overview_images),
                  SizedBox(height: 56.w),
                  ...buildRewardSection(
                    'location.png',
                    data.location_images,
                    data.location_desc,
                  ),
                  SizedBox(height: 56.w),
                  ...buildRewardSection(
                    'size_guide.png',
                    data.size_guide_images,
                  ),
                  SizedBox(height: 56.w),
                ],
              )),
              Positioned(
                top: 30.w,
                right: 15.w,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: SvgPicture.asset(
                    'assets/icons/cancle_style=fill.svg',
                    width: 30.w,
                    height: 30.w,
                    colorFilter: const ColorFilter.mode(
                        AppColors.Grey300, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ));
    });
  }

  Widget buildTopSection(BuildContext context) {
    return Stack(
      children: [
        ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
              stops: [0.7, 1],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: CachedNetworkImage(
              imageUrl: data.thumbnail ?? '',
              width: double.infinity,
              placeholder: (context, url) => buildPlaceholderImage(),
              fit: BoxFit.cover),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 48.w,
            margin: const EdgeInsets.symmetric(horizontal: 57).r,
            child: VoteCommonTitle(
              title: data.getTitle() ?? '',
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> buildRewardSection(String iconName,
      [List<String>? images, List<String>? desc]) {
    return [
      Stack(
        children: [
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, right: 16, top: 12).r,
              padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 53, bottom: 41)
                  .r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.Primary500, width: 1.5.r),
              ),
              child: Column(
                children: [
                  ...?images?.asMap()?.entries?.map((e) =>
                      _buildContainerWithText(iconName, e.key, e.value, desc)),
                  SizedBox(height: 16.w),
                ],
              )),
          Positioned(
            top: 0,
            left: 40.w,
            child: Image.asset('assets/images/reward_$iconName', height: 24.w),
          ),
        ],
      ),
    ];
  }

  Widget _buildContainerWithText(
      String iconName, int imageIndex, String imageUrl, List<String>? desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: iconName == 'location.png' && imageIndex == 0
                  ? Border.all(color: AppColors.Primary500, width: 3.r)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: CachedNetworkImage(
                imageUrl: imageUrl ?? '',
                width: double.infinity,
                placeholder: (context, url) => buildPlaceholderImage(),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (desc != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24).r,
              child: Text(
                '${imageIndex == 0 ? '•' : ""} ${desc[imageIndex]}',
                style: imageIndex == 0
                    ? getTextStyle(
                        AppTypo.BODY16B,
                        AppColors.Grey900,
                      )
                    : getTextStyle(
                        AppTypo.BODY16R,
                        AppColors.Grey900,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
