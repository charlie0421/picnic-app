import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_app/components/common/comment/comment_item.dart';
import 'package:picnic_app/components/common/comment/comment_list.dart';
import 'package:picnic_app/components/common/comment/post_popup_menu.dart';
import 'package:picnic_app/components/community/write/embed_builder/link_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/media_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/youtube_embed_builder.dart';
import 'package:picnic_app/config/config_service.dart';
import 'package:picnic_app/dialogs/report_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/global_media_query.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

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
  final bool _shouldShowAds = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  final Map<String, BannerAd?> _bannerAds = {};
  List<CommentModel>? _comments;
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _postFuture = _loadPost();
    if (_shouldShowAds) _loadAds();
  }

  Future<PostModel> _loadPost({bool isIncrementViewCount = true}) async {
    try {
      final updatedPost = await postById(ref, widget.postId,
          isIncrementViewCount: isIncrementViewCount);
      if (updatedPost != null) {
        _initializeQuillController(updatedPost);
        _updateNavigationInfo(updatedPost);
        await _loadComments(updatedPost.postId);
        return updatedPost;
      } else {
        throw Exception('Failed to load post');
      }
    } catch (e, s) {
      logger.e('Error loading post: $e', stackTrace: s);
      rethrow;
    }
  }

  void _initializeQuillController(PostModel post) {
    try {
      final content = _parseContent(post.content);
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(content),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e, s) {
      logger.e('Error initializing QuillController: $e', stackTrace: s);
      _errorMessage = S.of(context).post_loading_post_fail;
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
          pageTitle: currentBoard!.isOfficial
              ? getLocaleTextFromJson(currentBoard.name)
              : post.title,
        );
  }

  Future<void> _loadAds() async {
    final configService = ref.read(configServiceProvider);
    final topAdUnitId = Platform.isIOS
        ? await configService.getConfig('ADMOB_IOS_POSTVIEW_TOP')
        : await configService.getConfig('ADMOB_ANDROID_POSTVIEW_TOP');
    final bottomAdUnitId = Platform.isIOS
        ? await configService.getConfig('ADMOB_IOS_POSTVIEW_BOTTOM')
        : await configService.getConfig('ADMOB_ANDROID_POSTVIEW_BOTTOM');

    if (topAdUnitId != null) _loadBannerAd('top', topAdUnitId, AdSize.banner);
    if (bottomAdUnitId != null) {
      _loadBannerAd('bottom', bottomAdUnitId, AdSize.mediumRectangle);
    }
  }

  void _loadBannerAd(String position, String adUnitId, AdSize size) {
    _bannerAds[position] = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAds[position] = null;
        },
      ),
    )..load();
  }

  Future<void> _loadComments(String postId) async {
    if (!mounted) return;
    setState(() => _isLoadingComments = true);
    try {
      final loadedComments =
          await ref.read(commentsNotifierProvider(postId, 1, 3).notifier).build(
                postId,
                1,
                3,
                includeDeleted: false,
                includeReported: false,
              );
      if (!mounted) return;
      setState(() {
        _comments = loadedComments;
        _isLoadingComments = false;
      });
    } catch (e, s) {
      logger.e('Error loading comments: $e', stackTrace: s);
      if (!mounted) return;
      setState(() => _isLoadingComments = false);
    }
  }

  List<dynamic> _parseContent(dynamic content) {
    try {
      return (content is String ? jsonDecode(content) : content) as List;
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      rethrow;
    }
  }

  @override
  void dispose() {
    _quillController?.dispose();
    for (var ad in _bannerAds.values) {
      ad?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostModel>(
      future: _postFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final post = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_shouldShowAds) _buildAdSpace('top', AdSize.banner),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.cw),
                  child: Text(post.title ?? '',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 8),
                  child: post.isAnonymous ?? false
                      ? Text(S.of(context).anonymous,
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.primary500))
                      : Text(post.userProfiles?.nickname ?? '',
                          style: getTextStyle(
                              AppTypo.caption12B, AppColors.primary500)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.cw),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('${S.of(context).views}: ${post.viewCount}',
                              style: getTextStyle(AppTypo.caption10SB,
                                  const Color(0XFF8E8E8E))),
                          SizedBox(width: 8.cw),
                          Text('${S.of(context).replies}: ${post.replyCount}',
                              style: getTextStyle(AppTypo.caption10SB,
                                  const Color(0XFF8E8E8E))),
                          SizedBox(width: 8.cw),
                          Text(formatDateTimeYYYYMMDDHHM(post.createdAt),
                              style: getTextStyle(AppTypo.caption10SB,
                                  const Color(0XFF8E8E8E))),
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
                            logger.e('Error: $e, StackTrace: $s');
                            rethrow;
                          }
                        },
                        openReportModal: (String title, PostModel post) async {
                          try {
                            setState(() {
                              _isModalOpen = true;
                              for (var ad in _bannerAds.values) {
                                ad?.dispose();
                              }
                              _bannerAds.clear();
                            });
                            await showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) {
                                return ReportDialog(
                                    postId: post.postId,
                                    title: title,
                                    type: ReportType.post,
                                    target: post);
                              },
                            ).then((value) {
                              logger.i('Report dialog result: $value');
                              if (value == null) {
                                setState(() {
                                  _isModalOpen = false;
                                  if (_shouldShowAds) _loadAds();
                                });
                              } else {
                                ref
                                    .read(navigationInfoProvider.notifier)
                                    .goBack();
                              }
                            });
                          } catch (e, s) {
                            logger.e('Error: $e, StackTrace: $s');
                          }
                        },
                        context: context,
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.grey500),
                Padding(
                  padding: EdgeInsets.all(16.cw),
                  child: _buildContent(),
                ),
                if (_shouldShowAds)
                  _buildAdSpace('bottom', AdSize.mediumRectangle),
                const SizedBox(height: 36),
                _buildCommentsList(post),
              ],
            ),
          );
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Text(_errorMessage!, style: const TextStyle(color: Colors.red));
    }
    if (_quillController == null) {
      return const CircularProgressIndicator();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 100),
      child: quill.QuillEditor(
        controller: _quillController!,
        scrollController: ScrollController(),
        focusNode: AlwaysDisabledFocusNode(),
        configurations: quill.QuillEditorConfigurations(
          embedBuilders: [
            LinkEmbedBuilder(),
            YouTubeEmbedBuilder(),
            NetworkImageEmbedBuilder(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdSpace(String position, AdSize size) {
    return Center(
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: _isModalOpen
            ? null
            : _bannerAds[position] != null
                ? AdWidget(ad: _bannerAds[position]!)
                : null,
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
              _isLoadingComments
                  ? const Center(child: CircularProgressIndicator())
                  : _comments == null || _comments!.isEmpty
                      ? Center(
                          child: Column(
                          children: [
                            Text(S.of(context).post_no_comment),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _openCommentsModal(post),
                              child: Text(
                                  S.of(context).post_comment_write_label,
                                  style: getTextStyle(
                                      AppTypo.body14B, AppColors.grey00)),
                            ),
                          ],
                        ))
                      : Column(
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
                                  openCommentsModal: () =>
                                      _openCommentsModal(post),
                                  openReportModal:
                                      (String title, CommentModel comment) {
                                    setState(() {
                                      _isModalOpen = true;
                                      for (var ad in _bannerAds.values) {
                                        ad?.dispose();
                                      }
                                      _bannerAds.clear();
                                    });
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (BuildContext context) {
                                        return ReportDialog(
                                            postId: post.postId,
                                            title: title,
                                            type: ReportType.comment,
                                            target: comment);
                                      },
                                    ).then((_) {
                                      setState(() {
                                        _isModalOpen = false;
                                        if (_shouldShowAds) _loadAds();
                                      });
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        _loadPost(isIncrementViewCount: false);
                                        _loadComments(widget.postId);
                                      });
                                    });
                                  },
                                );
                              },
                            ),
                            ElevatedButton(
                              onPressed: () => _openCommentsModal(post),
                              child: Text(
                                  S.of(context).post_comment_content_more,
                                  style: getTextStyle(
                                      AppTypo.body14B, AppColors.grey00)),
                            ),
                          ],
                        ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 120.cw,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary500,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Comments',
                style: getTextStyle(AppTypo.body14B, AppColors.grey00),
                textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  void _openCommentsModal(PostModel post) {
    setState(() {
      _isModalOpen = true;
      for (var ad in _bannerAds.values) {
        ad?.dispose();
      }
      _bannerAds.clear();
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
      builder: (context) {
        return SafeArea(
          child: CommentList(
            id: post.postId,
            S.of(context).replies,
            openReportModal: (String title, CommentModel comment) {
              setState(() {
                _isModalOpen = true;
                for (var ad in _bannerAds.values) {
                  ad?.dispose();
                }
                _bannerAds.clear();
              });
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return ReportDialog(
                      postId: post.postId,
                      title: title,
                      type: ReportType.comment,
                      target: comment);
                },
              ).then((_) {
                setState(() {
                  _isModalOpen = false;
                  if (_shouldShowAds) _loadAds();
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadPost(isIncrementViewCount: false);
                  _loadComments(widget.postId);
                });
              });
            },
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isModalOpen = false;
        if (_shouldShowAds) _loadAds();
      });
      _refreshPostAndComments();
    });
  }

  void _refreshPostAndComments() {
    _loadComments(widget.postId);
    _postFuture = _loadPost(isIncrementViewCount: false);
    setState(() {});
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
