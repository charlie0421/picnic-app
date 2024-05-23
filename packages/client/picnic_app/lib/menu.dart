import 'package:flutter/material.dart';
import 'package:picnic_app/components/appinfo.dart';
import 'package:picnic_app/pages/prame/gallery_page.dart';
import 'package:picnic_app/pages/prame/landing_page.dart';
import 'package:picnic_app/pages/prame/prame_home_page.dart';
import 'package:picnic_app/pages/vote/vote_home.dart';
import 'package:picnic_app/screens/prame/prame_screen.dart';

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

List<Widget> developerScreens = [
  const AppInfo(),
];
