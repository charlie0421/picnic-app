import 'package:flutter/material.dart';
import 'package:picnic_app/pages/fan/fan_home_page.dart';
import 'package:picnic_app/pages/fan/gallery_page.dart';
import 'package:picnic_app/pages/fan/landing_page.dart';
import 'package:picnic_app/pages/vote/vote_home.dart';
import 'package:picnic_app/screens/fan/fan_screen.dart';

List<Widget> voteScreens = [
  const VoteHomePage(),
  Container(),
  Container(),
  Container(),
];

List<Widget> fanScreens = [
  const FanHomePage(),
  const GalleryPage(),
  const FanScreen(),
  Container(),
  const LandingPage(),
];

List<Widget> communityScreens = [
  Container(),
  Container(),
  Container(),
  Container(),
];

List<Widget> novelScreens = [
  Container(),
  Container(),
  Container(),
  Container(),
];
