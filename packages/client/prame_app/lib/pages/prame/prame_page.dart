import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:prame_app/components/prame/select_artist.dart';

class PramePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SelectArtist();
  }
}
