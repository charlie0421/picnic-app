import 'package:animated_digit/animated_digit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/list/vote_detail_title.dart';
import 'package:picnic_app/components/vote/list/voting_dialog.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class VoteDetailPage extends ConsumerStatefulWidget {
  String pageName = Intl.message('page_title_vote_detail');
  final int voteId;

  VoteDetailPage({super.key, required this.voteId});

  @override
  ConsumerState<VoteDetailPage> createState() => _VoteDetailPageState();
}

class _VoteDetailPageState extends ConsumerState<VoteDetailPage> {
  late ScrollController _scrollController;
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  initState() {
    super.initState();
    _scrollController = ScrollController();
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });

      if (!_focusNode.hasFocus) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    _setupRealtime();
  }

  void handleInserts(PostgresChangePayload payload) {
    logger.d('Change received! $payload');
    final asyncVoteIgemListNotifier =
        ref.read(asyncVoteItemListProvider(voteId: widget.voteId).notifier);
    asyncVoteIgemListNotifier.setVoteItem(
        id: payload.newRecord['id'],
        voteTotal: payload.newRecord['vote_total']);
  }

  void _setupRealtime() {
    logger.d('Setting up realtime');
    final subscription = Supabase.instance.client
        .channel('realtime')
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'vote_item',
            callback: handleInserts)
        .subscribe();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildVoteInfo(context),
        _buildVoteItemList(context),
      ],
    );
  }

  Widget _buildVoteInfo(BuildContext context) {
    return ref.watch(asyncVoteDetailProvider(voteId: widget.voteId)).when(
          data: (voteModel) => Column(
            children: [
              Container(
                height: 200.h,
                color: AppColors.Gray200,
              ),
              SizedBox(
                height: 36.h,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 57).r,
                child: VoteCommonTitle(title: voteModel?.vote_title ?? ''),
              ),
              SizedBox(
                height: 12.h,
              ),
              SizedBox(
                height: 18.h,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: DateFormat('yyyy.MM.dd HH:mm')
                          .format(voteModel?.start_at ?? DateTime.now()),
                      style:
                          getTextStyle(AppTypo.CAPTION12R, AppColors.Gray900),
                    ),
                    const TextSpan(text: ' ~ '),
                    TextSpan(
                      text: DateFormat('yyyy.MM.dd HH:mm')
                          .format(voteModel?.start_at ?? DateTime.now()),
                      style:
                          getTextStyle(AppTypo.CAPTION12R, AppColors.Gray900),
                    ),
                    TextSpan(
                      text: '(KST)',
                      style:
                          getTextStyle(AppTypo.CAPTION12R, AppColors.Gray900),
                    )
                  ]),
                ),
              ),
              SizedBox(
                height: 26.h,
              ),
              SizedBox(
                  height: 21.h,
                  child: Text(
                    '랭크 인 리워드',
                    style: getTextStyle(AppTypo.BODY14B, AppColors.Primary500),
                  )),
              SizedBox(
                height: 4.h,
              ),
              SizedBox(
                  height: 24.h,
                  child: Text(
                    '홍대, 강남역 라이트박스(30일)',
                    style: getTextStyle(AppTypo.BODY16B, AppColors.Gray900),
                  )),
              SizedBox(
                height: 16.h,
              ),
            ],
          ),
          loading: () => buildLoadingOverlay(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }

  Widget _buildVoteItemList(BuildContext context) {
    return ref.watch(asyncVoteItemListProvider(voteId: widget.voteId)).when(
          data: (data) => Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.Primary500,
                      width: 1.r,
                    ),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(70.r),
                        topRight: Radius.circular(70.r),
                        bottomLeft: Radius.circular(40.r),
                        bottomRight: Radius.circular(40.r))),
                child: Padding(
                  padding: const EdgeInsets.only(top: 56).h,
                  child: Column(
                    children: data.map((item) {
                      int index = data.indexOf(item);

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Container(
                          key: ValueKey<int>(index), // 각 아이템에 고유한 키를 할당
                          height: 45.h,
                          margin: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 36)
                              .r,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 35.w,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (index < 3)
                                      SvgPicture.asset(
                                          'assets/icons/vote/crown${index + 1}.svg'),
                                    Text(
                                      '${index + 1}위',
                                      style: getTextStyle(AppTypo.CAPTION12B,
                                          AppColors.Point900),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 16.w,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: voteGradient,
                                  borderRadius: BorderRadius.circular(22.5.r),
                                ),
                                padding: const EdgeInsets.all(3),
                                width: 45.w,
                                height: 45.w,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22.5.r),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        data[index]!.mystar_member.image ?? '',
                                    fit: BoxFit.cover,
                                    width: 39.w,
                                    height: 39.w,
                                    placeholder: (context, url) =>
                                        buildPlaceholderImage(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 8.w,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(
                                        data[index]!.mystar_member.name_ko,
                                        style: getTextStyle(
                                            AppTypo.BODY14B, AppColors.Gray900),
                                      ),
                                      SizedBox(
                                        width: 8.w,
                                      ),
                                      Text(
                                        data[index]!
                                                .mystar_member
                                                .mystar_group
                                                ?.name_ko ??
                                            '',
                                        style: getTextStyle(AppTypo.CAPTION10SB,
                                            AppColors.Gray600),
                                      ),
                                    ]),
                                    Container(
                                      width: double.infinity,
                                      height: 20.h,
                                      padding: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        gradient: commonGradient,
                                        color: AppColors.Gray100,
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                      ),
                                      alignment: Alignment.centerRight,
                                      child: AnimatedDigitWidget(
                                        value: data[index]!.vote_total,
                                        duration:
                                            const Duration(microseconds: 300),
                                        curve: Curves.fastOutSlowIn,
                                        enableSeparator: true,
                                        textStyle: getTextStyle(
                                            AppTypo.CAPTION10SB,
                                            AppColors.Gray00),
                                      ),
                                      // child: Text(
                                      //   NumberFormat()
                                      //       .format(data[index]!.vote_total),
                                      //   style: getTextStyle(
                                      //       context,
                                      //       AppTypo.CAPTION10SB,
                                      //       AppColors.Gray00),
                                      // ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 16.w,
                              ),
                              SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: GestureDetector(
                                  onTap: () {
                                    showVotingDialog(
                                        context: context,
                                        voteModel: ref
                                            .watch(asyncVoteDetailProvider(
                                                voteId: widget.voteId))
                                            .value!,
                                        voteItemModel: data[index]!);
                                  },
                                  child: SvgPicture.asset(
                                      'assets/icons/vote/vote_button.svg'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 10.w,
                left: 10.w,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: 280.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.Primary500,
                        width: 1.r,
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                      color: AppColors.Gray00,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16).w,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/vote/search_icon.svg',
                            width: 20.w,
                            height: 20.w,
                          ),
                          SizedBox(
                            width: 8.w,
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 36.h,
                              child: TextFormField(
                                cursorHeight: 16.h,
                                cursorColor: AppColors.Primary500,
                                focusNode: _focusNode,
                                controller: _textEditingController,
                                decoration: InputDecoration(
                                  hintText: '나의 최애는 어디에?',
                                  hintStyle: getTextStyle(
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
                  ),
                ),
              ),
            ],
          ),
          loading: () => buildLoadingOverlay(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }
}
