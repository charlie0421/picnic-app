import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/appinfo.dart';
import 'package:picnic_app/providers/logined_provider.dart';
import 'package:picnic_app/screens/login_screen.dart';

class DeveloperHomeScreen extends ConsumerWidget {
  const DeveloperHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool logined = ref.watch(loginedProvider);

    return Scaffold(body: logined ? const AppInfo() : const LoginScreen());
  }
}
