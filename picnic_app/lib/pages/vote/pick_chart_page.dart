import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/ui/style.dart';

class PicChartPage extends StatefulWidget {
  const PicChartPage({super.key});

  @override
  State<PicChartPage> createState() => _PicChartPageState();
}

class _PicChartPageState extends State<PicChartPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPicChartInfoDialog();
    });
  }

  _showPicChartInfoDialog() {
    showDialog(
        context: context,
        builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setState) => LargePopupWidget(
                title: '픽차트란?',
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '무슨 차트로,\n무슨 지표를 어떻게 하는 차트입니다.\n픽차트는 이렇게 저렇게 쓰입니당',
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.BODY14M, AppColors.Grey900),
                    ),
                    Divider(
                      height: 72.w,
                      thickness: 1,
                      color: AppColors.Grey300,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/vote/vote_title_left.svg',
                          width: 16.w,
                          height: 16.w,
                        ),
                        Text(
                          '점수 산정 방법',
                          style: getTextStyle(
                              AppTypo.BODY14B, AppColors.Primary500),
                        ),
                        SvgPicture.asset(
                          'assets/icons/vote/vote_title_right.svg',
                          width: 16.w,
                          height: 16.w,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.w),
                    Text(
                      '무슨 차트로,\n무슨 지표를 어떻게 하는 차트입니다.\n픽차트는 이렇게 저렇게 쓰입니당',
                      textAlign: TextAlign.center,
                      style: getTextStyle(AppTypo.BODY14M, AppColors.Grey900),
                    ),
                    SizedBox(height: 16.w),
                    Text(
                      '주간 투표 / 각 멤버의 투표 순위 평균 /\n개인의 경우 개인 순위 반영 / 포털 검색량 /\n구글, 네이버, 야후 등 / 스포티파이 순위',
                      textAlign: TextAlign.center,
                      style:
                          getTextStyle(AppTypo.CAPTION10SB, AppColors.Grey400),
                    ),
                  ],
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/vote/checkbox.svg',
                          width: 24.w,
                          height: 24.w,
                          colorFilter: const ColorFilter.mode(
                              AppColors.Mint500, BlendMode.srcIn),
                        ),
                        Text('1개월간 보지 않기',
                            style: getTextStyle(
                                AppTypo.CAPTION12R, AppColors.Mint500)),
                      ],
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('닫기',
                              style: getTextStyle(
                                  AppTypo.BODY14M, AppColors.Grey00)),
                          SvgPicture.asset(
                            'assets/icons/cancle_style=fill.svg',
                            width: 24.w,
                            height: 24.w,
                            colorFilter: const ColorFilter.mode(
                                AppColors.Grey00, BlendMode.srcIn),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: TabBar(controller: _tabController, tabs: [
            Tab(text: Intl.message('label_tabbar_picchart_daily')),
            Tab(text: Intl.message('label_tabbar_picchart_weekly')),
            Tab(text: Intl.message('label_tabbar_picchart_monthly')),
          ]),
        ),
        Expanded(
            child: TabBarView(controller: _tabController, children: [
          Container(
            child: Center(
              child: Text(Intl.message('label_tabbar_picchart_daily')),
            ),
          ),
          Container(
            child: Center(
              child: Text(Intl.message('label_tabbar_picchart_daily')),
            ),
          ),
          Container(
            child: Center(
              child: Text(Intl.message('label_tabbar_picchart_daily')),
            ),
          ),
        ]))
      ],
    );
  }
}
