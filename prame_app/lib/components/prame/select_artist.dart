import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/providers/celeb_list_provider.dart';
import 'package:prame_app/providers/my_celeb_list_provider.dart';
import 'package:prame_app/providers/prame_provider.dart';
import 'package:prame_app/ui/style.dart';

class SelectArtist extends ConsumerStatefulWidget {
  @override
  createState() => _SelectArtistState();
}

class _SelectArtistState extends ConsumerState<SelectArtist> {
  int selectedPrameIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;

    return Column(
      children: [
        Container(
            height: 116,
            padding: EdgeInsets.only(
              left: 36.w,
              top: 16.h,
            ),
            child: _buildSelectArtist()),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/mockup/prame/프레임 배경 1.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: 20.h),
                Consumer(builder:
                    (BuildContext context, WidgetRef ref, Widget? child) {
                  return Container(
                    height: 110.h,
                    padding: EdgeInsets.only(left: 36.w),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          SizedBox(width: 16.w),
                      itemBuilder: (context, index) {
                        return _buildSelectPrame(index);
                      },
                    ),
                  );
                }),
                SizedBox(height: 10.h),
                Container(
                    width: 180.w,
                    height: 277.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Hero(
                      tag: 'prame',
                      child: Image.asset(
                          'assets/mockup/prame/ko${selectedPrameIndex + 1}.png'),
                    )),
                SizedBox(height: 10.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(180.w, 49.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ref.read(parmePageIndexProvider.notifier).state = 1;
                  },
                  child: Text(
                    'Go Prame!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _buildSelectPrame(int index) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedPrameIndex = index;
          ref.read(prameSelectedIndexProvider.notifier).state = index;
        });
      },
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Opacity(
              opacity: selectedPrameIndex == index ? 1 : 0.2,
              child: Image.asset(
                'assets/mockup/prame/ko${index + 1}.png',
                width: 71.w,
                height: 110.h,
              ))),
    );
  }

  _buildSelectArtist() {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);
    return asyncCelebListState.when(
      data: (data) {
        final myCelebList = data.items
            .where((element) => element.users!
                .where((element) => element.id == userId)
                .isNotEmpty)
            .toList();

        return Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: myCelebList.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Image.network(
                      myCelebList[index].thumbnail,
                      width: 60.w,
                      height: 60.h,
                    ),
                    SizedBox(height: 4.h),
                    Text(data.items[index].nameKo,
                        style: getTextStyle(AppTypo.UI16B, AppColors.Gray900))
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('error'),
    );
  }
}
