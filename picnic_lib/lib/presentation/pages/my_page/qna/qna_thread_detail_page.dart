import 'dart:async';
import 'dart:io';

import 'package:picnic_lib/presentation/pages/my_page/qna/qna_media_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_category_chip.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_detail_utils.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_message_input.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_message_list_view.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_status_chip.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/loading_view.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';

// Re-export for backward compatibility with existing tests
export 'package:picnic_lib/presentation/pages/my_page/qna/qna_detail_utils.dart';

typedef QnaThreadStatusSubscriber =
    VoidCallback Function({
      required int threadId,
      required ValueChanged<String> onStatusChanged,
    });

class QnaThreadDetailPage extends ConsumerStatefulWidget {
  final QnaThread thread;
  final bool syncNavigation;
  final QnaRepository? repository;
  final QnaThreadStatusSubscriber? statusSubscriber;

  const QnaThreadDetailPage({
    super.key,
    required this.thread,
    this.syncNavigation = true,
    this.repository,
    this.statusSubscriber,
  });

  @override
  ConsumerState<QnaThreadDetailPage> createState() =>
      _QaThreadDetailPageState();
}

class _QaThreadDetailPageState extends ConsumerState<QnaThreadDetailPage> {
  late final QnaRepository _repository = widget.repository ?? QnaRepository();
  final TextEditingController _messageController = TextEditingController();

  late QnaThread _thread;
  late final bool _syncNavigation;
  List<QnaMessage> _messages = [];
  List<File> _attachments = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAttaching = false;
  bool _hasLoadError = false;
  bool _detailLoadInFlight = false;
  String? _categoryLabel;
  String? _prevPageTitle;
  String? _prevMyPageTitle;
  static const int _maxFileSizeInBytes = 10 * 1024 * 1024; // 10MB
  VoidCallback? _cancelThreadStatusSubscription;
  int _loadGeneration = 0;
  int _statusRevision = 0;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
    _syncNavigation = widget.syncNavigation;

