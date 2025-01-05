import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/enums.dart';

class ScreenInfo {
  const ScreenInfo({
    required this.type,
    required this.color,
    required this.pages,
  });

  final PortalType type;
  final Color color;
  final List<BottomNavigationItem> pages;
}
