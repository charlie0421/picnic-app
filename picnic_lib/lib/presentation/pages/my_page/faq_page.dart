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
import 'package:picnic_lib/presentation/pages/my_page/faq_page_helper.dart';

class FAQContent {
  const FAQContent({required this.faqs, required this.categories});

  final List<Map<String, dynamic>> faqs;
  final List<Map<String, dynamic>> categories;
}

typedef FAQContentLoader = Future<FAQContent> Function();

class FAQPage extends ConsumerStatefulWidget {
  const FAQPage({super.key, this.loadContent});

  final FAQContentLoader? loadContent;

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
  bool _isLoading = true;
  Object? _loadError;
  int _loadGeneration = 0;

  String _getLocalizedText(Map<String, dynamic> json, String language) {
    return FAQPageHelper.getLocalizedText(json, language);
  }

  // answer_delta에서 해당 언어의 Delta 가져오기
  Map<String, dynamic>? _getLocalizedDelta(
    Map<String, dynamic>? answerDelta,
    String language,
  ) {
    return FAQPageHelper.getLocalizedDelta(answerDelta, language);
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
          embedBuilders: [NetworkImageEmbedBuilder(enableFullScreen: true)],
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
    return FAQPageHelper.extractPlainTextFromDelta(delta);
  }

  // 답변 위젯 빌더
  Widget _buildAnswer(Map<String, dynamic> faq, String language) {
    final answerDelta = faq['answer_delta'] as Map<String, dynamic>?;
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
    return FAQPageHelper.getLocalizedCategoryLabel(
      categoryCode,
      language,
      _categoriesData,
      allLabel: AppLocalizations.of(context).faq_category_all,
    );
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
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        if (_faqs.isEmpty) _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final content = await (widget.loadContent?.call() ?? _loadContent());

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _faqs = content.faqs;
        _categoriesData = content.categories;
        _categories = FAQPageHelper.buildCategoriesList(_categoriesData);
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'ALL';
        }
        _isLoading = false;
      });
    } catch (error) {
      logger.e('FAQ 데이터 가져오기 오류', error: error);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<FAQContent> _loadContent() async {
    final client = Supabase.instance.client;
    final results = await Future.wait([
      client
          .from('faqs')
          .select()
          .eq('status', 'PUBLISHED')
          .order('order_number'),
      client
          .from('faq_categories')
          .select('code,label,order_number,active')
          .eq('active', true)
          .order('order_number'),
    ]);
    return FAQContent(
      faqs: (results[0] as List<dynamic>).cast<Map<String, dynamic>>(),
      categories: (results[1] as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }

  List<Map<String, dynamic>> _getFilteredFaqs() {
    return FAQPageHelper.getFilteredFaqs(_faqs, _selectedCategory);
  }

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: title);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(appSettingProvider).language;
    final filteredFaqs = _getFilteredFaqs();

    if (_isLoading && _faqs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null && _faqs.isEmpty) return _buildError(context);

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
          child: RefreshIndicator(
            onRefresh: _fetchPage,
            child: filteredFaqs.isNotEmpty || _loadError != null
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    itemCount:
                        filteredFaqs.length + (_loadError == null ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (_loadError != null && index == 0) {
                        return _buildError(context, compact: true);
                      }
                      final faqIndex = index - (_loadError == null ? 0 : 1);
                      final faq = filteredFaqs[faqIndex];
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
                              _getLocalizedText(
                                faq['question'],
                                currentLanguage,
                              ),
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
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.55,
                        child: NoItemContainer(
                          message: AppLocalizations.of(
                            context,
                          ).common_text_no_search_result,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, {bool compact = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context).message_error_occurred,
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              key: const ValueKey('faq-retry'),
              onPressed: _fetchPage,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).label_retry),
            ),
          ],
        ),
      ),
    );
  }
}
