import 'package:prame_app/pages/home_page.dart';
import 'package:prame_app/providers/bottom_navigation_provider.dart';
import 'package:prame_app/screens/bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterRead =
        ref.read(bottomNavigationBarIndexStateProvider.notifier);
    final counterState = ref.watch(bottomNavigationBarIndexStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      bottomNavigationBar: buildBottomNavigationBar(counterRead, counterState),
      body: HomePage(),
    );
  }
}
