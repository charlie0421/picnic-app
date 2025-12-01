import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_status_chip.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_submit_button.dart';
import 'package:picnic_lib/presentation/utils/withdrawn_user_guard.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';

class QnaThreadListPage extends ConsumerStatefulWidget {
  final String userId;

  const QnaThreadListPage({super.key, required this.userId});

  @override
  ConsumerState<QnaThreadListPage> createState() => _QnaThreadListPageState();
}

class _QnaThreadListPageState extends ConsumerState<QnaThreadListPage>
    with RouteAwareStateMixin<QnaThreadListPage> {
  final QnaRepository _repository = QnaRepository();
  final ScrollController _scrollController = ScrollController();
  List<QnaThread> _threadList = [];
  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentTitle = AppLocalizations.of(context).qna_list_title;
      _updateNavigation();
    });
    _loadThreads(isInitial: true);
  }

  @override
  void dispose() {
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
    if (_isMoreLoading || !_hasMore) {
      return;
    }

    try {
      if (isInitial && _threadList.isEmpty) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      } else if (!isInitial) {
        setState(() {
          _isMoreLoading = true;
          _errorMessage = null;
        });
      }

      final lastId = isInitial || _threadList.isEmpty
          ? null
          : _threadList.last.id;
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
        _isLoading = false;
        _isMoreLoading = false;
        if (isInitial) {
          _errorMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isMoreLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToCreateThread() async {
    if (showWithdrawalBlockedDialog(context: context, ref: ref)) {
      return;
    }
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

  void _updateNavigation() {
    final title = _currentTitle;
    if (title == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).setMyPageTitle(
            pageTitle: title,
          );
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
    if (_isLoading) {
      return _buildShimmer();
    }

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
            slivers: [SliverFillRemaining(child: _buildEmptyView())],
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
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final thread = _threadList[index];
            return _buildThreadCard(thread);
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

  Widget _buildEmptyView() {
    return NoItemContainer(
      message: AppLocalizations.of(context).qna_no_inquiries,
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
              color: Colors.grey.withValues(alpha: 0.1),
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
              children: [
                Expanded(
                  child: Text(
                    thread.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                QnaStatusChip(status: thread.status),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: _repository.getFirstAttachmentForThread(thread.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final att = snapshot.data!;
                final isImage =
                    (att.fileType?.startsWith('image/') ?? false) ||
                    ['jpg', 'jpeg', 'png', 'gif'].any(
                      (ext) => att.fileName.toLowerCase().endsWith('.$ext'),
                    );
                final isVideo = att.fileType?.startsWith('video/') ?? false;

                final url = _repository.getPublicUrl(att.filePath);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: isImage
                          ? ImageThumbnailFromUrl(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            )
                          : isVideo
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                VideoThumbnailFromUrl(
                                  videoUrl: url,
                                  fit: BoxFit.cover,
                                ),
                                const Align(
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              color: AppColors.grey200,
                              child: const Center(
                                child: Icon(
                                  Icons.insert_drive_file,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat(
                    'yyyy-MM-dd HH:mm',
                  ).format(thread.updatedAt.toLocal()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
