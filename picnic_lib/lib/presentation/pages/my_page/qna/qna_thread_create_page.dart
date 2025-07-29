import 'package:flutter/material.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaThreadCreatePage extends StatefulWidget {
  final String userId;

  const QnaThreadCreatePage({
    super.key,
    required this.userId,
  });

  @override
  State<QnaThreadCreatePage> createState() => _QnaThreadCreatePageState();
}

class _QnaThreadCreatePageState extends State<QnaThreadCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final QnaRepository _repository = QnaRepository();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitThread() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _repository.createQaThread(
        userId: widget.userId,
        title: _titleController.text.trim(),
        initialMessage: _contentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).qna_submit_success),
            backgroundColor: AppColors.primary500,
          ),
        );
        Navigator.of(context).pop(true); // true를 반환하여 목록 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).qna_submit_error),
            backgroundColor: AppColors.grey900,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).qna_create_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).qna_form_title,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).qna_form_title_empty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).qna_form_content,
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).qna_form_content_empty;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitThread,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppLocalizations.of(context).submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
