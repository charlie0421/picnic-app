import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
// ignore: unused_import
import 'package:picnic_lib/presentation/widgets/community/compatibility/compatibility_score_widget.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilityCard extends StatelessWidget {
  const CompatibilityCard({
    super.key,
    required this.artist,
    required this.ref,
    this.birthDate,
    this.birthTime,
    this.compatibility,
    this.gender,
  });

  final ArtistModel artist;
  final WidgetRef ref;
  final DateTime? birthDate;
  final String? birthTime;
  final String? gender;
  final CompatibilityModel? compatibility;

  /// 아티스트 이미지 빌드 (null/빈 문자열 처리 포함)
  Widget _buildArtistImage() {
    final imageUrl = artist.image;

    // 이미지 URL이 null이거나 빈 문자열인 경우 플레이스홀더 표시
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        width: 150.w,
        height: 150.w,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Icon(
          Icons.person,
          size: 150.w * 0.4, // 다른 파일과 동일한 비율
          color: AppColors.grey400,
        ),
      );
    }

    // 유효한 이미지 URL이 있는 경우
    return PicnicCachedNetworkImage(
      key: ValueKey('artist_${artist.id}_${artist.name}'), // ✅ 유니크 키로 캐시 최적화
      imageUrl: imageUrl,
      width: 150.w,
      height: 150.w,
      fit: BoxFit.cover,
      priority: ImagePriority.normal, // ✅ 안정적인 normal 우선순위
      lazyLoadingStrategy: LazyLoadingStrategy.viewport, // ✅ 뷰포트 기반 지연로딩
      enableMemoryOptimization: true, // ✅ 메모리 최적화 활성화
      enableProgressiveLoading: true, // ✅ 점진적 로딩으로 빠른 표시
      memCacheWidth: 150, // ✅ 메모리 캐시 크기 지정
      memCacheHeight: 150, // ✅ 메모리 캐시 크기 지정
      timeout: const Duration(seconds: 10), // ✅ 타임아웃 설정
      maxRetries: 2, // ✅ 재시도 횟수 설정
      borderRadius: BorderRadius.only(
        // ✅ 테두리 최적화
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      placeholder: Container(
        width: 150.w,
        height: 150.w,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Icon(
          Icons.person,
          size: 150.w * 0.4, // 다른 파일과 동일한 비율
          color: AppColors.grey400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        ref.watch(userInfoProvider.select((value) => value.value?.avatarUrl));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey00,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: _buildArtistImage(),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: ProfileImageContainer(
                        avatarUrl: avatarUrl ?? '',
                        width: 40,
                        height: 40,
                        borderRadius: 20,
                        border: Border.all(
                          color: AppColors.primary500,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UnderlinedText(
                        text: getLocaleTextFromJson(artist.name),
                        underlineGap: 2,
                        textStyle:
                            getTextStyle(AppTypo.body16B, AppColors.grey900),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            formatDateTimeYYYYMMDD(
                                artist.birthDate ?? DateTime.now()),
                            textAlign: TextAlign.center,
                            style: getTextStyle(
                                AppTypo.caption12M, AppColors.grey600),
                          ),
                          Text(' · ',
                              style: getTextStyle(
                                  AppTypo.caption12B, AppColors.grey900)),
                          Text(
                            artist.gender! == Gender.male.name
                                ? '🧑'
                                : artist.gender! == Gender.female.name
                                    ? '👩'
                                    : '',
                            textAlign: TextAlign.center,
                            style: getTextStyle(
                                AppTypo.caption12M, AppColors.grey900),
                          )
                        ],
                      ),
                      SizedBox(height: 4),
                      if (birthDate != null) ...[
                        SizedBox(height: 18),
                        UnderlinedText(
                          text: ref.read(userInfoProvider
                                  .select((value) => value.value?.nickname)) ??
                              '',
                          underlineGap: 2,
                          textStyle:
                              getTextStyle(AppTypo.body16B, AppColors.grey900),
                        ),
                      ],
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (birthDate != null) ...[
                            Text(
                              formatDateTimeYYYYMMDD(birthDate!),
                              textAlign: TextAlign.center,
                              style: getTextStyle(
                                  AppTypo.caption12M, AppColors.grey600),
                            )
                          ],
                          if (gender != null) ...[
                            Text(' · ',
                                style: getTextStyle(
                                    AppTypo.caption12B, AppColors.grey900)),
                            Text(
                              gender! == 'male' ? '🧑' : '👩',
                              textAlign: TextAlign.center,
                              style: getTextStyle(
                                  AppTypo.caption12M, AppColors.grey900),
                            )
                          ],
                          if (birthTime != null) ...[
                            Text(' · ',
                                style: getTextStyle(
                                    AppTypo.caption12B, AppColors.grey900)),
                            Text(
                              convertKoreanTraditionalTime(birthTime),
                              textAlign: TextAlign.center,
                              style: getTextStyle(
                                  AppTypo.caption12M, AppColors.grey900),
                            )
                          ],
                        ],
                      ),
                    ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
