import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/enums.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class CompatibilityInfo extends StatelessWidget {
  const CompatibilityInfo({
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

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        ref.watch(userInfoProvider.select((value) => value.value?.avatarUrl));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: compatibility?.status ==
                                CompatibilityStatus.completed &&
                            compatibility?.isAds == true
                        ? BorderRadius.only(topLeft: Radius.circular(16))
                        : BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16)),
                    child: PicnicCachedNetworkImage(
                      imageUrl: artist.image ?? '',
                      width: 150.cw,
                      height: 150.cw,
                    ),
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
                    Text(
                      getLocaleTextFromJson(artist.name),
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                    ),
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
                          artist.gender! == Gender.MALE.name
                              ? '🧑'
                              : artist.gender! == Gender.FEMALE.name
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
                      Text(
                        ref.read(userInfoProvider
                                .select((value) => value.value?.nickname)) ??
                            '',
                        textAlign: TextAlign.center,
                        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                      ),
                    ],
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
          if (compatibility != null &&
              compatibility?.status == CompatibilityStatus.completed &&
              compatibility?.isAds == true) ...[
            Builder(
              builder: (context) {
                final currentLocale = getLocaleLanguage();
                final localizedResult =
                    compatibility?.localizedResults?[currentLocale];

                if (localizedResult != null) {
                  return AnimatedCompatibilityBar(
                    score: localizedResult.score,
                    message: localizedResult.scoreTitle,
                  );
                }
                return const SizedBox.shrink(); // 결과가 없을 경우 빈 위젯 반환
              },
            ),
          ],
        ],
      ),
    );
  }
}

class AnimatedCompatibilityBar extends StatefulWidget {
  final int score;
  final String message;

  const AnimatedCompatibilityBar({
    super.key,
    required this.score,
    required this.message,
  });

  @override
  State<AnimatedCompatibilityBar> createState() =>
      AnimatedCompatibilityBarState();
}

class AnimatedCompatibilityBarState extends State<AnimatedCompatibilityBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _widthAnimation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _widthAnimation,
                builder: (context, child) {
                  final actualWidth =
                      constraints.maxWidth * _widthAnimation.value;

                  return ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: actualWidth,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.mint500,
                              AppColors.primary500,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  '${widget.score}%',
                  style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                ),
                SizedBox(width: 8),
                Text(
                  widget.message,
                  style: getTextStyle(AppTypo.body16B, AppColors.grey00),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
