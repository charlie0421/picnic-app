import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';

class SignUpScreen extends ConsumerWidget {
  static const routeName = '/singup';

  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
        body: SafeArea(
            child: Stack(
                fit: StackFit.expand, children: [SignUpAnimatedSwitcher()])));
  }
}
