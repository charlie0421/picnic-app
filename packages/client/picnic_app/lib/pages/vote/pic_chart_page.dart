import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/ui/style.dart';

class PicChartPage extends ConsumerStatefulWidget {
  const PicChartPage({super.key});

  @override
  ConsumerState<PicChartPage> createState() => _PicChartPageState();
}

class _PicChartPageState extends ConsumerState<PicChartPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOverlay = false;

  @override
  initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _showOverlay = true;
      });
    });
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/picchart_comming_soon.png',
            fit: BoxFit.fill),
        if (_showOverlay)
          Positioned(
            left: 24.w,
            right: 24.w,
            top: 48.h,
            child: Material(
              color: Colors.transparent,
              child: LargePopupWidget(
                title: S.of(context).text_comming_soon_pic_chart_title,
                content: Container(
                  padding: EdgeInsets.only(
                      left: 16.w, right: 16.w, top: 64.h, bottom: 40.h),
                  child: Column(
                    children: [
                      Text(
                        S.of(context).text_comming_soon_pic_chart1,
                        style: getTextStyle(
                          AppTypo.BODY14M,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Divider(
                        color: AppColors.Grey300,
                        thickness: 1,
                        height: 40.h,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/icons/play_style=fill.svg',
                              width: 16.w,
                              height: 16.w,
                              color: AppColors.Primary500),
                          Text(
                            'COMING SOON',
                            style: getTextStyle(
                              AppTypo.BODY14B,
                              AppColors.Primary500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Transform.rotate(
                            angle: 3.14,
                            child: SvgPicture.asset(
                                'assets/icons/play_style=fill.svg',
                                width: 16.w,
                                height: 16.w,
                                color: AppColors.Primary500),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        S.of(context).text_comming_soon_pic_chart2,
                        style: getTextStyle(
                          AppTypo.BODY14M,
                          AppColors.Grey900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        S.of(context).text_comming_soon_pic_chart3,
                        style: getTextStyle(
                          AppTypo.CAPTION10SB,
                          AppColors.Grey400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
