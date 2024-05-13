import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/pages/prame/prame_make_page.dart';
import 'package:prame_app/pages/prame/prame_page.dart';

import '../../providers/prame_provider.dart';

class PrameScreen extends ConsumerWidget {
  static const String routeName = '/prame';

  const PrameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int pramePageIndex = ref.watch(parmePageIndexProvider);
    logger.d('pramePageIndex: $pramePageIndex');
    Widget widget = pramePageIndex == 0 ? PramePage() : PrameMakePage();
    return WillPopScope(
      onWillPop: () async {
        if (ref.watch(parmePageIndexProvider.notifier).state == 1) {
          ref.read(parmePageIndexProvider.notifier).state = 0;
          return false;
        } else if (ref.watch(prameSelectedIndexProvider.notifier).state == 0) {
          return true;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: widget,
      ),
    );
  }
}
