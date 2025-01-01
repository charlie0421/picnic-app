import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_app/ui/style.dart';

class ProfileImageContainer extends StatelessWidget {
  const ProfileImageContainer({
    super.key,
    required this.avatarUrl,
    required this.borderRadius,
    required this.width,
    required this.height,
    this.border,
  });

  final String? avatarUrl;
  final double? borderRadius;
  final double? width;
  final double? height;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: (borderRadius != null)
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius!),
              border: border != null
                  ? Border.all(
                      color: AppColors.primary500,
                      width: 1.5,
                    )
                  : null,
            )
          : null,
      child: (borderRadius != null)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius!),
              child: _buildImage(),
            )
          : _buildImage(),
    );
  }

  Widget _buildImage() {
    if (avatarUrl == null) {
      return NoAvatar(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    if (avatarUrl!.contains('http://') || avatarUrl!.contains('https://')) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    return PicnicCachedNetworkImage(
      imageUrl: avatarUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
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
      padding: const EdgeInsets.all(6),
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
  const NoAvatar(
      {super.key,
      required this.width,
      required this.height,
      required this.borderRadius});

  final double? borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: Image.asset(
        'assets/icons/header/no_avatar.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}
