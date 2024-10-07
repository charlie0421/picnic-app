import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class BoardRequest extends ConsumerStatefulWidget {
  const BoardRequest(this.artistId, {super.key});
  final int artistId;

  @override
  ConsumerState<BoardRequest> createState() => _BoardRequireState();
}

class _BoardRequireState extends ConsumerState<BoardRequest> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _requestMessageController;

  bool requested = false;

  bool _nameValidated = false;
  bool _purposeValidated = false;
  bool _requestMessageValidated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _requestMessageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _requestMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: checkPendingRequest(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (snapshot.data != null) {
            _nameController.text = snapshot.data!.name['minor'];
            _descriptionController.text = snapshot.data!.description;
            _requestMessageController.text =
                snapshot.data?.requestMessage ?? '';
          }
          return Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInfoBanner(),
                ..._buildSection(
                  _nameController,
                  '마이너 게시판 이름',
                  '게시판 이름을 입력해주세요',
                  1,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return '게시판 이름을 입력해주세요';
                    }
                    return null;
                  },
                  _nameValidated,
                  (val) => setState(() => _nameValidated = true),
                  snapshot.data == null,
                ),
                ..._buildSection(
                  _descriptionController,
                  '마이너 게시판 설명',
                  '마이너 게시판 설명을 작성해 주세요.',
                  3,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return '게시판 설명을 입력해주세요';
                    }
                    if (value.length < 5 && value.length < 20) {
                      return '목적은 5자 이상 20자 이하로 입력해주세요';
                    }
                    return null;
                  },
                  _purposeValidated,
                  (val) => setState(() => _purposeValidated = true),
                  snapshot.data == null,
                ),
                ..._buildSection(
                  _requestMessageController,
                  '* 게시판 오픈 요청 메시지',
                  '게시판 오픈 요청 메시지를 입력해주세요.',
                  3,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return '게시판 오픈 요청 메시지를 입력해주세요';
                    }
                    if (value.length < 10) {
                      return '게시판 오픈 요청 메시지는 10자 이상 입력해주세요';
                    }
                    return null;
                  },
                  _requestMessageValidated,
                  (val) => setState(() => _requestMessageValidated = true),
                  snapshot.data == null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => AppColors.grey400),
                      ),
                  onPressed: snapshot.data == null ? _handleSubmit : null,
                  child: Text(
                      snapshot.data == null ? '게시판 오픈 요청' : '게시판 오픈 검토중',
                      style: getTextStyle(AppTypo.body14B, AppColors.grey00)),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildInfoBanner() {
    return Container(
      height: 30,
      decoration: const BoxDecoration(color: Color(0xFFF3EFFF)),
      child: Center(
        child: Text('*아이디 당 1개의 마이너 게시판만 신청이 가능합니다.',
            style: getTextStyle(AppTypo.caption12M, AppColors.primary500)),
      ),
    );
  }

  List<Widget> _buildSection(
    TextEditingController controller,
    String title,
    String hintText,
    int maxLines,
    String? Function(String?) validator,
    bool validated,
    void Function(String) onChanged,
    bool enabled,
  ) {
    return [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 16.cw, top: 24),
        child: Text(title,
            style: getTextStyle(AppTypo.body14B, AppColors.grey900)),
      ),
      const SizedBox(height: 7),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.cw),
        child: TextFormField(
          maxLines: maxLines,
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            fillColor: enabled ? AppColors.grey00 : AppColors.grey100,
            filled: !enabled,
            hintText: hintText,
            hintStyle: getTextStyle(AppTypo.body16M, AppColors.grey400),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.cw, vertical: 16.cw),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.grey400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.primary500),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: validator,
          autovalidateMode: validated
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          onChanged: onChanged,
        ),
      ),
    ];
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      checkDuplicateBoard(ref, _nameController.text).then((value) {
        if (value != null) {
          showSimpleDialog(
            content: '이미 존재하는 게시판입니다.',
            onOk: () => Navigator.of(context).pop(),
          );
        } else {
          createBoard(
            ref,
            widget.artistId,
            _nameController.text,
            _descriptionController.text,
            _requestMessageController.text,
          ).then((value) {
            showSimpleDialog(
              content: '게시판 오픈 요청이 완료되었습니다.',
              onOk: () => Navigator.of(context).pop(),
            );
          });
        }
      });
    }
  }
}
