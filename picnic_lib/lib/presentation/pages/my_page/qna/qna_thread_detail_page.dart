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
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';

// Re-export for backward compatibility with existing tests
export 'package:picnic_lib/presentation/pages/my_page/qna/qna_detail_utils.dart';

class QnaThreadDetailPage extends ConsumerStatefulWidget {
  final QnaThread thread;
  final bool syncNavigation;

  const QnaThreadDetailPage({
    super.key,
    required this.thread,
    this.syncNavigation = true,
  });

  @override
  ConsumerState<QnaThreadDetailPage> createState() =>
      _QaThreadDetailPageState();
}

class _QaThreadDetailPageState extends ConsumerState<QnaThreadDetailPage> {
  final QnaRepository _repository = QnaRepository();
  final TextEditingController _messageController = TextEditingController();

  late QnaThread _thread;
  late final bool _syncNavigation;
  List<QnaMessage> _messages = [];
  List<File> _attachments = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAttaching = false;
  String? _errorMessage;
  String? _categoryLabel;
  String? _prevPageTitle;
  String? _prevMyPageTitle;
  static const int _maxFileSizeInBytes = 10 * 1024 * 1024; // 10MB
  RealtimeChannel? _threadStatusChannel;

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
      final supabase = Supabase.instance.client;
      _threadStatusChannel = supabase.channel('qna_thread_status_${_thread.id}')
        ..onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'qna_threads',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _thread.id,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'] as String?;
            if (newStatus != null && mounted) {
              setState(() {
                _thread = _thread.copyWith(status: newStatus);
              });
            }
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('QnA 스레드 상태 Realtime 구독 실패: $e');
    }
  }

  Future<void> _loadThreadDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final threadWithMessages = await _repository.getQaThreadById(
        _thread.id,
      );
      setState(() {
        _thread = threadWithMessages.thread;
        _messages = threadWithMessages.messages;
        _categoryLabel = threadWithMessages.categoryLabel;
        _isLoading = false;
      });
      if (_syncNavigation) {
        _applyNavigation(_thread.title);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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
    final content = _messageController.text.trim();
    if (content.isEmpty && _attachments.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final newMessage = await _repository.createQaMessage(
        threadId: _thread.id,
        userId: userId,
        content: content,
        attachments: _attachments,
      );

      _messageController.clear();
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _attachments = [];
        });
        SnackbarUtil().success(
          AppLocalizations.of(context).qna_message_sent_success,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil().error(
          '${AppLocalizations.of(context).qna_message_sent_fail}: $e',
          context: context,
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
    try {
      _threadStatusChannel?.unsubscribe();
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).qna_no_answer_yet),
      );
    }
    return QnaMessageListView(
      messages: _messages,
      currentUserId: Supabase.instance.client.auth.currentUser!.id,
      getPublicUrl: _repository.getPublicUrl,
    );
  }
}
