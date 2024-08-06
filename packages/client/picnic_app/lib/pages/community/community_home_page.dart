import 'package:flutter/material.dart';
import 'package:picnic_app/components/common/common_banner.dart';

class CommunityHomePage extends StatelessWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const CommonBanner('vote_home'),
    ]);
  }
}
