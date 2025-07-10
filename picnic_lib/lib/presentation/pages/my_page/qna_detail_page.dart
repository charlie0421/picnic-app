import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/qna/qna.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:intl/intl.dart';

class QnADetailPage extends StatefulWidget {
  final QnA qna;

  const QnADetailPage({
    super.key,
    required this.qna,
  });

  @override
  State<QnADetailPage> createState() => _QnADetailPageState();
}

class _QnADetailPageState extends State<QnADetailPage> {
  final QnARepository _repository = QnARepository();
  QnA? _currentQnA;

  @override
  void initState() {
    super.initState();
    _currentQnA = widget.qna;
    _refreshQnA();
  }

  Future<void> _refreshQnA() async {
    setState(() {});

    try {
      final updatedQnA = await _repository.getQnAById(widget.qna.qnaId);
      if (updatedQnA != null && mounted) {
        setState(() {
          _currentQnA = updatedQnA;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).qna_load_error),
            backgroundColor: AppColors.grey900,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQnA == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).qna_detail_page_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey00),
          ),
          backgroundColor: AppColors.primary500,
          foregroundColor: AppColors.grey00,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).qna_detail_page_title,
          style: getTextStyle(AppTypo.title18B, AppColors.grey00),
        ),
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.grey00,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshQnA,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshQnA,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQnAHeader(),
              const SizedBox(height: 24),
              _buildQnAContent(),
              const SizedBox(height: 24),
              _buildQnAInfo(),
              if (_currentQnA!.answer != null) ...[
                const SizedBox(height: 32),
                _buildAnswerSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQnAHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _currentQnA!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildStatusChip(_currentQnA!.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(_currentQnA!.createdAt),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              if (_currentQnA!.isPublic)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context).qna_public,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQnAContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).qna_content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentQnA!.question,
            style: getTextStyle(AppTypo.body16R, AppColors.grey900),
          ),
        ],
      ),
    );
  }

  Widget _buildQnAInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).qna_info_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            AppLocalizations.of(context).qna_status,
            _getStatusText(_currentQnA!.status),
          ),
          _buildInfoRow(
            AppLocalizations.of(context).qna_created_at,
            DateFormat('yyyy-MM-dd HH:mm').format(_currentQnA!.createdAt),
          ),
          _buildInfoRow(
            AppLocalizations.of(context).qna_updated_at,
            DateFormat('yyyy-MM-dd HH:mm').format(_currentQnA!.updatedAt),
          ),
          _buildInfoRow(
            AppLocalizations.of(context).qna_public_status,
            _currentQnA!.isPrivate
                ? AppLocalizations.of(context).qna_private
                : AppLocalizations.of(context).qna_public_option,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.question_answer,
                color: AppColors.primary500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).qna_answer_title,
                style: getTextStyle(AppTypo.title18B, AppColors.grey900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentQnA!.answer!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          if (_currentQnA!.answeredAt != null) ...[
            const SizedBox(height: 12),
            Text(
              '${AppLocalizations.of(context).qna_answered_at}: ${DateFormat('yyyy-MM-dd HH:mm').format(_currentQnA!.answeredAt!)}',
              style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
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
        text = AppLocalizations.of(context).qna_status_pending;
        break;
      case 'answered':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = AppLocalizations.of(context).qna_status_answered;
        break;
      case 'resolved':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        text = AppLocalizations.of(context).qna_status_resolved;
        break;
      case 'closed':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = AppLocalizations.of(context).qna_status_closed;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppLocalizations.of(context).qna_status_pending;
      case 'answered':
        return AppLocalizations.of(context).qna_status_answered;
      case 'resolved':
        return AppLocalizations.of(context).qna_status_resolved;
      case 'closed':
        return AppLocalizations.of(context).qna_status_closed;
      default:
        return status;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
