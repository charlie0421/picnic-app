import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/services/vote_application_service_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'dart:async';

Future showVoteApplicationDialog({
  required BuildContext context,
  required VoteModel voteModel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return VoteApplicationDialog(
        vote: voteModel,
      );
    },
  );
}

class VoteApplicationDialog extends ConsumerStatefulWidget {
  final VoteModel vote;

  const VoteApplicationDialog({
    super.key,
    required this.vote,
  });

  @override
  ConsumerState<VoteApplicationDialog> createState() {
    return _VoteApplicationDialogState();
  }
}

class _VoteApplicationDialogState extends ConsumerState<VoteApplicationDialog> {
  late TextEditingController _reasonController;
  late FocusNode _reasonFocusNode;

  bool _isSubmitting = false;
  bool _isSearching = false;
  String? _errorMessage;
  ArtistModel? _selectedArtist;
  List<ArtistModel> _searchResults = [];
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _reasonFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _reasonFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedArtist = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await SearchService.searchArtists(
        query: query,
        page: 0,
        limit: 10,
        supportKoreanInitials: true,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      logger.e('아티스트 검색 실패', error: e);
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _selectArtist(ArtistModel artist) {
    setState(() {
      _selectedArtist = artist;
      _searchResults = [];
    });
  }

  Future<void> _submitApplication() async {
    if (_selectedArtist == null) {
      setState(() {
        _errorMessage = t('error_artist_not_selected');
      });
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = t('error_application_reason_required');
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userInfoAsync = ref.read(userInfoProvider);
      final userInfo = userInfoAsync.value;
      if (userInfo?.id == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final voteApplicationService = ref.read(voteApplicationServiceProvider);

      await voteApplicationService.submitApplication(
        voteId: widget.vote.id.toString(),
        userId: userInfo!.id!,
        title: getLocaleTextFromJson(_selectedArtist!.name),
        description: _reasonController.text.trim(),
        artistName: getLocaleTextFromJson(_selectedArtist!.name),
        groupName: _selectedArtist!.artistGroup != null
            ? getLocaleTextFromJson(_selectedArtist!.artistGroup!.name)
            : null,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        showSimpleDialog(
          title: t('success'),
          content: t('application_success'),
        );
      }
    } catch (e) {
      logger.e('투표 신청 실패', error: e);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: AppColors.grey00,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.grey200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t('vote_application_title'),
                      style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.grey600),
                  ),
                ],
              ),
            ),

            // 내용
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 투표 정보
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getLocaleTextFromJson(widget.vote.title),
                            style: getTextStyle(
                                AppTypo.body16B, AppColors.grey900),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '${t('vote_period')}: ${widget.vote.startAt?.toString().split(' ')[0]} ~ ${widget.vote.stopAt?.toString().split(' ')[0]}',
                            style: getTextStyle(
                                AppTypo.caption12R, AppColors.grey600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // 아티스트 검색 필드
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('artist_name_label'),
                          style:
                              getTextStyle(AppTypo.body14M, AppColors.grey700),
                        ),
                        SizedBox(height: 8.h),
                        EnhancedSearchBox(
                          hintText: t('search_artist_hint'),
                          onSearchChanged: _onSearchChanged,
                          showClearButton: true,
                          showSearchIcon: true,
                          autofocus: true,
                        ),
                        // 검색 결과 표시
                        if (_searchResults.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          _buildSearchResults(),
                        ],
                        // 선택된 아티스트 표시
                        if (_selectedArtist != null) ...[
                          SizedBox(height: 8.h),
                          _buildSelectedArtist(),
                        ],
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // 신청 사유 필드
                    _buildReasonField(),
                    SizedBox(height: 24.h),

                    // 오류 메시지
                    if (_errorMessage != null) ...[
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: getTextStyle(AppTypo.caption12R, Colors.red),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // 제출 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitApplication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.grey00),
                                ),
                              )
                            : Text(
                                t('submit_application'),
                                style: getTextStyle(
                                    AppTypo.body16B, AppColors.grey00),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('application_reason_label'),
          style: getTextStyle(AppTypo.body14M, AppColors.grey700),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey300),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: _reasonController,
            focusNode: _reasonFocusNode,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: t('application_reason_hint'),
              hintStyle: getTextStyle(AppTypo.body14R, AppColors.grey500),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.r),
            ),
            style: getTextStyle(AppTypo.body14R, AppColors.grey900),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      height: 200.h, // 고정 높이로 변경
      decoration: BoxDecoration(
        color: AppColors.grey00,
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isSearching
          ? _buildSearchLoading()
          : _searchResults.isEmpty
              ? _buildNoResults()
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final artist = _searchResults[index];
                    return _buildSearchResultItem(artist);
                  },
                ),
    );
  }

  Widget _buildSearchLoading() {
    return Container(
      padding: EdgeInsets.all(24.r),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              t('searching'),
              style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: EdgeInsets.all(24.r),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 24.r,
              color: AppColors.grey400,
            ),
            SizedBox(height: 8.h),
            Text(
              t('no_search_results'),
              style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 언어 감지 함수 (한국어 여부 확인)
  bool _isKorean(String text) {
    if (text.isEmpty) return false;
    // 한글 유니코드 범위: AC00-D7AF (가-힣), 1100-11FF (자모)
    final koreanRegex = RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]');
    return koreanRegex.hasMatch(text);
  }

  // 언어에 따른 텍스트 순서 결정
  List<String> _getOrderedTexts(String primaryText, String secondaryText) {
    if (_isKorean(primaryText)) {
      // 한국어인 경우: 한국어, 영어 순
      return [primaryText, secondaryText];
    } else {
      // 나머지 언어: 영어, 한국어 순
      return [secondaryText, primaryText];
    }
  }

  Widget _buildSearchResultItem(ArtistModel artist) {
    final artistNameKo = getLocaleTextFromJson(artist.name);
    final artistNameEn = artist.name?['en'] ?? '';
    final groupNameKo = artist.artistGroup != null
        ? getLocaleTextFromJson(artist.artistGroup!.name)
        : null;
    final groupNameEn = artist.artistGroup?.name?['en'] ?? '';

    // 아티스트명 순서 결정
    final orderedArtistNames = _getOrderedTexts(artistNameKo, artistNameEn);
    final primaryArtistName = orderedArtistNames[0];
    final secondaryArtistName = orderedArtistNames[1];

    // 그룹명 순서 결정
    final orderedGroupNames = groupNameKo != null
        ? _getOrderedTexts(groupNameKo, groupNameEn)
        : ['', ''];
    final primaryGroupName = orderedGroupNames[0];
    final secondaryGroupName = orderedGroupNames[1];

    return InkWell(
      onTap: () => _selectArtist(artist),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 아티스트 이미지
            Container(
              width: 40.w,
              height: 40.h,
              child: ClipOval(
                child: artist.image != null
                    ? PicnicCachedNetworkImage(
                        imageUrl: artist.image!,
                        fit: BoxFit.cover,
                        width: 40.w,
                        height: 40.h,
                      )
                    : Container(
                        color: AppColors.grey200,
                        child: Icon(
                          Icons.person,
                          color: AppColors.grey500,
                          size: 20.r,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            // 아티스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 아티스트 이름 (언어에 따라 순서 결정하여 한 줄에)
                  Row(
                    children: [
                      // 첫 번째 텍스트 (주 언어)
                      if (primaryArtistName.isNotEmpty)
                        Flexible(
                          child:
                              KoreanSearchUtils.buildConditionalHighlightText(
                            primaryArtistName,
                            _currentSearchQuery,
                            getTextStyle(AppTypo.body14B, AppColors.grey900),
                            highlightColor:
                                AppColors.primary500.withValues(alpha: 0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // 두 번째 텍스트 (보조 언어) - 오른쪽에 작은 폰트로
                      if (secondaryArtistName.isNotEmpty &&
                          secondaryArtistName != primaryArtistName) ...[
                        SizedBox(width: 8.w),
                        Flexible(
                          child:
                              KoreanSearchUtils.buildConditionalHighlightText(
                            secondaryArtistName,
                            _currentSearchQuery,
                            getTextStyle(AppTypo.caption12R, AppColors.grey500),
                            highlightColor:
                                AppColors.primary500.withValues(alpha: 0.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 그룹명 (언어에 따라 순서 결정하여 한 줄에)
                  if (primaryGroupName.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 12.r,
                          color: AppColors.grey500,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Row(
                            children: [
                              // 첫 번째 그룹명 (주 언어)
                              if (primaryGroupName.isNotEmpty)
                                Flexible(
                                  child: KoreanSearchUtils
                                      .buildConditionalHighlightText(
                                    primaryGroupName,
                                    _currentSearchQuery,
                                    getTextStyle(
                                        AppTypo.caption12R, AppColors.grey700),
                                    highlightColor: AppColors.primary500
                                        .withValues(alpha: 0.3),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              // 두 번째 그룹명 (보조 언어) - 오른쪽에 작은 폰트로
                              if (secondaryGroupName.isNotEmpty &&
                                  secondaryGroupName != primaryGroupName) ...[
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: KoreanSearchUtils
                                      .buildConditionalHighlightText(
                                    secondaryGroupName,
                                    _currentSearchQuery,
                                    getTextStyle(
                                        AppTypo.caption12R, AppColors.grey500),
                                    highlightColor: AppColors.primary500
                                        .withValues(alpha: 0.2),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // 선택 아이콘
            Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedArtist() {
    if (_selectedArtist == null) return const SizedBox.shrink();

    final artistNameKo = getLocaleTextFromJson(_selectedArtist!.name);
    final artistNameEn = _selectedArtist!.name?['en'] ?? '';
    final groupNameKo = _selectedArtist!.artistGroup != null
        ? getLocaleTextFromJson(_selectedArtist!.artistGroup!.name)
        : null;
    final groupNameEn = _selectedArtist!.artistGroup?.name?['en'] ?? '';

    // 선택된 아티스트명 순서 결정
    final orderedArtistNames = _getOrderedTexts(artistNameKo, artistNameEn);
    final primaryArtistName = orderedArtistNames[0];
    final secondaryArtistName = orderedArtistNames[1];

    // 선택된 그룹명 순서 결정
    final orderedGroupNames = groupNameKo != null
        ? _getOrderedTexts(groupNameKo, groupNameEn)
        : ['', ''];
    final primaryGroupName = orderedGroupNames[0];
    final secondaryGroupName = orderedGroupNames[1];

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 선택된 아티스트 이미지
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grey200,
            ),
            child: ClipOval(
              child: _selectedArtist!.image != null
                  ? PicnicCachedNetworkImage(
                      imageUrl: _selectedArtist!.image!,
                      fit: BoxFit.cover,
                      width: 32.w,
                      height: 32.h,
                    )
                  : Container(
                      color: AppColors.grey200,
                      child: Icon(
                        Icons.person,
                        color: AppColors.grey500,
                        size: 16.r,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 8.w),
          // 선택된 아티스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아티스트명 (언어에 따라 순서 결정하여 한 줄에)
                Row(
                  children: [
                    // 첫 번째 텍스트 (주 언어)
                    if (primaryArtistName.isNotEmpty)
                      Flexible(
                        child: Text(
                          primaryArtistName,
                          style: getTextStyle(
                              AppTypo.body14B, AppColors.primary500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    // 두 번째 텍스트 (보조 언어) - 오른쪽에 작은 폰트로
                    if (secondaryArtistName.isNotEmpty &&
                        secondaryArtistName != primaryArtistName) ...[
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          secondaryArtistName,
                          style: getTextStyle(
                              AppTypo.caption12R, AppColors.primary500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                // 그룹명 (언어에 따라 순서 결정하여 한 줄에)
                if (primaryGroupName.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      // 첫 번째 그룹명 (주 언어)
                      if (primaryGroupName.isNotEmpty)
                        Flexible(
                          child: Text(
                            primaryGroupName,
                            style: getTextStyle(
                                AppTypo.caption12R, AppColors.grey700),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      // 두 번째 그룹명 (보조 언어) - 오른쪽에 작은 폰트로
                      if (secondaryGroupName.isNotEmpty &&
                          secondaryGroupName != primaryGroupName) ...[
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            secondaryGroupName,
                            style: getTextStyle(
                                AppTypo.caption12R, AppColors.grey500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 체크 아이콘
          Icon(
            Icons.check_circle,
            color: AppColors.primary500,
            size: 20.r,
          ),
        ],
      ),
    );
  }
}
