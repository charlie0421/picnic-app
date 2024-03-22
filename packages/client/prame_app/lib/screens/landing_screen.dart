import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/pages/landing_page.dart';
import 'package:prame_app/providers/bottom_navigation_provider.dart';
import 'package:prame_app/screens/my_screen.dart';

class LandingScreen extends ConsumerWidget {
  static const String routeName = '/landing';

  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterRead =
        ref.read(bottomNavigationBarIndexStateProvider.notifier);
    final counterState = ref.watch(bottomNavigationBarIndexStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing'),
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, MyScreen.routeName);
              },
              child: CircleAvatar(
                child: Text('MY'),
              ),
            ),
          ),
        ],
      ),
      body: LandingPage(),
    );
  }
}
