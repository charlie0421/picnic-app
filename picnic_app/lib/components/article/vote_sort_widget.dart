// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:picnic_app/providers/article_list_provider.dart';
// import 'package:picnic_app/ui/style.dart';
//
// class VoteSortWidget extends ConsumerWidget {
//   final int galleryId;
//
//   const VoteSortWidget({
//     super.key,
//     required this.galleryId,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final sortOptionState = ref.watch(sortOptionProvider);
//     final sortOptionNotifier = ref.read(sortOptionProvider.notifier);
//     final asyncArticleListNotifier =
//         ref.read(asyncArticleListProvider(galleryId).notifier);
//
//     return InkWell(
//         onTap: () => showModalBottomSheet(
//               context: context,
//               showDragHandle: true,
//               builder: (context) {
//                 return StatefulBuilder(
//                   builder: (BuildContext context, StateSetter setState) {
//                     return SafeArea(
//                       child: Container(
//                         height:224,
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text('정렬 방식 선택',
//                                     style: getTextStyle(
//                                         AppTypo.BODY16B, AppColors.Grey900)),
//                                 IconButton(
//                                     onPressed: () {
//                                       Navigator.pop(context);
//                                     },
//                                     icon: Icon(
//                                       Icons.close,
//                                       size: 18.w,
//                                     )),
//                               ],
//                             ),
//                             ListView.separated(
//                               physics: const NeverScrollableScrollPhysics(),
//                               shrinkWrap: true,
//                               itemCount: 3,
//                               separatorBuilder: (context, index) =>
//                                   const Divider(
//                                 height: 1,
//                                 color: AppColors.Grey100,
//                               ),
//                               itemBuilder: (context, index) {
//                                 switch (index) {
//                                   case 0:
//                                     return InkWell(
//                                       onTap: () {
//                                         String sort = 'id';
//                                         String order = 'DESC';
//
//                                         sortOptionNotifier.setSortOption(
//                                             sort, order);
//                                         asyncArticleListNotifier.clearItems();
//                                         asyncArticleListNotifier.fetch(
//                                             galleryId: galleryId,
//                                             sort: sort,
//                                             order: order,
//                                             page: 1,
//                                             limit: 10);
//                                         Navigator.pop(context);
//                                       },
//                                       child: Container(
//                                         alignment: Alignment.centerLeft,
//                                         height:56,
//                                         child: Row(
//                                           children: [
//                                             sortOptionState.sort == 'id'
//                                                 ? SvgPicture.asset(
//                                                     'assets/icons/check_green.svg',
//                                                     width: 18.w,
//                                                     height:18,
//                                                   )
//                                                 : SizedBox(width: 18.w),
//                                             SizedBox(width: 8.w),
//                                             Text('최신 등록순',
//                                                 style:
//                                                     sortOptionState.sort == 'id'
//                                                         ? getTextStyle(
//                                                             AppTypo.BODY16B,
//                                                             AppColors.Grey500)
//                                                         : getTextStyle(
//                                                             AppTypo.BODY16M,
//                                                             AppColors.Grey900)),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   case 1:
//                                     return InkWell(
//                                       onTap: () {
//                                         String sort = 'viewCount';
//                                         String order = 'DESC';
//
//                                         sortOptionNotifier.setSortOption(
//                                             sort, order);
//                                         asyncArticleListNotifier.clearItems();
//                                         asyncArticleListNotifier.fetch(
//                                             galleryId: galleryId,
//                                             sort: sort,
//                                             order: order,
//                                             page: 1,
//                                             limit: 10);
//
//                                         Navigator.pop(context);
//                                       },
//                                       child: Container(
//                                         alignment: Alignment.centerLeft,
//                                         height:56,
//                                         child: Row(
//                                           children: [
//                                             sortOptionState.sort == 'viewCount'
//                                                 ? SvgPicture.asset(
//                                                     'assets/icons/check_green.svg',
//                                                     width: 18.w,
//                                                     height:18,
//                                                   )
//                                                 : SizedBox(width: 18.w),
//                                             SizedBox(width: 8.w),
//                                             Text('저장순',
//                                                 style: sortOptionState.sort ==
//                                                         'viewCount'
//                                                     ? getTextStyle(
//                                                         AppTypo.BODY16B,
//                                                         AppColors.Grey500)
//                                                     : getTextStyle(
//                                                         AppTypo.BODY16M,
//                                                         AppColors.Grey900)),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   case 2:
//                                     return InkWell(
//                                       onTap: () {
//                                         String sort = 'commentCount';
//                                         String order = 'DESC';
//
//                                         sortOptionNotifier.setSortOption(
//                                             sort, order);
//                                         asyncArticleListNotifier.clearItems();
//                                         asyncArticleListNotifier.fetch(
//                                             galleryId: galleryId,
//                                             sort: sort,
//                                             order: order,
//                                             page: 1,
//                                             limit: 10);
//                                         Navigator.pop(context);
//                                       },
//                                       child: Container(
//                                         alignment: Alignment.centerLeft,
//                                         height:56,
//                                         child: Row(
//                                           children: [
//                                             sortOptionState.sort ==
//                                                     'commentCount'
//                                                 ? SvgPicture.asset(
//                                                     'assets/icons/check_green.svg',
//                                                     width: 18.w,
//                                                     height:18,
//                                                   )
//                                                 : SizedBox(width: 18.w),
//                                             SizedBox(width: 8.w),
//                                             Text('댓글 순',
//                                                 style: sortOptionState.sort ==
//                                                         'commentCount'
//                                                     ? getTextStyle(
//                                                         AppTypo.BODY16B,
//                                                         AppColors.Grey500)
//                                                     : getTextStyle(
//                                                         AppTypo.BODY16M,
//                                                         AppColors.Grey900)),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//         child: Container(
//           width: 102.w,
//           height:30,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8).r,
//             border: Border.all(color: AppColors.Grey100),
//           ),
//           padding: const EdgeInsets.symmetric(horizontal: 4).w,
//           margin: const EdgeInsets.only(right: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Expanded(
//                 child: Align(
//                   alignment: Alignment.center,
//                   child: Text(
//                     sortOptionState.sort == 'id'
//                         ? '최신 등록순'
//                         : sortOptionState.sort == 'viewCount'
//                             ? '조회순'
//                             : sortOptionState.sort == 'commentCount'
//                                 ? '댓글순'
//                                 : '',
//                     style: getTextStyle(AppTypo.BODY14M, AppColors.Grey600),
//                   ),
//                 ),
//               ),
//               SvgPicture.asset(
//                 'assets/icons/arrow_down_style=line.svg',
//                 width: 18.w,
//                 height:18,
//               )
//             ],
//           ),
//         ));
//   }
// }
