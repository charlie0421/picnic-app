import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/community/compatibility/animated_heart.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';

class CompatibilityInfo extends StatelessWidget {
  const CompatibilityInfo({
    super.key,
    required this.artist,
    required this.ref,
    required DateTime? birthDate,
  }) : _birthDate = birthDate;

  final ArtistModel artist;
  final WidgetRef ref;
  final DateTime? _birthDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary500, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfileImageContainer(
                avatarUrl: artist.image ?? '',
                width: 100,
                height: 100,
                borderRadius: 20,
              ),
              SizedBox(width: 16),
              FancyPulsingHeart(
                size: 32.0,
                color: Colors.red,
                duration: const Duration(seconds: 2),
              ),
              SizedBox(width: 16),
              ProfileImageContainer(
                avatarUrl: ref.read(userInfoProvider
                        .select((value) => value.value?.avatarUrl)) ??
                    '',
                width: 100,
                height: 100,
                borderRadius: 20,
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Text(
                      getLocaleTextFromJson(artist.name) ?? '',
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                    Text(
                      formatDateTimeYYYYMMDD(
                          artist.birthDate ?? DateTime.now()),
                      textAlign: TextAlign.center,
                      style:
                          getTextStyle(AppTypo.caption12M, AppColors.grey900),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 70),
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Text(
                      ref.read(userInfoProvider
                              .select((value) => value.value?.nickname)) ??
                          '',
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                    Text(
                      formatDateTimeYYYYMMDD(_birthDate ?? DateTime.now()),
                      textAlign: TextAlign.center,
                      style:
                          getTextStyle(AppTypo.caption12M, AppColors.grey900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
