import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/ui/style.dart';

class PicChartPage extends ConsumerStatefulWidget {
  const PicChartPage({super.key});

  @override
  ConsumerState<PicChartPage> createState() => _PicChartPageState();
}

class _PicChartPageState extends ConsumerState<PicChartPage>
    with SingleTickerProviderStateMixin {
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: true, showBottomNavigation: true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _showOverlay = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
            package: 'picnic_lib',
            'assets/images/picchart_comming_soon.png',
            fit: BoxFit.fill),
        if (_showOverlay)
          Center(
            child: Material(
              color: Colors.transparent,
              child: LargePopupWidget(
                title: t('text_comming_soon_pic_chart_title'),
                content: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 80,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                              package: 'picnic_lib',
                              'assets/icons/play_style=fill.svg',
                              width: 16.w,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                  AppColors.primary500, BlendMode.srcIn)),
                          Text(
                            'COMING SOON',
                            style: getTextStyle(
                              AppTypo.body14B,
                              AppColors.primary500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Transform.rotate(
                            angle: 3.14,
                            child: SvgPicture.asset(
                                package: 'picnic_lib',
                                'assets/icons/play_style=fill.svg',
                                width: 16.w,
                                height: 16,
                                colorFilter: ColorFilter.mode(
                                    AppColors.primary500, BlendMode.srcIn)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('text_comming_soon_pic_chart2'),
                        style: getTextStyle(
                          AppTypo.body14M,
                          AppColors.grey900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('text_comming_soon_pic_chart3'),
                        style: getTextStyle(
                          AppTypo.caption10SB,
                          AppColors.grey400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                closeButton: null,
                showCloseButton: false,
              ),
            ),
          ),
      ],
    );
  }
}
