import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/community/compatibility.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_input_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_loading_page.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_result_page.dart';
import 'package:picnic_lib/presentation/providers/community/compatibility_list_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilityListPage extends ConsumerStatefulWidget {
  final int? artistId;

  const CompatibilityListPage({super.key, this.artistId});

  @override
  ConsumerState<CompatibilityListPage> createState() =>
      _CompatibilityListPageState();
}

class _CompatibilityListPageState extends ConsumerState<CompatibilityListPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isInitialLoading = true; // 초기 로딩 상태 추가

  // 스켈레톤 애니메이션 컨트롤러
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 CompatibilityListPage: initState 시작');

    // 스켈레톤 애니메이션 초기화
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
    _shimmerController.repeat();

    _safeInitialize();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _safeInitialize() async {
    try {
      debugPrint('🔧 CompatibilityListPage: 안전한 초기화 시작');

      // 다음 프레임에서 실행하여 위젯 트리가 완전히 빌드된 후 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performInitialLoad();
        }
      });

      debugPrint('✅ CompatibilityListPage: 초기화 완료');
    } catch (e, stackTrace) {
      debugPrint('❌ CompatibilityListPage: 초기화 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = '초기화 중 오류가 발생했습니다: $e';
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _performInitialLoad() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 CompatibilityListPage: 초기 로딩 트리거');

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ CompatibilityListPage: 사용자 미인증');
        if (mounted) {
          setState(() {
            _errorMessage = '로그인이 필요합니다.';
            _isInitialLoading = false;
          });
        }
        return;
      }

      debugPrint('👤 CompatibilityListPage: 사용자 인증 상태 - ${user.id}');

      if (!mounted) return;

      final historyProvider =
          compatibilityListProvider(artistId: widget.artistId);
      debugPrint('📊 CompatibilityListPage: Provider 호출 시작');

      final artistId = widget.artistId;
      debugPrint('🎯 CompatibilityListPage: artistId = $artistId');

      debugPrint(
          '📈 CompatibilityListPage: 현재 상태 - items: ${ref.read(historyProvider).items.length}, isLoading: ${ref.read(historyProvider).isLoading}, hasMore: ${ref.read(historyProvider).hasMore}');

      debugPrint('⏳ CompatibilityListPage: loadInitial() 실행 시작...');
      await ref.read(historyProvider.notifier).loadInitial();
      debugPrint('✅ CompatibilityListPage: loadInitial() 실행 완료');

      // 더 긴 시간 대기하여 Provider 상태 변화 기다림
      await Future.delayed(const Duration(milliseconds: 500));

      final finalState = ref.read(historyProvider);
      debugPrint(
          '🏁 CompatibilityListPage: 최종 상태 - items: ${finalState.items.length}, isLoading: ${finalState.isLoading}, hasMore: ${finalState.hasMore}');

      if (mounted) {
        setState(() {
          _isInitialized = true;
          // 무조건 3초간 로딩 상태 유지
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isInitialLoading = false;
              });
            }
          });
        });

        debugPrint('🔄 CompatibilityListPage: UI 강제 리빌드 트리거 (3초 후 로딩 종료 예약)');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ CompatibilityListPage: 데이터 로드 실패 - $e');
      debugPrint('스택 트레이스: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
          _isInitialLoading = false;
        });
      }
    }
  }

  void _setupNavigation() {
    try {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            topRightMenu: null,
            showBottomNavigation: false,
            pageTitle: AppLocalizations.of(context).compatibility_page_title,
          );
    } catch (e) {
      debugPrint('❌ 네비게이션 설정 실패: $e');
    }
  }

  void _triggerInitialLoad() {
    if (!mounted || _isInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _performInitialLoad();
      }
    });
  }

  void _handleRefresh() async {
    try {
      debugPrint('🔄 CompatibilityListPage: 새로고침 시작');
      setState(() => _errorMessage = null);

      await ref
          .read(compatibilityListProvider(artistId: widget.artistId).notifier)
          .loadInitial();

      debugPrint('✅ CompatibilityListPage: 새로고침 완료');
    } catch (e) {
      debugPrint('❌ CompatibilityListPage: 새로고침 실패 - $e');
      setState(() => _errorMessage = '새로고침 실패: $e');
    }
  }

  void _handleNewCompatibility() {
    debugPrint('➕ CompatibilityListPage: 새 궁합 만들기');

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _errorMessage = '로그인 후 궁합을 만들 수 있습니다.');
      return;
    }

    try {
      // artistId가 있는 경우 해당 아티스트와 궁합, 없으면 일반 궁합 입력 페이지
      if (widget.artistId != null) {
        // 특정 아티스트와의 궁합 - artist 정보를 provider에서 가져와야 함
        // 일단 간단하게 Navigator 기본 push 사용
        Navigator.of(context).pushNamed('/compatibility_input');
      } else {
        // 일반 궁합 입력 페이지
        Navigator.of(context).pushNamed('/compatibility_input');
      }
    } catch (e) {
      debugPrint('❌ 새 궁합 만들기 실패: $e');
      setState(() => _errorMessage = '궁합 만들기 페이지로 이동할 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필요

    final user = supabase.auth.currentUser;
    if (user == null) {
      return _buildLoginRequiredPage();
    }

    final history =
        ref.watch(compatibilityListProvider(artistId: widget.artistId));

    // 🔧 UI에서 받고 있는 실제 데이터 상태 확인
    debugPrint(
        '🎨 CompatibilityListPage UI: items.length=${history.items.length}, isLoading=${history.isLoading}, hasMore=${history.hasMore}');
    debugPrint(
        '🎨 CompatibilityListPage UI: isEmpty=${history.items.isEmpty}, _errorMessage=$_errorMessage');
    debugPrint(
        '🎨 CompatibilityListPage UI: _isInitialized=$_isInitialized, _isInitialLoading=$_isInitialLoading');

    return _buildMainPage(history);
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '초기화 중...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey00,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequiredPage() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login_outlined,
              size: 80,
              color: AppColors.grey00.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              '로그인이 필요합니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.grey00,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '궁합 기록을 보려면 로그인해주세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey00.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPage(CompatibilityHistoryModel history) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary500, AppColors.secondary500],
          ),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '궁합 기록',
                      style: getTextStyle(AppTypo.title18B, AppColors.grey00),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey00.withValues(alpha: 0.2),
                      foregroundColor: AppColors.grey00,
                    ),
                    child: const Text('새로고침'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleNewCompatibility,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey00.withValues(alpha: 0.2),
                      foregroundColor: AppColors.grey00,
                    ),
                    child: const Text('새 궁합'),
                  ),
                ],
              ),
            ),

            // 콘텐츠
            Expanded(
              child: _buildContent(history),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CompatibilityHistoryModel history) {
    debugPrint('🎭 _buildContent: _errorMessage=$_errorMessage');
    debugPrint('🎭 _buildContent: _isInitialLoading=$_isInitialLoading');
    debugPrint('🎭 _buildContent: _isInitialized=$_isInitialized');
    debugPrint('🎭 _buildContent: history.isLoading=${history.isLoading}');
    debugPrint(
        '🎭 _buildContent: history.items.isEmpty=${history.items.isEmpty}');
    debugPrint(
        '🎭 _buildContent: history.items.length=${history.items.length}');

    // 에러 상태
    if (_errorMessage != null) {
      debugPrint('🎭 _buildContent: 에러 상태로 분기');
      return _buildErrorState();
    }

    // 아직 초기화가 안 됐거나, 초기 로딩 중이거나, Provider가 로딩 중인 경우
    if (!_isInitialized || _isInitialLoading || history.isLoading) {
      debugPrint('🎭 _buildContent: 로딩 상태로 분기');
      return _buildLoadingState();
    }

    // 데이터가 있는 경우
    if (history.items.isNotEmpty) {
      debugPrint('🎭 _buildContent: 리스트 상태로 분기 - ${history.items.length}개 아이템');
      return _buildList(history.items);
    }

    // 초기화 완료, 로딩 완료, 데이터 없음
    debugPrint('🎭 _buildContent: 빈 상태로 분기');
    return _buildEmptyState();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '알 수 없는 오류',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey00.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleRefresh,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 스켈레톤 리스트 아이템들
          Expanded(
            child: ListView.builder(
              itemCount: 6, // 스켈레톤 아이템 6개 표시
              itemBuilder: (context, index) => _buildSkeletonItem(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아티스트 이름 스켈레톤
          _buildShimmerBox(width: 120, height: 20),
          const SizedBox(height: 8),

          // 점수 스켈레톤
          Row(
            children: [
              _buildShimmerBox(width: 70, height: 16),
              const SizedBox(width: 8),
              _buildShimmerBox(width: 40, height: 16),
            ],
          ),
          const SizedBox(height: 8),

          // 상태 배지 스켈레톤
          _buildShimmerBox(width: 50, height: 24, borderRadius: 6),
          const SizedBox(height: 8),

          // 날짜 스켈레톤
          _buildShimmerBox(width: 60, height: 12),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    double? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius ?? 4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_shimmerAnimation.value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.grey00.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            '아직 궁합 기록이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 궁합을 만들어보세요!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey00.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleNewCompatibility,
            child: const Text('궁합 만들기'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<CompatibilityModel> items) {
    debugPrint('📋 _buildList: ${items.length}개 아이템으로 리스트 빌드 시작');

    if (items.isEmpty) {
      debugPrint('📋 _buildList: 아이템이 비어있음 - 빈 상태 표시');
      return _buildEmptyState();
    }

    // 🔧 레이아웃 디버깅을 위한 Container로 감싸기
    return Container(
      color: Colors.blue.withValues(alpha: 0.1), // 디버깅용 배경색
      child: LayoutBuilder(
        builder: (context, constraints) {
          debugPrint('📋 _buildList: 사용 가능한 높이 = ${constraints.maxHeight}');
          debugPrint('📋 _buildList: 사용 가능한 너비 = ${constraints.maxWidth}');

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              debugPrint(
                  '📋 _buildList: 아이템 $index 빌드 중 - ${items[index].artist.name}');
              return _buildSimpleItem(items[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSimpleItem(CompatibilityModel item) {
    try {
      debugPrint('🎯 _buildSimpleItem: 아이템 렌더링 시작 - ID: ${item.id}');
      debugPrint('🎯 _buildSimpleItem: artist.name = ${item.artist.name}');
      debugPrint('🎯 _buildSimpleItem: score = ${item.score}');
      debugPrint('🎯 _buildSimpleItem: status = ${item.status}');

      final artistName = item.artist.name.toString();
      debugPrint('🎯 _buildSimpleItem: artistName 변환 완료 = $artistName');

      final scoreText = '${item.score}점';
      debugPrint('🎯 _buildSimpleItem: scoreText 생성 완료 = $scoreText');

      final widget = Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: InkWell(
          onTap: () => _onItemTap(item),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아티스트 이름
              Text(
                artistName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 점수
              Row(
                children: [
                  const Text(
                    '궁합 점수: ',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    scoreText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // 상태
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status == CompatibilityStatus.completed
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status == CompatibilityStatus.completed ? '완료' : '대기중',
                  style: TextStyle(
                    fontSize: 12,
                    color: item.status == CompatibilityStatus.completed
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
              ),

              // 날짜
              if (item.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${DateTime.now().difference(item.createdAt!).inDays}일 전',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      debugPrint('🎯 _buildSimpleItem: 위젯 생성 완료');
      return widget;
    } catch (e, stackTrace) {
      debugPrint('❌ _buildSimpleItem: 렌더링 에러 - $e');
      debugPrint('❌ _buildSimpleItem: 스택트레이스 - $stackTrace');

      // 안전한 fallback 위젯
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Text(
          '렌더링 에러: ${item.id}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  void _onItemTap(CompatibilityModel item) {
    try {
      debugPrint('🎯 CompatibilityListPage: 아이템 탭 - ${item.id}');

      if (item.status == CompatibilityStatus.completed) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CompatibilityResultPage(compatibility: item),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CompatibilityLoadingPage(compatibility: item),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 아이템 탭 실패: $e');
      setState(() => _errorMessage = '페이지 이동 실패: $e');
    }
  }

  // 새로고침 메서드 추가
  void _onRefresh() async {
    try {
      final provider = compatibilityListProvider(artistId: widget.artistId);

      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });

      await ref.read(provider.notifier).loadInitial();

      setState(() {
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = '새로고침 실패: $e';
      });
    }
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
