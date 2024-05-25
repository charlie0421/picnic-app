import 'package:flutter/material.dart';
import 'package:picnic_app/components/appinfo.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({super.key});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  @override
  Widget build(BuildContext context) {
    return const AppInfo();
  }
}
