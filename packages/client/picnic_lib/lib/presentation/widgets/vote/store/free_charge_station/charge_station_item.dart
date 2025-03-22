import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_types.dart';

/// 미션 및 광고 아이템을 위한 클래스 정의
class ChargeStationItem {
  final String id;
  final String title;
  final bool isMission;
  final AdPlatformType platformType;
  final int index;
  final VoidCallback onPressed;
  final String bonusText;

  const ChargeStationItem({
    required this.id,
    required this.title,
    required this.isMission,
    required this.platformType,
    this.index = 0,
    required this.onPressed,
    this.bonusText = '1',
  });
}
