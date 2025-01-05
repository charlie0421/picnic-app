import 'package:flutter/material.dart';

class BottomNavigationItem {
  const BottomNavigationItem({
    required this.title,
    required this.assetPath,
    required this.index,
    required this.pageWidget,
    required this.needLogin,
  });

  final String title;
  final String assetPath;
  final int index;
  final Widget pageWidget;
  final bool needLogin;
}
