import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/pages/my_page/terms_page.dart';

class TermsScreen extends StatelessWidget {
  static const String routeName = '/terms';

  final String? language;

  const TermsScreen({super.key, this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: TermsPage(language: language));
  }
}
