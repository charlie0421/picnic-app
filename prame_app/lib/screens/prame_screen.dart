import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/pages/prame_page.dart';

class PrameScreen extends ConsumerWidget {
  static const String routeName = '/prame';

  const PrameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(Intl.message('title_prame'))),
      body: PramePage(),
    );
  }
}
