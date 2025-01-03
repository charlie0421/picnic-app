import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/pages/my_page/privacy_page.dart';

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
