import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

class FAQPage extends ConsumerStatefulWidget {
  const FAQPage({super.key});

  @override
  ConsumerState<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends ConsumerState<FAQPage>
    with RouteAwareStateMixin<FAQPage> {
  List<Map<String, dynamic>> _faqs = [];
  String? _selectedCategory;
  List<String> _categories = ['ALL'];
  List<Map<String, dynamic>> _categoriesData = [];
  String? _currentTitle;

  String _getLocalizedText(Map<String, dynamic> json, String language) {
    if (json[language] != null) {
      return json[language];
    }
    return json['en'] ?? '';
  }

  String _getLocalizedCategoryLabel(String categoryCode, String language) {
    if (categoryCode == 'ALL') {
      return AppLocalizations.of(context).faq_category_all;
    }
    try {
      final Map<String, dynamic> found = _categoriesData.firstWhere(
        (c) => c['code'] == categoryCode,
        orElse: () => <String, dynamic>{},
      );
      if (found.isNotEmpty && found['label'] is Map<String, dynamic>) {
        return _getLocalizedText(
          found['label'] as Map<String, dynamic>,
          language,
        );
      }
    } catch (_) {}
    return categoryCode;
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'ALL';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTitle = AppLocalizations.of(context).label_mypage_faq;
      _updateNavigation();
      _fetchPage();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).label_mypage_faq;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  Future<void> _fetchPage() async {
    try {
      final client = Supabase.instance.client;

      final faqsFuture = client
          .from('faqs')
          .select()
          .eq('status', 'PUBLISHED')
          .order('order_number');

      final categoriesFuture = client
          .from('faq_categories')
          .select('code,label,order_number,active')
          .eq('active', true)
          .order('order_number');

      final results = await Future.wait([faqsFuture, categoriesFuture]);
      final faqsResponse = results[0] as List<dynamic>;
      final categoriesResponse = results[1] as List<dynamic>;

      setState(() {
        _faqs = faqsResponse.cast<Map<String, dynamic>>();
        _categoriesData = categoriesResponse.cast<Map<String, dynamic>>();
        _categories = [
          'ALL',
          ..._categoriesData.map((e) => e['code']).whereType<String>(),
        ];
      });
    } catch (error) {
      logger.e('FAQ 데이터 가져오기 오류', error: error);
    }
  }

  List<Map<String, dynamic>> _getFilteredFaqs() {
    if (_selectedCategory == 'ALL') {
      return _faqs;
    }
    return _faqs.where((faq) => faq['category'] == _selectedCategory).toList();
  }

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(
            pageTitle: title,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(appSettingProvider).language;
    final filteredFaqs = _getFilteredFaqs();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(
                      _getLocalizedCategoryLabel(category, currentLanguage),
                      style: getTextStyle(
                        AppTypo.caption12M,
                        _selectedCategory == category
                            ? AppColors.grey00
                            : AppColors.grey700,
                      ),
                    ),
                    selected: _selectedCategory == category,
                    selectedColor: AppColors.primary500,
                    backgroundColor: AppColors.grey100,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: filteredFaqs.isNotEmpty
              ? ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  itemCount: filteredFaqs.length,
                  itemBuilder: (context, index) {
                    final faq = filteredFaqs[index];
                    return ExpansionTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (faq['category'] != null)
                            Text(
                              _getLocalizedCategoryLabel(
                                faq['category'],
                                currentLanguage,
                              ),
                              style: getTextStyle(
                                AppTypo.body14M,
                                AppColors.primary500,
                              ),
                            ),
                          SizedBox(height: 4.h),
                          Text(
                            _getLocalizedText(faq['question'], currentLanguage),
                            style: getTextStyle(
                              AppTypo.body14B,
                              AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Text(
                            _getLocalizedText(faq['answer'], currentLanguage),
                            style: getTextStyle(
                              AppTypo.body14M,
                              AppColors.grey700,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : NoItemContainer(
                  message: AppLocalizations.of(
                    context,
                  ).common_text_no_search_result,
                ),
        ),
      ],
    );
  }
}
