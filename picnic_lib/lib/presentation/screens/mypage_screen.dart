import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_animated_switcher.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  static const String routeName = '/mypage';

  const MyPageScreen({super.key});

  @override
  MyPageScreenState createState() => MyPageScreenState();
}

class MyPageScreenState extends ConsumerState<MyPageScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfo = ref.watch(navigationInfoProvider);

    String pageName = navigationInfo.myPageTitle;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        logger.d('PopScope onPopInvokedWithResult: $didPop, $result');
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: PicnicUi.surface,
          foregroundColor: PicnicUi.ink,
          leading: Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Material(
                  color: AppColors.grey200,
                  elevation: 3,
                  shadowColor: PicnicUi.ink.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      if (navigationInfo.drawerNavigationStack != null &&
                          navigationInfo.drawerNavigationStack!.length > 1) {
                        ref
                            .read(navigationInfoProvider.notifier)
                            .goBackMyPage();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: SizedBox(
                      width: PicnicUi.minimumTapTarget,
                      height: PicnicUi.minimumTapTarget,
                      child: Center(
                        child: SvgPicture.asset(
                          package: 'picnic_lib',
                          'assets/icons/arrow_left_style=line.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            PicnicUi.ink,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          title: Text(
            pageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PicnicUi.text(size: 16, weight: FontWeight.w700),
          ),
          centerTitle: true,
          leadingWidth: 60,
        ),
        body: const DrawerAnimatedSwitcher(),
      ),
    );
  }
}
