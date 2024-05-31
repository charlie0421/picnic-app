import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/ui/style.dart';

Future showVotingDialog({
  required BuildContext context,
  required VoteModel voteModel,
  required VoteItemModel voteItemModel,
}) {
  return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return VotingDialog(
          voteModel: voteModel,
          voteItemModel: voteItemModel,
        );
      });
}

class VotingDialog extends Dialog {
  final VoteModel voteModel;
  final VoteItemModel voteItemModel;

  VotingDialog(
      {super.key, required this.voteModel, required this.voteItemModel}) {
    _scrollController = ScrollController();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  late ScrollController _scrollController;
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _hasFocus = false;

  bool _checkAll = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (context, setState) => Container(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                          top: 64, left: 24, right: 24, bottom: 36)
                      .r,
                  decoration: BoxDecoration(
                      color: AppColors.Gray00,
                      border: Border.all(
                        color: AppColors.Mint500,
                        width: 2.r,
                      ),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(120.r),
                          topRight: Radius.circular(120.r),
                          bottomLeft: Radius.circular(120.r),
                          bottomRight: Radius.circular(120.r))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100.r),
                        child: CachedNetworkImage(
                          imageUrl: voteItemModel.mystar_member.image ?? '',
                          width: 100.w,
                          height: 100.w,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 24.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              voteItemModel.mystar_member.name_ko ?? '',
                              style: getTextStyle(
                                  context, AppTypo.BODY16B, AppColors.Gray900),
                            ),
                            SizedBox(
                              width: 8.w,
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                voteItemModel
                                        .mystar_member.mystar_group?.name_ko ??
                                    '',
                                style: getTextStyle(context, AppTypo.CAPTION12R,
                                    AppColors.Gray600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      const Divider(
                        color: AppColors.Gray300,
                        height: 1,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        height: 32.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/header/star.png',
                              width: 24.w,
                              height: 24.w,
                            ),
                            SizedBox(
                              width: 12.w,
                            ),
                            Expanded(
                              child: Text('12,000',
                                  style: getTextStyle(context, AppTypo.BODY16B,
                                          AppColors.Primary500)
                                      .copyWith(
                                    fontSize: 20.sp,
                                  )),
                            ),
                            Container(
                              height: 32.h,
                              padding: EdgeInsets.only(
                                left: 20.w,
                                right: 18.w,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.Mint500,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                children: [
                                  Text('충전하기',
                                      style: getTextStyle(
                                          context,
                                          AppTypo.BODY14B,
                                          AppColors.Primary500)),
                                  SvgPicture.asset(
                                    'assets/icons/vote/recharge-plus.svg',
                                    width: 16.w,
                                    height: 16.h,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _checkAll = !_checkAll;
                              });
                            },
                            child: _checkAll
                                ? SvgPicture.asset(
                                    'assets/icons/vote/checkbox.svg',
                                    width: 24.w,
                                    height: 24.w,
                                    colorFilter: const ColorFilter.mode(
                                        AppColors.Gray300, BlendMode.srcIn),
                                  )
                                : SvgPicture.asset(
                                    'assets/icons/vote/checkbox.svg',
                                    width: 24.w,
                                    height: 24.w,
                                    colorFilter: const ColorFilter.mode(
                                        AppColors.Primary500, BlendMode.srcIn),
                                  ),
                          ),
                          SizedBox(width: 4.w),
                          Text('전체사용',
                              style: getTextStyle(
                                  context, AppTypo.BODY14M, AppColors.Gray400)),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.Primary500,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(24).r,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16).w,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36.h,
                                child: TextFormField(
                                  cursorHeight: 16.h,
                                  cursorColor: AppColors.Primary500,
                                  focusNode: _focusNode,
                                  controller: _textEditingController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '입력',
                                    hintStyle: getTextStyle(context,
                                        AppTypo.BODY16R, AppColors.Gray300),
                                    border: InputBorder.none,
                                    focusColor: AppColors.Primary500,
                                    fillColor: AppColors.Gray900,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _textEditingController.clear();
                              },
                              child: SvgPicture.asset(
                                'assets/icons/vote/cancel.svg',
                                width: 20.w,
                                height: 20.w,
                                colorFilter: ColorFilter.mode(
                                    _hasFocus
                                        ? AppColors.Gray700
                                        : AppColors.Gray200,
                                    BlendMode.srcIn),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 28.h),
                      Container(
                        width: 172.w,
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: AppColors.Primary500,
                          borderRadius: BorderRadius.circular(24).r,
                        ),
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text('투표하기',
                              style: getTextStyle(context, AppTypo.TITLE18SB,
                                  AppColors.Gray00)),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                    child: Container(
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.symmetric(horizontal: 32).w,
                        child: VoteDetailTitle(
                          voteModel: voteModel,
                        ))),
                Positioned.fill(
                    child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: SvgPicture.asset(
                              'assets/icons/vote/close.svg',
                              width: 24.w,
                              height: 24.w,
                            )))),
              ],
            ),
          ),
        ));
  }
}