    if (_syncNavigation) {
      final navState = ref.read(navigationInfoProvider);
      _prevPageTitle = navState.pageTitle;
      _prevMyPageTitle = navState.myPageTitle;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyNavigation(_thread.title);
      });
    }
    _loadThreadDetails();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    try {
      _cancelThreadStatusSubscription =
          (widget.statusSubscriber ?? _subscribeToThreadStatus)(
            threadId: _thread.id,
            onStatusChanged: _handleStatusChanged,
          );
    } catch (e) {
      debugPrint('QnA 스레드 상태 Realtime 구독 실패: $e');
    }
  }

  VoidCallback _subscribeToThreadStatus({
    required int threadId,
    required ValueChanged<String> onStatusChanged,
  }) {
    final client = supabase;
    final channel = client.channel('qna_thread_status_$threadId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'qna_threads',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: threadId,
        ),
        callback: (payload) {
          final newStatus = payload.newRecord['status'] as String?;
          if (newStatus != null) onStatusChanged(newStatus);
        },
      )
      ..subscribe();

    return () {
      unawaited(client.removeChannel(channel).catchError((_) => 'error'));
    };
  }

  void _handleStatusChanged(String newStatus) {
    if (!mounted) return;
    setState(() {
      _statusRevision++;
      _thread = _thread.copyWith(status: newStatus);
    });
  }

  Future<void> _loadThreadDetails() async {
    if (!mounted || _detailLoadInFlight) return;

    _detailLoadInFlight = true;
    final generation = ++_loadGeneration;
    final statusRevisionAtStart = _statusRevision;

    try {
      setState(() {
        _isLoading = true;
        _hasLoadError = false;
      });

      final threadWithMessages = await _repository.getQaThreadById(_thread.id);
      if (!mounted || generation != _loadGeneration) return;

      final loadedThread = statusRevisionAtStart == _statusRevision
          ? threadWithMessages.thread
          : threadWithMessages.thread.copyWith(status: _thread.status);
      setState(() {
        _thread = loadedThread;
        _messages = List<QnaMessage>.of(threadWithMessages.messages);
        _categoryLabel = threadWithMessages.categoryLabel;
        _isLoading = false;
      });
      if (_syncNavigation) {
        _applyNavigation(_thread.title);
      }
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
      });
    } finally {
      if (mounted && generation == _loadGeneration) {
        _detailLoadInFlight = false;
      }
    }
  }

  void _applyNavigation(String title) {
    if (!_syncNavigation) return;
    final nav = ref.read(navigationInfoProvider.notifier);
    nav.setMyPageTitle(pageTitle: title);
    nav.settingNavigation(
      showPortal: false,
      showBottomNavigation: true,
      showTopMenu: true,
      pageTitle: title,
    );
  }

  Future<void> _sendMessage() async {
    if (!mounted ||
        _isSending ||
        _isLoading ||
        _hasLoadError ||
        !_thread.isOpen) {
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty && _attachments.isEmpty) return;

    String? userId;
    try {
      userId = supabase.auth.currentUser?.id;
    } catch (_) {
      userId = null;
    }
    if (userId == null) {
      SnackbarUtil().error(
        AppLocalizations.of(context).error_user_not_authenticated,
        context: context,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);
    final attachments = List<File>.of(_attachments);

    late final QnaMessage newMessage;
    try {
      newMessage = await _repository.createQaMessage(
        threadId: _thread.id,
        userId: userId,
        content: content,
        attachments: attachments,
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtil().error(
          '${AppLocalizations.of(context).qna_message_sent_fail}: $e',
          context: context,
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }

    if (!mounted) return;
    _messageController.clear();
    setState(() {
      _messages.add(newMessage);
      _attachments = [];
    });
    SnackbarUtil().success(
      AppLocalizations.of(context).qna_message_sent_success,
      context: context,
    );
  }

  Future<void> _pickMedia() async {
    FocusScope.of(context).unfocus();
    setState(() => _isAttaching = true);
    try {
      final result = await pickQnaMedia(
        context: context,
        maxFileSizeInBytes: _maxFileSizeInBytes,
      );
      if (!mounted) return;
      setState(() => _attachments.addAll(result.selectedFiles));
    } finally {
      if (mounted) setState(() => _isAttaching = false);
    }
  }

  void _removeAttachment(int index) {
    FocusScope.of(context).unfocus();
    setState(() => _attachments.removeAt(index));
  }

  @override
  void dispose() {
    _loadGeneration++;
    try {
      _cancelThreadStatusSubscription?.call();
    } catch (_) {}
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                _thread.title,
                style: getTextStyle(AppTypo.body14M, AppColors.grey900),
              ),
              backgroundColor: AppColors.grey00,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: AppColors.grey900,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: QnaStatusChip(status: _thread.status),
                ),
              ],
            ),
            body: Column(
              children: [
                if (_categoryLabel != null && _categoryLabel!.isNotEmpty)
                  QnaCategoryChip(label: _categoryLabel!),
                Expanded(child: _buildBody()),
                QnaMessageInput(
                  isThreadOpen: _thread.isOpen,
                  showAutoCloseNotice: shouldShowAutoCloseNotice(
                    threadStatus: _thread.status,
                    messages: _messages,
                  ),
                  isSending: _isSending,
                  attachments: _attachments,
                  messageController: _messageController,
                  onSend: _sendMessage,
                  onPickMedia: _pickMedia,
                  onRemoveAttachment: _removeAttachment,
                ),
              ],
            ),
          ),
          if (_isSending || _isAttaching)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: LoadingView()),
            ),
        ],
      ),
    );

    if (!_syncNavigation) return body;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        final nav = ref.read(navigationInfoProvider.notifier);
        nav.setMyPageTitle(pageTitle: _prevMyPageTitle ?? '');
        nav.settingNavigation(
          showPortal: false,
          showBottomNavigation: true,
          showTopMenu: true,
          pageTitle: _prevPageTitle ?? '',
        );
      },
      child: body,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: MediumPulseLoadingIndicator());
    }
    if (_hasLoadError) {
      return _buildErrorView();
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).qna_no_answer_yet),
      );
    }
    return QnaMessageListView(
      messages: _messages,
      currentUserId: _currentUserId,
      getPublicUrl: _repository.getPublicUrl,
    );
  }

  String get _currentUserId {
    try {
      return supabase.auth.currentUser?.id ?? '';
    } catch (_) {
      return '';
    }
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
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadThreadDetails,
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
