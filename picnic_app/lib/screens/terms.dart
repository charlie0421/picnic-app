import 'package:flutter/material.dart';
import 'package:picnic_app/pages/mypage/terms_page.dart';

class TermsScreen extends StatelessWidget {
  static const String routeName = '/terms';

  final String? language;

  TermsScreen({super.key, this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: TermsPage(language: language));
  }
}
