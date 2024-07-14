import 'package:flutter/material.dart';
import 'package:picnic_app/pages/mypage/privacy_page.dart';

class PrivacyScreen extends StatelessWidget {
  static const String routeName = '/privacy';
  final String? language;

  const PrivacyScreen({super.key, this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PrivacyPage(
      language: language,
    ));
  }
}
