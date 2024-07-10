import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/ui/picnic_animated_switcher.dart';

class SignUpScreen extends ConsumerWidget {
  static const routeName = '/common';

  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
        body: SafeArea(
            child: Stack(
                fit: StackFit.expand, children: [SignUpAnimatedSwitcher()])));
  }
}
