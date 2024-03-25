import 'package:intl/intl.dart';
import 'package:prame_app/providers/bottom_navigation_provider.dart';
import 'package:flutter/material.dart';

BottomNavigationBar buildBottomNavigationBar(
  BottomNavigationBarCount counterRead,
  int counterState,
) {
  return BottomNavigationBar(
    items: <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: Intl.message('nav_home')
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.photo),
          label: Intl.message('nav_gallery')
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.library_books),
          label: Intl.message('nav_library')
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.wallet),
          label: Intl.message('nav_purchases')
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.ads_click),
          label: Intl.message('nav_ads')
      ),
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
