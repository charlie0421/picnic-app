import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class ProfileImageContainer extends StatelessWidget {
  ProfileImageContainer({
    super.key,
    required this.avatarUrl,
    required this.borderRadius,
    required this.width,
    required this.height,
  });

  final avatarUrl;
  double? borderRadius = 8.r;
  double? width = 24.cw;
  double? height = 24.cw;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius!),
          child: avatarUrl != null &&
                  (avatarUrl.contains('http://') ||
                      avatarUrl.contains('https://'))
              ? CachedNetworkImage(
                  imageUrl: avatarUrl ?? '',
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                )
              : avatarUrl != null
                  ? PicnicCachedNetworkImage(
                      imageUrl: avatarUrl ?? '',
                      width: width?.toInt(),
                      height: height?.toInt(),
                      fit: BoxFit.cover,
                    )
                  : NoAvatar(
                      width: width,
                      height: height,
                      borderRadius: borderRadius,
                    )),
    );
  }
}

class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(6).r,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: SvgPicture.asset(
        'assets/icons/header/default_avatar.svg',
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppColors.grey00,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class NoAvatar extends StatelessWidget {
  NoAvatar(
      {super.key,
      required this.width,
      required this.height,
      required this.borderRadius});

  double? borderRadius = 8.r;
  double? width = 24.cw;
  double? height = 24.cw;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: Image.asset(
        'assets/icons/header/no_avatar.png',
        width: width,
        height: height,
      ),
    );
  }
}
