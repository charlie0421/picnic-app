import 'package:flutter/material.dart';
import 'package:prame_app/pages/prame/gallery_page.dart';
import 'package:prame_app/pages/prame/home_page.dart';
import 'package:prame_app/pages/prame/landing_page.dart';
import 'package:prame_app/pages/vote/vote_home.dart';
import 'package:prame_app/screens/prame/prame_screen.dart';

List<Widget> voteScreens = [
  const VoteHomePage(),
  Container(),
  Container(),
  Container(),
];

List<Widget> prameScreens = [
  const PrameHomePage(),
  const GalleryPage(),
  const PrameScreen(),
  Container(),
  const LandingPage(),
];
