import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';

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

  bool _isNameValid = false;
  bool _isDescriptionValid = false;
  bool _isRequestMessageValid = false;
  bool _isLoading = true;
  String? _error;
  late BoardRequestNotifier _boardRequestNotifier;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _requestMessageController = TextEditingController();
    _boardRequestNotifier = ref.read(boardRequestNotifierProvider.notifier);

    _setupControllers();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final request = await _boardRequestNotifier.build();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (request != null) {
          _nameController.text = getLocaleTextFromJson(request.name);
          _descriptionController.text = request.description;
          _requestMessageController.text = request.requestMessage ?? '';
        }
      });
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      rethrow;
    }
  }

  void _setupControllers() {
    _nameController.addListener(() {
      final isValid = _validateName(_nameController.text) == null;
      if (isValid != _isNameValid) {
        setState(() => _isNameValid = isValid);
      }
    });

    _descriptionController.addListener(() {
      final isValid = _validateDescription(_descriptionController.text) == null;
      if (isValid != _isDescriptionValid) {
        setState(() => _isDescriptionValid = isValid);
      }
    });

    _requestMessageController.addListener(() {
      final isValid =
          _validateRequestMessage(_requestMessageController.text) == null;
      if (isValid != _isRequestMessageValid) {
        setState(() => _isRequestMessageValid = isValid);
      }
    });
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
    // Provider 상태 구독
    final boardRequestState = ref.watch(boardRequestNotifierProvider);

    return boardRequestState.when(
      data: (pendingRequest) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(child: Text('Error: $_error'));
        }

        final bool isButtonEnabled = _isNameValid &&
            _isDescriptionValid &&
            _isRequestMessageValid &&
            pendingRequest == null;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.only(bottom: 300),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoBanner(),
                    ..._buildSection(
                      _nameController,
                      _nameFocus,
                      S.of(context).post_minor_board_name,
                      S.of(context).post_minor_board_name_input,
                      1,
                      _validateName,
                      pendingRequest == null,
                    ),
                    ..._buildSection(
                      _descriptionController,
                      _descriptionFocus,
                      S.of(context).post_minor_board_description,
                      S.of(context).post_minor_board_description_input,
                      3,
                      _validateDescription,
                      pendingRequest == null,
                    ),
                    ..._buildSection(
                      _requestMessageController,
                      _requestMessageFocus,
                      S.of(context).post_minor_board_create_request_message,
                      S
                          .of(context)
                          .post_minor_board_create_request_message_input,
                      3,
                      _validateRequestMessage,
                      pendingRequest == null,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.cw),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: Theme.of(context)
                              .elevatedButtonTheme
                              .style
                              ?.copyWith(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                  (states) => isButtonEnabled
                                      ? AppColors.primary500
                                      : AppColors.grey400,
                                ),
                              ),
                          onPressed: isButtonEnabled ? _handleSubmit : null,
                          child: Text(
                            pendingRequest == null
                                ? S.of(context).post_board_create_request_label
                                : S
                                    .of(context)
                                    .post_board_create_request_reviewing,
                            style:
                                getTextStyle(AppTypo.body14B, AppColors.grey00),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32.cw),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: ${error.toString()}'),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      try {
        final duplicate = await _boardRequestNotifier
            .checkDuplicateBoard(_nameController.text);
        if (duplicate != null) {
          if (!mounted) return;
          showSimpleDialog(
            content: S.of(context).post_board_already_exist,
            onOk: () => Navigator.of(context).pop(),
          );
          return;
        }

        await _boardRequestNotifier.createBoard(
          widget.artistId,
          _nameController.text,
          _descriptionController.text,
          _requestMessageController.text,
        );

        if (!mounted) return;
        showSimpleDialog(
          content: S.of(context).post_board_create_request_complete,
          onOk: () => Navigator.of(context).pop(),
        );
      } catch (e, s) {
        logger.e('Error submitting board request:', error: e, stackTrace: s);
        if (!mounted) return;
        showSimpleDialog(
          type: DialogType.error,
          content: S.of(context).message_error_occurred,
          onOk: () => Navigator.of(context).pop(),
        );
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).post_minor_board_name_input;
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).post_minor_board_description_input;
    }
    if (value.length < 5 || value.length > 20) {
      return S.of(context).post_minor_board_condition;
    }
    return null;
  }

  String? _validateRequestMessage(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).post_minor_board_create_request_message_input;
    }
    if (value.length < 10) {
      return S.of(context).post_minor_board_create_request_message_condition;
    }
    return null;
  }

  Widget _buildInfoBanner() {
    return Container(
      height: 30,
      decoration: const BoxDecoration(color: Color(0xFFF3EFFF)),
      child: Center(
        child: Text(
          S.of(context).post_board_create_request_condition,
          style: getTextStyle(AppTypo.caption12M, AppColors.primary500),
        ),
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
    bool enabled,
  ) {
    return [
      Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 16.cw, top: 24),
        child: Text(
          title,
          style: getTextStyle(AppTypo.body14B, AppColors.grey900),
        ),
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
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    ];
  }
}
