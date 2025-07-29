import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/ui/style.dart';

class QaThreadListPage extends StatefulWidget {
  final String userId;

  const QaThreadListPage({
    super.key,
    required this.userId,
  });

  @override
  State<QaThreadListPage> createState() => _QaThreadListPageState();
}

class _QaThreadListPageState extends State<QaThreadListPage> {
  final QnaRepository _repository = QnaRepository();
  List<QnaThread> _threadList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final threads = await _repository.getQaThreadList(userId: widget.userId);

      if (mounted) {
        setState(() {
          _threadList = threads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _navigateToCreateThread() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => QnaThreadCreatePage(userId: widget.userId),
      ),
    );
    if (result == true) {
      _loadThreads();
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
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).qna_list_title,
          style: getTextStyle(AppTypo.title18B, AppColors.grey00),
        ),
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.grey00,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateThread,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_errorMessage'),
        ),
      );
    }
    if (_threadList.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).qna_list_empty));
    }
    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.builder(
        itemCount: _threadList.length,
        itemBuilder: (context, index) {
          final thread = _threadList[index];
          return ListTile(
            title: Text(thread.title),
            subtitle: Text(
              'Status: ${thread.status} | Last updated: ${thread.createdAt.toLocal()}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _navigateToThreadDetail(thread),
          );
        },
      ),
    );
  }
}
