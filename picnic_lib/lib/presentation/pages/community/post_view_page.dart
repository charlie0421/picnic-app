import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/ads/banner_ad_widget.dart';
import 'package:picnic_lib/presentation/common/comment/comment_item.dart';
import 'package:picnic_lib/presentation/common/comment/comment_list.dart';
import 'package:picnic_lib/presentation/common/comment/post_popup_menu.dart';
import 'package:picnic_lib/presentation/dialogs/report_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/link_embed_builder.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/media_embed_builder.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/youtube_embed_builder.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

class PostViewPage extends ConsumerStatefulWidget {
  const PostViewPage(this.postId, {super.key});

  final String postId;

  @override
  ConsumerState<PostViewPage> createState() => _PostViewPageState();
}

class _PostViewPageState extends ConsumerState<PostViewPage> {
  late Future<PostModel> _postFuture;
  quill.QuillController? _quillController;
  String? _errorMessage;
  bool _isModalOpen = false;
  List<CommentModel>? _comments;
  bool _isLoadingComments = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _postFuture = _loadPost();
  }

  Future<PostModel> _loadPost({bool isIncrementViewCount = true}) async {
    if (_isDisposed) return Future.error('Widget is disposed');

    try {
      final updatedPost = await postById(ref, widget.postId,
          isIncrementViewCount: isIncrementViewCount);

      if (_isDisposed) return Future.error('Widget is disposed');

      if (updatedPost == null) {
        throw Exception(t('post_not_found'));
      }

      _initializeQuillController(updatedPost);
      _updateNavigationInfo(updatedPost);
      await _loadComments(updatedPost.postId);
      return updatedPost;
    } catch (e, s) {
      logger.e('Error loading post: $e', stackTrace: s);
      final errorMessage = _getErrorMessage(e);
      if (!_isDisposed) {
        setState(() => _errorMessage = errorMessage);
      }
      throw Exception(errorMessage);
    }
  }

  void _initializeQuillController(PostModel post) {
    if (_isDisposed) return;

    try {
      final content = _parseContent(post.content);
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(content),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e, s) {
      logger.e('Error initializing QuillController: $e', stackTrace: s);
      if (!_isDisposed) {
        setState(() => _errorMessage = t('error_content_parse'));
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return t('error_network_connection');
    } else if (error is TimeoutException) {
      return t('error_request_timeout');
    } else if (error is FormatException) {
      return t('error_invalid_data');
    } else {
      return t('error_unknown');
    }
  }

  void _updateNavigationInfo(PostModel post) {
    final currentBoard = ref.read(communityStateInfoProvider).currentBoard;
    ref.read(communityStateInfoProvider.notifier).setCurrentPost(post);
    ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.postView,
          showBottomNavigation: false,
          pageTitle: getLocaleTextFromJson(currentBoard!.name),
        );
  }

  List<dynamic> _parseContent(dynamic content) {
    try {
      if (content == null) {
        return [
          {"insert": ""}
        ];
      }
      return (content is String ? jsonDecode(content) : content) as List;
    } catch (e, s) {
      logger.e('Error parsing content: $e', stackTrace: s);
      return [
        {"insert": t('error_content_parse')}
      ];
    }
  }

  Future<void> _loadComments(String postId) async {
    if (_isDisposed) return;

    setState(() => _isLoadingComments = true);

    try {
      final loadedComments = await Future.value(
          ref.read(commentsNotifierProvider(postId, 1, 3).notifier).build(
                postId,
                1,
                3,
                includeDeleted: false,
                includeReported: false,
              )).timeout(const Duration(seconds: 10));

      if (_isDisposed) return;

      setState(() {
        _comments = loadedComments;
        _isLoadingComments = false;
      });
    } catch (e, s) {
      logger.e('Error loading comments: $e', stackTrace: s);
      if (!_isDisposed) {
        setState(() {
          _isLoadingComments = false;
          _errorMessage = _getErrorMessage(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _quillController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostModel>(
      future: _postFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LargePulseLoadingIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage ?? t('error_unknown'),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _postFuture = _loadPost();
                    });
                  },
                  child: Text(t('label_retry')),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(t('post_not_found')),
          );
        }

        final post = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () => _refreshPostAndComments(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BannerAdWidget(
                  configKey: 'POSTVIEW_TOP',
                  adSize: AdSize.fullBanner,
                ),
                // 컨텐츠

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    post.title ?? '',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
                  child: post.isAnonymous ?? false
                      ? Text(
                          t('anonymous'),
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.primary500),
                        )
                      : Text(
                          post.userProfiles?.nickname ?? '',
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.primary500),
                        ),
                ),
                _buildPostInfo(post),
                const Divider(color: AppColors.grey500),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: _buildContent(),
                ),
                BannerAdWidget(
                  configKey: 'POSTVIEW_BOTTOM',
                  adSize: AdSize.mediumRectangle,
                ),

                const SizedBox(height: 36),
                _buildCommentsList(post),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostInfo(PostModel post) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${t('views')}: ${post.viewCount}',
                style:
                    getTextStyle(AppTypo.caption10SB, const Color(0XFF8E8E8E)),
              ),
              SizedBox(width: 8.w),
              Text(
                '${t('replies')}: ${post.replyCount}',
                style:
                    getTextStyle(AppTypo.caption10SB, const Color(0XFF8E8E8E)),
              ),
              SizedBox(width: 8.w),
              Text(
                formatDateTimeYYYYMMDDHHM(post.createdAt!),
                style:
                    getTextStyle(AppTypo.caption10SB, const Color(0XFF8E8E8E)),
              ),
            ],
          ),
          PostPopupMenu(
            post: post,
            deletePost: () async {
              try {
                final ref = this.ref;
                await deletePost(ref, post.postId);
                ref.read(navigationInfoProvider.notifier).goBack();
              } catch (e, s) {
                logger.e('Error deleting post: $e', stackTrace: s);
                if (!_isDisposed) {
                  SnackbarUtil().showSnackbar(t('error_delete_post'));
                }
              }
            },
            openReportModal: (String title, PostModel post) async {
              try {
                setState(() {
                  _isModalOpen = true;
                });

                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return ReportDialog(
                      postId: post.postId,
                      title: title,
                      type: ReportType.post,
                      target: post,
                    );
                  },
                );

                if (!_isDisposed) {
                  if (result == null) {
                    setState(() {
                      _isModalOpen = false;
                    });
                  } else {
                    ref.read(navigationInfoProvider.notifier).goBack();
                  }
                }
              } catch (e, s) {
                logger.e('Error showing report dialog: $e', stackTrace: s);
              }
            },
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red),
      );
    }
    if (_quillController == null) {
      return const Center(child: MediumPulseLoadingIndicator());
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100),
      child: quill.QuillEditor(
        controller: _quillController!,
        scrollController: ScrollController(),
        focusNode: AlwaysDisabledFocusNode(),
        config: quill.QuillEditorConfig(
          embedBuilders: [
            LinkEmbedBuilder(),
            YouTubeEmbedBuilder(),
            NetworkImageEmbedBuilder(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(PostModel post) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary500),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (_isLoadingComments)
                const Center(child: MediumPulseLoadingIndicator())
              else if (_comments == null || _comments!.isEmpty)
                _buildEmptyComments(post)
              else
                _buildCommentItems(post),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 120.w,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary500,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t('comments'),
              style: getTextStyle(AppTypo.body14B, AppColors.grey00),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyComments(PostModel post) {
    return Center(
      child: Column(
        children: [
          Text(t('post_no_comment')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openCommentsModal(post),
            child: Text(
              t('post_comment_write_label'),
              style: getTextStyle(AppTypo.body14B, AppColors.grey00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItems(PostModel post) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _comments!.length,
          itemBuilder: (context, index) {
            return CommentItem(
              postId: post.postId,
              commentModel: _comments![index],
              pagingController: null,
              showReplyButton: false,
              openCommentsModal: () => _openCommentsModal(post),
              openReportModal: (String title, CommentModel comment) {
                _handleCommentReport(title, comment, post);
              },
            );
          },
        ),
        ElevatedButton(
          onPressed: () => _openCommentsModal(post),
          child: Text(
            t('post_comment_content_more'),
            style: getTextStyle(AppTypo.body14B, AppColors.grey00),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCommentReport(
    String title,
    CommentModel comment,
    PostModel post,
  ) async {
    setState(() {
      _isModalOpen = true;
    });

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ReportDialog(
          postId: post.postId,
          title: title,
          type: ReportType.comment,
          target: comment,
        );
      },
    );

    if (!_isDisposed) {
      setState(() {
        _isModalOpen = false;
      });
      _refreshPostAndComments();
    }
  }

  void _openCommentsModal(PostModel post) {
    if (!isSupabaseLoggedSafely) {
      showRequireLoginDialog();
      return;
    }

    setState(() {
      _isModalOpen = true;
    });

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      constraints: BoxConstraints(
        maxHeight: ref.watch(globalMediaQueryProvider).size.height -
            getAppBarHeight(ref),
      ),
      builder: (context) => SafeArea(
        child: CommentList(
          id: post.postId,
          title: t('replies'),
          openReportModal: (String title, CommentModel comment) {
            _handleCommentReport(title, comment, post);
          },
        ),
      ),
    ).then((_) {
      if (!_isDisposed) {
        setState(() {
          _isModalOpen = false;
        });
        _refreshPostAndComments();
      }
    });
  }

  Future<void> _refreshPostAndComments() async {
    if (_isDisposed || _isModalOpen) return;

    try {
      await _loadComments(widget.postId);
      _postFuture = _loadPost(isIncrementViewCount: false);
      if (!_isDisposed) {
        setState(() {});
      }
    } catch (e, s) {
      logger.e('Error refreshing data: $e', stackTrace: s);
    }
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
