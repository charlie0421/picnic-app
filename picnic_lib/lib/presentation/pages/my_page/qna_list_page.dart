import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/qna/qna.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna_create_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna_detail_page.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';

class QnAListPage extends StatefulWidget {
  final String userId;

  const QnAListPage({
    super.key,
    required this.userId,
  });

  @override
  State<QnAListPage> createState() => _QnAListPageState();
}

class _QnAListPageState extends State<QnAListPage> {
  final QnARepository _repository = QnARepository();
  List<QnA> _qnaList = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQnAList();
  }

  Future<void> _loadQnAList() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await _repository.getMyQnAList(userId: widget.userId);

      setState(() {
        _qnaList = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('qna_list_title'),
          style: getTextStyle(AppTypo.title18B, AppColors.grey00),
        ),
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.grey00,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateQnA(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              t('qna_error_message'),
              style: getTextStyle(AppTypo.body16M, AppColors.grey600),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: getTextStyle(AppTypo.body14R, AppColors.grey500),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadQnAList,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: AppColors.grey00,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t('retry'),
                style: getTextStyle(AppTypo.caption12B, AppColors.grey00),
              ),
            ),
          ],
        ),
      );
    }

    if (_qnaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              t('qna_empty_list'),
              style: getTextStyle(AppTypo.body16R, AppColors.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t('qna_create_first'),
              style: getTextStyle(AppTypo.body14R, AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQnAList,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _qnaList.length,
        itemBuilder: (context, index) {
          final qna = _qnaList[index];
          return _buildQnAItem(qna);
        },
      ),
    );
  }

  Widget _buildQnAItem(QnA qna) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToQnADetail(qna),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      qna.title,
                      style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(qna.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                qna.question.length > 100
                    ? '${qna.question.substring(0, 100)}...'
                    : qna.question,
                style: getTextStyle(AppTypo.body14R, AppColors.grey600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(qna.createdAt),
                    style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
                  ),
                  const Spacer(),
                  if (!qna.isPrivate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t('qna_public_option'),
                        style:
                            getTextStyle(AppTypo.caption12R, AppColors.grey00),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = t('qna_status_pending');
        break;
      case 'answered':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = t('qna_status_answered');
        break;
      case 'closed':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = t('qna_status_closed');
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: getTextStyle(AppTypo.caption12R, textColor),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}${t('days_ago')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${t('hours_ago')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${t('minutes_ago')}';
    } else {
      return t('just_now');
    }
  }

  void _navigateToCreateQnA() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => QnACreatePage(userId: widget.userId),
          ),
        )
        .then((_) => _loadQnAList());
  }

  void _navigateToQnADetail(QnA qna) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => QnADetailPage(qna: qna),
          ),
        )
        .then((_) => _loadQnAList());
  }
}
