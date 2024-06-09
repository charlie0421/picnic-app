import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:picnic_app/providers/celeb_list_provider.dart';
import 'package:picnic_app/providers/pic_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class SelectArtist extends ConsumerStatefulWidget {
  const SelectArtist({super.key});

  @override
  createState() => _SelectArtistState();
}

class _SelectArtistState extends ConsumerState<SelectArtist> {
  int selectedPicIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadOverlayImage() async {
    final ByteData data = await rootBundle.load(
        'assets/mockup/pic/che${ref.watch(picSelectedIndexProvider) + 1}.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final img.Image image = img.decodeImage(bytes)!;
    final uiImage = await _convertImage(image);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;

    return ListView(
      children: [
        Container(
            height: 100.h,
            padding: EdgeInsets.only(
              left: 36.w,
              top: 8.h,
            ),
            child: _buildSelectArtist()),
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/mockup/pic/프레임 배경 1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Consumer(builder:
                  (BuildContext context, WidgetRef ref, Widget? child) {
                return Container(
                  height: 90.h,
                  padding: EdgeInsets.only(left: 36.w),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (context, index) => SizedBox(width: 16.w),
                    itemBuilder: (context, index) {
                      return _buildSelectPic(index);
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
                    tag: 'pic',
                    child: Image.asset(
                        'assets/mockup/pic/che${selectedPicIndex + 1}.png'),
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
                  _showCameraView();
                },
                child: Text(
                  'Go Pic!',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _buildSelectPic(int index) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedPicIndex = index;
          ref.read(picSelectedIndexProvider.notifier).state = index;
        });
      },
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Opacity(
              opacity: selectedPicIndex == index ? 1 : 0.2,
              child: Image.asset(
                'assets/mockup/pic/che${index + 1}.png',
                width: 71.w,
                height: 110.h,
              ))),
    );
  }

  _buildSelectArtist() {
    final asyncCelebListState = ref.watch(asyncCelebListProvider);

    return asyncCelebListState.when(
      data: (data) {
        return Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data?.length ?? 0,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        data?[index].thumbnail ?? '',
                        width: 60.w,
                        height: 60.h,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(data?[index].name_ko ?? '',
                        style: getTextStyle(AppTypo.BODY16B, AppColors.Gray900))
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => buildLoadingOverlay(),
      error: (error, stackTrace) => const Text('error'),
    );
  }

  void _showCameraView() {
    Navigator.pushNamed(context, '/pic-camera');
    // ref.read(navigationInfoProvider.notifier).setCurrentPage(
    //     PicCameraViewPage(),
    //     showTopMenu: false,
    //     showBottomNavigation: false);
    // showModalBottomSheet(
    //     context: context,
    //     useSafeArea: true,
    //     isScrollControlled: true,
    //     useRootNavigator: true,
    //     showDragHandle: false,
    //     builder: (BuildContext context) {
    //       return PicCameraViewPage();
    //     });
  }

  Future<ui.Image> _convertImage(img.Image image) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.fromList(img.encodePng(image)), (uiImage) {
      completer.complete(uiImage);
    });
    return completer.future;
  }
}
