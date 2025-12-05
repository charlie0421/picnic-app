import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/media_embed_builder.dart';
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

  // answer_delta에서 해당 언어의 Delta 가져오기
  Map<String, dynamic>? _getLocalizedDelta(
    Map<String, dynamic>? answerDelta,
    String language,
  ) {
    if (answerDelta == null) return null;
    if (answerDelta[language] != null) {
      return answerDelta[language] as Map<String, dynamic>?;
    }
    if (answerDelta['ko'] != null) {
      return answerDelta['ko'] as Map<String, dynamic>?;
    }
    return null;
  }

  // Delta를 QuillEditor로 렌더링
  Widget _buildQuillViewer(Map<String, dynamic> delta) {
    try {
      final ops = delta['ops'] as List?;
      if (ops == null || ops.isEmpty) {
        return const SizedBox.shrink();
      }

      final document = quill.Document.fromJson(ops);
      final controller = quill.QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return quill.QuillEditor(
        controller: controller,
        scrollController: ScrollController(),
        focusNode: FocusNode(),
        config: quill.QuillEditorConfig(
          showCursor: false,
          autoFocus: false,
          expands: false,
          padding: EdgeInsets.zero,
          embedBuilders: [
            NetworkImageEmbedBuilder(enableFullScreen: true),
          ],
        ),
      );
    } catch (e) {
      logger.e('FAQ Delta 렌더링 오류', error: e);
      // 폴백: Delta에서 plain text 추출
      return Text(
        _extractPlainTextFromDelta(delta),
        style: getTextStyle(AppTypo.body14M, AppColors.grey700),
      );
    }
  }

  // Delta에서 plain text 추출 (폴백용)
  String _extractPlainTextFromDelta(Map<String, dynamic> delta) {
    final ops = delta['ops'] as List?;
    if (ops == null) return '';
    return ops
        .where((op) => op is Map && op['insert'] is String)
        .map((op) => op['insert'] as String)
        .join();
  }

  // 답변 위젯 빌더
  Widget _buildAnswer(Map<String, dynamic> faq, String language) {
    final answerDelta =
        faq['answer_delta'] as Map<String, dynamic>?;
    final delta = _getLocalizedDelta(answerDelta, language);

    if (delta != null) {
      return _buildQuillViewer(delta);
    }

    // 폴백: 레거시 텍스트 렌더링
    return Text(
      _getLocalizedText(faq['answer'], language),
      style: getTextStyle(AppTypo.body14M, AppColors.grey700),
    );
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
                          child: _buildAnswer(faq, currentLanguage),
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
