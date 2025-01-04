import 'package:flutter/material.dart';
import 'package:picnic_lib/data/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/enums.dart';

class ScreenInfo {
  PortalType type;
  Color color;
  List<BottomNavigationItem> pages;

  ScreenInfo({
    required this.type,
    required this.color,
    required this.pages,
  });
}
