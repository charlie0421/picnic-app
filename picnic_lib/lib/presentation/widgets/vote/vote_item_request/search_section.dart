import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

/// 검색 섹션 위젯
class SearchSection extends StatelessWidget {
  final Function(String) onSearchChanged;

  const SearchSection({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: PicnicUi.horizontal(12),
        vertical: PicnicUi.vertical(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PicnicUi.horizontal(8),
                  vertical: PicnicUi.vertical(8),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary500,
                  size: 16,
                ),
              ),
              SizedBox(width: PicnicUi.horizontal(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      ).vote_item_request_search_artist,
                      style: PicnicUi.text(
                        size: 16,
                        weight: FontWeight.w600,
                        color: PicnicUi.ink,
                      ),
                    ),
                    SizedBox(height: PicnicUi.vertical(4)),
                    Text(
                      '새로운 아티스트를 찾아 투표에 추가하세요',
                      style: PicnicUi.text(
                        size: 12,
                        color: PicnicUi.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: PicnicUi.vertical(16)),
          EnhancedSearchBox(
            hintText: AppLocalizations.of(
              context,
            ).vote_item_request_search_artist_hint,
            onSearchChanged: onSearchChanged,
            showClearButton: true,
            showSearchIcon: true,
            autofocus: false,
          ),
          SizedBox(height: PicnicUi.vertical(24)),
        ],
      ),
    );
  }
}
