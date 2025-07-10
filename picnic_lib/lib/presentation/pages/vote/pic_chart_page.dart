import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_pic_list_page.dart';

class PicChartPage extends ConsumerStatefulWidget {
  const PicChartPage({super.key});

  @override
  ConsumerState<PicChartPage> createState() => _PicChartPageState();
}

class _PicChartPageState extends ConsumerState<PicChartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showMyPoint: false,
            showBottomNavigation: true,
            pageTitle: AppLocalizations.of(context).label_pic_chart,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const VotePicListPage();
  }
}
