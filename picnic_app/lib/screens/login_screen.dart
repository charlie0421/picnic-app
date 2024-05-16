import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/pages/prame/my_page.dart';

class LoginScreen extends ConsumerWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

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

class LoginScreenArguments {
  final String? email;
  final String? password;

  LoginScreenArguments({this.email, this.password});
}
