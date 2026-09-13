import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_card.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_submit_button.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QnaThreadListPage extends ConsumerStatefulWidget {
  final String userId;
  final QnaRepository? repository;

  const QnaThreadListPage({super.key, required this.userId, this.repository});

  @override
  ConsumerState<QnaThreadListPage> createState() => _QnaThreadListPageState();
}

class _QnaThreadListPageState extends ConsumerState<QnaThreadListPage>
    with RouteAwareStateMixin<QnaThreadListPage> {
  static const int _pageSize = 20;
  late final QnaRepository _repository = widget.repository ?? QnaRepository();
  final ScrollController _scrollController = ScrollController();
  List<QnaThread> _threadList = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _currentTitle;
  RealtimeChannel? _threadListChannel;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTitle = AppLocalizations.of(context).qna_list_title;
      _updateNavigation();
    });
    _loadThreads(isInitial: true);
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    try {
      final supabase = Supabase.instance.client;
      _threadListChannel = supabase.channel('qna_thread_list_${widget.userId}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'qna_threads',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            final threadId = record['id'] as int?;
            final newStatus = record['status'] as String?;
            if (threadId != null && newStatus != null && mounted) {
              setState(() {
                final index = _threadList.indexWhere((t) => t.id == threadId);
                if (index != -1) {
                  _threadList[index] = _threadList[index].copyWith(
                    status: newStatus,
                  );
                }
              });
            }
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('QnA 스레드 목록 Realtime 구독 실패: $e');
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    try {
      _threadListChannel?.unsubscribe();
    } catch (_) {}
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentTitle ??= AppLocalizations.of(context).qna_list_title;
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadThreads();
    }
  }

  Future<void> _loadThreads({bool isInitial = false}) async {
    if (!isInitial &&
        (_isLoading || _isRefreshing || _isMoreLoading || !_hasMore)) {
      return;
    }

    final generation = isInitial ? ++_loadGeneration : _loadGeneration;

    try {
      if (!mounted) return;
      if (isInitial) {
        setState(() {
          _isLoading = _threadList.isEmpty;
          _isRefreshing = true;
          _isMoreLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isMoreLoading = true;
          _errorMessage = null;
        });
      }

      final lastId = isInitial || _threadList.isEmpty
          ? null
          : _threadList.last.id;
      final lastCreatedAt = isInitial || _threadList.isEmpty
          ? null
          : _threadList.last.createdAt;
      final threads = await _repository.getQaThreadList(
        userId: widget.userId,
        lastId: lastId,
        lastCreatedAt: lastCreatedAt,
        limit: _pageSize,
      );

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        if (isInitial) {
          _threadList = threads;
        } else {
          final existingIds = _threadList.map((thread) => thread.id).toSet();
          _threadList.addAll(
            threads.where((thread) => existingIds.add(thread.id)),
          );
        }
        _hasMore = threads.length == _pageSize;
        _isLoading = false;
        _isRefreshing = false;
        _isMoreLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _isMoreLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToCreateThread() async {
    if (await showWithdrawalBlockedDialog(context: context, ref: ref)) return;
    if (!mounted) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            QnaThreadCreatePage(userId: widget.userId, repository: _repository),
      ),
    );
    if (!mounted) return;
    if (result == true) await _loadThreads(isInitial: true);
  }

  void _navigateToThreadDetail(QnaThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QnaThreadDetailPage(thread: thread),
      ),
    );
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
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: QnaSubmitButton.fab(
        context,
        onPressed: _navigateToCreateThread,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();

    return RefreshIndicator(
      onRefresh: () => _loadThreads(isInitial: true),
      child: () {
        if (_errorMessage != null && _threadList.isEmpty) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [SliverFillRemaining(child: _buildErrorView())],
          );
        }

        if (_threadList.isEmpty) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: NoItemContainer(
                  message: AppLocalizations.of(context).qna_no_inquiries,
                ),
              ),
            ],
          );
        }

        return ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: _threadList.length + (_isMoreLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _threadList.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: MediumPulseLoadingIndicator(),
                ),
              );
            }
            final thread = _threadList[index];
            return QnaThreadCard(
              thread: thread,
              repository: _repository,
              onTap: () => _navigateToThreadDetail(thread),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
        );
      }(),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 20.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8.0),
              Container(width: 150.0, height: 16.0, color: Colors.white),
            ],
          ),
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 60),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).qna_load_fail_title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _loadThreads(isInitial: true),
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).retry),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }
}
