import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/community/compatibility/animated_heart.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';

class CompatibilityInfo extends StatefulWidget {
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
  State<CompatibilityInfo> createState() => _CompatibilityInfoState();
}

class _CompatibilityInfoState extends State<CompatibilityInfo> {
  @override
  Widget build(BuildContext context) {
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
              ClipRRect(
                borderRadius: widget.compatibility?.status !=
                        CompatibilityStatus.completed
                    ? BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16))
                    : BorderRadius.only(topLeft: Radius.circular(16)),
                child: ProfileImageContainer(
                  avatarUrl: widget.artist.image ?? '',
                  width: 150,
                  height: 150,
                  borderRadius: 0,
                ),
              ),
              SizedBox(width: 16),
              Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getLocaleTextFromJson(widget.artist.name),
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatDateTimeYYYYMMDD(
                              widget.artist.birthDate ?? DateTime.now()),
                          textAlign: TextAlign.center,
                          style: getTextStyle(
                              AppTypo.caption12M, AppColors.grey600),
                        ),
                        Text(' · ',
                            style: getTextStyle(
                                AppTypo.caption12B, AppColors.grey900)),
                        Text(
                          widget.artist.gender! == 'male' ? '🧑' : '👩',
                          textAlign: TextAlign.center,
                          style: getTextStyle(
                              AppTypo.caption12M, AppColors.grey900),
                        )
                      ],
                    ),
                    SizedBox(height: 4),
                    if (widget.birthDate != null) ...[
                      SizedBox(height: 18),
                      Text(
                        widget.ref.read(userInfoProvider
                                .select((value) => value.value?.nickname)) ??
                            '',
                        textAlign: TextAlign.center,
                        style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                      ),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.birthDate != null) ...[
                          Text(
                            formatDateTimeYYYYMMDD(widget.birthDate!),
                            textAlign: TextAlign.center,
                            style: getTextStyle(
                                AppTypo.caption12M, AppColors.grey600),
                          )
                        ],
                        if (widget.gender != null) ...[
                          Text(' · ',
                              style: getTextStyle(
                                  AppTypo.caption12B, AppColors.grey900)),
                          Text(
                            widget.gender! == 'male' ? '🧑' : '👩',
                            textAlign: TextAlign.center,
                            style: getTextStyle(
                                AppTypo.caption12M, AppColors.grey900),
                          )
                        ],
                        if (widget.birthTime != null) ...[
                          Text(' · ',
                              style: getTextStyle(
                                  AppTypo.caption12B, AppColors.grey900)),
                          Text(
                            convertKoreanTraditionalTime(widget.birthTime),
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
          if (widget.compatibility?.status == CompatibilityStatus.completed)
            AnimatedCompatibilityBar(
              score: widget.compatibility!.compatibilityScore ?? 0,
              message: _getScoreMessage(
                  widget.compatibility!.compatibilityScore ?? 0),
            ),
        ],
      ),
    );
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return S.of(context).compatibility_result_90;
    if (score >= 80) return S.of(context).compatibility_result_80;
    if (score >= 70) return S.of(context).compatibility_result_70;
    return S.of(context).compatibility_result_low;
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
      _AnimatedCompatibilityBarState();
}

class _AnimatedCompatibilityBarState extends State<AnimatedCompatibilityBar>
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
          AnimatedBuilder(
            animation: _widthAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _widthAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getScoreColor(widget.score),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mint500,
                        AppColors.primary500,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
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

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.primary500; // 핑크
    if (score >= 80) return AppColors.point900; // 레드
    if (score >= 70) return AppColors.point500;
    return AppColors.grey500;
  }
}
