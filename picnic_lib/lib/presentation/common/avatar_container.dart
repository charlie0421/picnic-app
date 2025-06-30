import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/ui/style.dart';

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
      key: ValueKey('avatar_${avatarUrl!}_${width}_$height'), // ✅ 유니크 키로 캐시 최적화
      imageUrl: avatarUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      priority: ImagePriority.normal, // ✅ 안정적인 normal 우선순위
      lazyLoadingStrategy: LazyLoadingStrategy.viewport, // ✅ 뷰포트 기반 지연로딩
      enableMemoryOptimization: true, // ✅ 메모리 최적화 활성화
      enableProgressiveLoading: true, // ✅ 점진적 로딩으로 빠른 표시
      memCacheWidth: width?.toInt() ?? 48, // ✅ 메모리 캐시 크기 지정
      memCacheHeight: height?.toInt() ?? 48, // ✅ 메모리 캐시 크기 지정
      timeout: const Duration(seconds: 10), // ✅ 타임아웃 설정
      maxRetries: 2, // ✅ 재시도 횟수 설정
      borderRadius:
          borderRadius != null ? BorderRadius.circular(borderRadius!) : null,
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: borderRadius != null
              ? BorderRadius.circular(borderRadius!)
              : null,
        ),
        child: Icon(
          Icons.person,
          size: ((width ?? 48) * 0.4),
          color: AppColors.grey400,
        ),
      ),
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
        package: 'picnic_lib',
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
        package: 'picnic_lib',
        'assets/icons/header/no_avatar.png',
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}
