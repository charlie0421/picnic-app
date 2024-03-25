import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prame_app/pages/gallery_page.dart';
import 'package:prame_app/pages/home_page.dart';
import 'package:prame_app/providers/bottom_navigation_provider.dart';
import 'package:prame_app/screens/bottom_navigation_bar.dart';

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
        title: counterState == 0
            ? const Text('Home')
            : counterState == 1
                ? Text('Gallery')
                : Container(),
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/prame');
            },
            child:
                CircleAvatar(backgroundColor: Colors.grey, child: Text('P')),
          ),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(counterRead, counterState),
      body: counterState == 0
          ? HomePage()
          : counterState == 1
              ? GalleryPage()
              : Container(),
    );
  }
}
