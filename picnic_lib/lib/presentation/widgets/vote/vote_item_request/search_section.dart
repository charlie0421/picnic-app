import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/ui/style.dart';

/// 검색 섹션 위젯
class SearchSection extends StatelessWidget {
  final Function(String) onSearchChanged;

  const SearchSection({
    super.key,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary500,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .vote_item_request_search_artist,
                      style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '새로운 아티스트를 찾아 투표에 추가하세요',
                      style:
                          getTextStyle(AppTypo.caption12R, AppColors.grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          EnhancedSearchBox(
            hintText: AppLocalizations.of(context)
                .vote_item_request_search_artist_hint,
            onSearchChanged: onSearchChanged,
            showClearButton: true,
            showSearchIcon: true,
            autofocus: false,
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
