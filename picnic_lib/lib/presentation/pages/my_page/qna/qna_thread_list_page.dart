import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

class QnaThreadListPage extends ConsumerStatefulWidget {
  final String userId;

  const QnaThreadListPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<QnaThreadListPage> createState() => _QnaThreadListPageState();
}

class _QnaThreadListPageState extends ConsumerState<QnaThreadListPage> {
  final QnaRepository _repository = QnaRepository();
  final ScrollController _scrollController = ScrollController();
  List<QnaThread> _threadList = [];
  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).setMyPageTitle(
            pageTitle: AppLocalizations.of(context).qna_list_title,
          );
    });
    _loadThreads(isInitial: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadThreads();
    }
  }

  Future<void> _loadThreads({bool isInitial = false}) async {
    if (_isMoreLoading || !_hasMore) {
      return;
    }

    try {
      setState(() {
        if (isInitial) {
          _isLoading = true;
        } else {
          _isMoreLoading = true;
        }
        _errorMessage = null;
      });

      final lastId =
          isInitial || _threadList.isEmpty ? null : _threadList.last.id;
      final threads = await _repository.getQaThreadList(
        userId: widget.userId,
        lastId: lastId,
      );

      setState(() {
        if (isInitial) {
          _threadList = threads;
        } else {
          _threadList.addAll(threads);
        }
        _hasMore = threads.isNotEmpty;
        if (isInitial) {
          _isLoading = false;
        }
        _isMoreLoading = false;
      });
    } catch (e) {
      setState(() {
        if (isInitial) {
          _isLoading = false;
        }
        _isMoreLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToCreateThread() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QnaThreadCreatePage(userId: widget.userId),
      ),
    );
    if (result == true) {
      _loadThreads(isInitial: true);
    }
  }

  void _navigateToThreadDetail(QnaThread thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QnaThreadDetailPage(thread: thread),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateThread,
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmer();
    }
    if (_errorMessage != null) {
      return _buildErrorView();
    }
    if (_threadList.isEmpty) {
      return _buildEmptyView();
    }
    return RefreshIndicator(
      onRefresh: () => _loadThreads(isInitial: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: _threadList.length + (_isMoreLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _threadList.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final thread = _threadList[index];
          return _buildThreadCard(thread);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
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
              Container(
                width: 150.0,
                height: 16.0,
                color: Colors.white,
              ),
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
          const Text(
            'Failed to load inquiries',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary500,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return NoItemContainer(
      message: AppLocalizations.of(context).qna_list_empty,
    );
  }

  Widget _buildThreadCard(QnaThread thread) {
    return InkWell(
      onTap: () => _navigateToThreadDetail(thread),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    thread.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(thread.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(thread.updatedAt.toLocal()),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    bool isClosed = status.toLowerCase() == 'closed';
    Color chipColor = isClosed ? AppColors.secondary500 : AppColors.primary500;
    Color textColor = isClosed ? AppColors.grey900 : Colors.white;
    String statusText = isClosed
        ? AppLocalizations.of(context).qna_status_closed
        : AppLocalizations.of(context).qna_status_open;

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
            color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
