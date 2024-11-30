import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/community/compatibility/animated_heart.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';

class CompatibilityInfo extends StatefulWidget {
  const CompatibilityInfo({
    super.key,
    required this.artist,
    required this.ref,
    required DateTime? birthDate,
    this.birthTime,
  }) : _birthDate = birthDate;

  final ArtistModel artist;
  final WidgetRef ref;
  final DateTime? _birthDate;
  final String? birthTime;

  @override
  State<CompatibilityInfo> createState() => _CompatibilityInfoState();
}

class _CompatibilityInfoState extends State<CompatibilityInfo> {
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
                avatarUrl: widget.artist.image ?? '',
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
                avatarUrl: widget.ref.read(userInfoProvider
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
                width: 120,
                child: Column(
                  children: [
                    Text(
                      getLocaleTextFromJson(widget.artist.name),
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                    Text(
                      formatDateTimeYYYYMMDD(
                          widget.artist.birthDate ?? DateTime.now()),
                      textAlign: TextAlign.center,
                      style:
                          getTextStyle(AppTypo.caption12M, AppColors.grey900),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 60),
              SizedBox(
                width: 120,
                child: Column(
                  children: [
                    Text(
                      widget.ref.read(userInfoProvider
                              .select((value) => value.value?.nickname)) ??
                          '',
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.body14M, AppColors.grey900),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget._birthDate != null)
                          Text(
                            formatDateTimeYYYYMMDD(widget._birthDate!),
                            textAlign: TextAlign.center,
                            style: getTextStyle(
                                AppTypo.caption12M, AppColors.grey900),
                          ),
                        if (widget.birthTime != null)
                          Text(
                            convertKoreanTraditionalTime(widget.birthTime),
                            textAlign: TextAlign.center,
                            style: getTextStyle(
                                AppTypo.body16B, AppColors.grey900),
                          ),
                      ],
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
