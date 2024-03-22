import 'package:prame_app/providers/bottom_navigation_provider.dart';
import 'package:flutter/material.dart';

BottomNavigationBar buildBottomNavigationBar(
  BottomNavigationBarCount counterRead,
  int counterState,
) {
  return BottomNavigationBar(
    items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.photo),
        label: 'Gallery',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.library_books),
        label: 'Library',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.wallet),
        label: 'Purchase',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.ads_click),
        label: 'Ads',
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
