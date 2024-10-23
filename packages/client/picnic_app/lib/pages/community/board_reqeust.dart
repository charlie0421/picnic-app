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
  final _scrollController = ScrollController();

  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _requestMessageFocus = FocusNode();

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

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && !_nameValidated) {
        setState(() => _nameValidated = true);
      }
    });
    _descriptionFocus.addListener(() {
      if (!_descriptionFocus.hasFocus && !_purposeValidated) {
        setState(() => _purposeValidated = true);
      }
    });
    _requestMessageFocus.addListener(() {
      if (!_requestMessageFocus.hasFocus && !_requestMessageValidated) {
        setState(() => _requestMessageValidated = true);
      }
    });

    _nameFocus.addListener(_handleFocusChange);
    _descriptionFocus.addListener(_handleFocusChange);
    _requestMessageFocus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    FocusNode? focusNode;
    if (_nameFocus.hasFocus) focusNode = _nameFocus;
    if (_descriptionFocus.hasFocus) focusNode = _descriptionFocus;
    if (_requestMessageFocus.hasFocus) focusNode = _requestMessageFocus;

    if (focusNode != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        final RenderObject? renderObject = focusNode?.context?.findRenderObject();
        if (renderObject != null) {
          _scrollController.position.ensureVisible(
            renderObject,
            duration: const Duration(milliseconds: 300),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _requestMessageController.dispose();
    _scrollController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _requestMessageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _nameFocus.unfocus();
        _descriptionFocus.unfocus();
        _requestMessageFocus.unfocus();
      },
      child: FutureBuilder(
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

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.only(
                  bottom: 300,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInfoBanner(),
                      ..._buildSection(
                        _nameController,
                        _nameFocus,
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
                        snapshot.data == null,
                      ),
                      ..._buildSection(
                        _descriptionController,
                        _descriptionFocus,
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
                        snapshot.data == null,
                      ),
                      ..._buildSection(
                        _requestMessageController,
                        _requestMessageFocus,
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
                        snapshot.data == null,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.cw),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                              backgroundColor: WidgetStateProperty.resolveWith(
                                    (states) => AppColors.grey400,
                              ),
                            ),
                            onPressed: snapshot.data == null ? _handleSubmit : null,
                            child: Text(
                              snapshot.data == null ? '게시판 오픈 요청' : '게시판 오픈 검토중',
                              style: getTextStyle(AppTypo.body14B, AppColors.grey00),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32.cw),
                    ],
                  ),
                ),
              ),
            );
          },
      ),
    );
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
      FocusNode focusNode,
      String title,
      String hintText,
      int maxLines,
      String? Function(String?) validator,
      bool validated,
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
          focusNode: focusNode,
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
