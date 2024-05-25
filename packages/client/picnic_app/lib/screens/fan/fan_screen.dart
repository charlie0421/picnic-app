import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/pages/fan/fan_make_page.dart';
import 'package:picnic_app/pages/fan/fan_page.dart';

import '../../providers/fan_provider.dart';

class FanScreen extends ConsumerWidget {
  static const String routeName = '/fan';

  const FanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int fanPageIndex = ref.watch(parmePageIndexProvider);
    logger.d('fanPageIndex: $fanPageIndex');
    Widget widget = fanPageIndex == 0 ? const FanPage() : const FanMakePage();
    return WillPopScope(
      onWillPop: () async {
        if (ref.watch(parmePageIndexProvider.notifier).state == 1) {
          ref.read(parmePageIndexProvider.notifier).state = 0;
          return false;
        } else if (ref.watch(fanSelectedIndexProvider.notifier).state == 0) {
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
