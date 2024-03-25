import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/pages/language_page.dart';
import 'package:prame_app/providers/app_setting_provider.dart';

class LanguageScreen extends ConsumerWidget {
  static const String routeName = '/language';

  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(Intl.message('title_select_language'))),
      body: LanguagePage(),
    );
  }
}
