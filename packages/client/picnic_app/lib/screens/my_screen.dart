import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/prame/my_page.dart';

class MyScreen extends ConsumerWidget {
  static const String routeName = '/my';

  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My'),
      ),
      body: MyPage(),
    );
  }
}
