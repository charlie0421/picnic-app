import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picnic_app/components/pic/make-pic.dart';

class PicMakePage extends ConsumerWidget {
  const PicMakePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MakgePic();
  }
}
