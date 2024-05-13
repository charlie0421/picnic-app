import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:prame_app/components/prame/make_prame.dart';
import 'package:prame_app/components/prame/select_artist.dart';

class PrameMakePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MakgePrame();
  }
}
