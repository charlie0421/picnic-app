import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:prame_app/providers/prame_provider.dart';

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
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (context, index) => SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildSelectArtist(index);
            },
          ),
        ),
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
                Container(
                  height: 110.h,
                  padding: EdgeInsets.only(left: 36.w),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (context, index) => SizedBox(width: 16.w),
                    itemBuilder: (context, index) {
                      return _buildSelectPrame(index);
                    },
                  ),
                ),
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

    // return Stack(
    //   children: [
    //     if (_userImage != null)
    //       Container(
    //         decoration: BoxDecoration(
    //           image: DecorationImage(
    //             image: FileImage(_userImage!),
    //             fit: BoxFit.cover,
    //           ),
    //         ),
    //       ),
    //     Container(
    //         alignment: Alignment.bottomRight,
    //         child: Image.asset('assets/mockup/prame/고윤정 고화질3 1.png')),
    //     Row(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         ElevatedButton(
    //           onPressed: getImage,
    //           child: Text('사진첩'),
    //         ),
    //         if (cameras != null && cameras!.isNotEmpty) SizedBox(width: 16),
    //         if (cameras != null && cameras!.isNotEmpty)
    //           ElevatedButton(
    //             onPressed: () {
    //               showModalBottomSheet(
    //                 context: context,
    //                 isScrollControlled: true,
    //                 builder: (BuildContext context) {
    //                   return StatefulBuilder(builder:
    //                       (BuildContext context, StateSetter setState) {
    //                     logger.i('build');
    //                     return SizedBox(
    //                       height: MediaQuery.of(context)
    //                           .size
    //                           .height, // 전체 화면 높이를 사용
    //                       child: Stack(
    //                         alignment: Alignment.center,
    //                         children: [
    //                           CameraPreview(
    //                             controller!,
    //                             child: CustomPaint(
    //                               size: Size.infinite,
    //                               painter: OverlayImagePainter(
    //                                   overlayImage: _overlayImage),
    //                             ),
    //                           ),
    //                           Container(
    //                             width: double.infinity,
    //                             alignment: Alignment.bottomCenter,
    //                             padding: const EdgeInsets.only(bottom: 100),
    //                             child: Row(
    //                               mainAxisAlignment: MainAxisAlignment.center,
    //                               children: [
    //                                 ElevatedButton(
    //                                   onPressed: () async {
    //                                     final XFile file =
    //                                         await controller!.takePicture();
    //                                     final img.Image image = img.decodeImage(
    //                                         await file.readAsBytes())!;
    //                                     final uiImage =
    //                                         await _convertImage(image);
    //                                     setState(() {
    //                                       _userImage = File(file.path);
    //                                       _convertedUserImage = uiImage;
    //                                     });
    //                                     Navigator.pop(context);
    //                                   },
    //                                   child: Text('사진 찍기'),
    //                                 ),
    //                                 SizedBox(width: 16),
    //                                 if (cameras != null && cameras!.isNotEmpty)
    //                                   ElevatedButton(
    //                                     onPressed: () async {
    //                                       _toggleCamera();
    //                                       Future.delayed(
    //                                           Duration(milliseconds: 1000), ()
    //                                       {
    //                                         setState(() {});
    //                                       });
    //                                     },
    //                                     child: Text('카메라 전환'),
    //                                   ),
    //                               ],
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                     );
    //                   });
    //                 },
    //               );
    //             },
    //             child: Text('카메라'),
    //           ),
    //       ],
    //     )
    //   ],
    // );
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

  List<String> artistList = ['이도현', '고윤정', '한소희', '김우빈', '문상민'];

  _buildSelectArtist(int index) {
    return Container(
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/mockup/prame/prame${index + 1}.png',
              width: 60.w,
              height: 60.h,
            ),
            SizedBox(height: 8.h),
            Text(
              artistList[index],
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            )
          ],
        ));
  }
}
