import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/providers/bottom_navigation_provider.dart';

BottomNavigationBar buildBottomNavigationBar(ref) {
  final counterRead = ref.read(bottomNavigationBarIndexStateProvider.notifier);
  final counterState = ref.watch(bottomNavigationBarIndexStateProvider);

  return BottomNavigationBar(
    items: <BottomNavigationBarItem>[
      BottomNavigationBarItem(
          icon: const Icon(Icons.home), label: Intl.message('nav_home')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.photo), label: Intl.message('nav_gallery')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.library_books),
          label: Intl.message('nav_library')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.wallet), label: Intl.message('nav_purchases')),
      BottomNavigationBarItem(
          icon: const Icon(Icons.settings), label: Intl.message('nav_setting')),
    ],
    currentIndex: counterState,
    // backgroundColor: Colors.blue,
    // selectedItemColor: Colors.white,
    // unselectedIconTheme: const IconThemeData(color: Colors.white30),
    // unselectedItemColor: Colors.white30,
    onTap: (index) {
      counterRead.setIndex(index);
    },
  );
}
