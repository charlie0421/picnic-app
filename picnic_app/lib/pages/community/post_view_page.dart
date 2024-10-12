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
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/report_dialog.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/global_media_query.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class PostViewPage extends ConsumerStatefulWidget {
  const PostViewPage(this.post, {super.key});

  final PostModel post;

  @override
  ConsumerState<PostViewPage> createState() => _PostViewPageState();
}

class _PostViewPageState extends ConsumerState<PostViewPage> {
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
    _initializeQuillController();
    if (_shouldShowAds) {
      _loadAds();
    }
    _loadComments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentBoard = ref.watch(
        communityStateInfoProvider.select((value) => value.currentBoard),
      );
      ref.read(communityStateInfoProvider.notifier).setCurrentPost(widget.post);
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showBottomNavigation: false,
            pageTitle: currentBoard!.is_official
                ? getLocaleTextFromJson(currentBoard.name)
                : widget.post.title,
          );
    });
  }

  void _initializeQuillController() {
    try {
      final content = _parseContent(widget.post.content);
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(content),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e, s) {
      logger.e('Error initializing QuillController: $e', stackTrace: s);
      setState(() {
        _errorMessage = '내용을 불러오는 중 오류가 발생했습니다.';
      });
      rethrow;
    }
  }

  Future<void> _loadAds() async {
    final configService = ref.read(configServiceProvider);
    final topAdUnitId = Platform.isIOS
        ? await configService.getConfig('ADMOB_IOS_POSTVIEW_TOP')
        : await configService.getConfig('ADMOB_ANDROID_POSTVIEW_TOP');
    final bottomAdUnitId = Platform.isIOS
        ? await configService.getConfig('ADMOB_IOS_POSTVIEW_BOTTOM')
        : await configService.getConfig('ADMOB_ANDROID_POSTVIEW_BOTTOM');

    if (topAdUnitId != null) {
      _loadBannerAd('top', topAdUnitId, AdSize.banner);
    }
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
        onAdLoaded: (_) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAds[position] = null;
        },
      ),
    )..load();
  }

  void _loadComments() async {
    if (!mounted) return; // 먼저 체크
    setState(() {
      _isLoadingComments = true;
    });
    try {
      final loadedComments = await comments(ref, widget.post.post_id, 1, 3,
          includeDeleted: false, includeReported: false);
      if (!mounted) return; // 비동기 작업 후 다시 체크
      setState(() {
        _comments = loadedComments;
        _isLoadingComments = false;
      });
    } catch (e, s) {
      logger.e('Error loading comments: $e', stackTrace: s);
      if (!mounted) return; // 예외 처리 시에도 체크
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  List<dynamic> _parseContent(dynamic content) {
    if (content is String) {
      try {
        return (jsonDecode(content) as List)
            .map((item) => item is String ? jsonDecode(item) : item)
            .toList();
      } catch (e, s) {
        logger.e(e, stackTrace: s);
        rethrow;
      }
    } else if (content is List) {
      return content
          .map((item) => item is String ? jsonDecode(item) : item)
          .toList();
    } else {
      throw const FormatException('Unexpected content format');
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_shouldShowAds) _buildAdSpace('top', AdSize.banner),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.cw),
            child: Text(widget.post.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 8),
              child: widget.post.is_anonymous
                  ? Text('잌명',
                      style: getTextStyle(
                          AppTypo.caption12B, AppColors.primary500))
                  : Text(widget.post.user_profiles?.nickname ?? '',
                      style: getTextStyle(
                          AppTypo.caption12B, AppColors.primary500))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('조회: ${widget.post.view_count}',
                        style: getTextStyle(
                            AppTypo.caption10SB, const Color(0XFF8E8E8E))),
                    SizedBox(width: 8.cw),
                    Text('댓글: ${widget.post.reply_count}',
                        style: getTextStyle(
                            AppTypo.caption10SB, const Color(0XFF8E8E8E))),
                    SizedBox(width: 8.cw),
                    Text(formatDateTimeYYYYMMDDHHM(widget.post.created_at),
                        style: getTextStyle(
                            AppTypo.caption10SB, const Color(0XFF8E8E8E))),
                  ],
                ),
                PostPopupMenu(
                    post: widget.post,
                    context: context,
                    openReportModal: _openPostReportModal,
                    refreshFunction:
                        ref.read(navigationInfoProvider.notifier).goBack),
              ],
            ),
          ),
          const Divider(color: AppColors.grey500),
          Padding(
            padding: EdgeInsets.all(16.cw),
            child: _buildContent(),
          ),
          if (_shouldShowAds) _buildAdSpace('bottom', AdSize.mediumRectangle),
          const SizedBox(height: 36),
          _buildCommentsList(),
        ],
      ),
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
            NetworkImageEmbedBuilder()
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

  Widget _buildCommentsList() {
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
                            const Text('댓글이 없습니다.'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _openCommentsModal,
                              child: Text('댓글 쓰기',
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
                                  commentModel: _comments![index],
                                  pagingController: null,
                                  showReplyButton: false,
                                  openCommentsModal: _openCommentsModal,
                                  openReportModal: _openCommentReportModal,
                                );
                              },
                            ),
                            ElevatedButton(
                              onPressed: _openCommentsModal,
                              child: Text('더보기',
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
                  textAlign: TextAlign.center)),
        ),
      ],
    );
  }

  void _openCommentsModal() {
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
          maxHeight: ref.watch(globalMediaQueryProviderProvider).size.height -
              getAppBarHeight(ref)),
      builder: (context) {
        return SafeArea(
          child: CommentList(
            id: widget.post.post_id,
            '댓글',
            openReportModal: _openCommentReportModal,
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isModalOpen = false;
        if (_shouldShowAds) {
          _loadAds();
        }
      });
      _loadComments(); // Reload comments after modal is closed
    });
  }

  void _openCommentReportModal(String title, CommentModel comment) {
    setState(() {
      _isModalOpen = true;
      for (var ad in _bannerAds.values) {
        ad?.dispose();
      }
      _bannerAds.clear();
    });
    logger.d('Open report modal');
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return ReportDialog(
              title: title, type: ReportType.comment, target: comment);
        }).then((_) {
      setState(() {
        _isModalOpen = false;
        if (_shouldShowAds) {
          _loadAds();
        }
      });
      _loadComments(); // Reload comments after modal is closed
    });
  }

  void _openPostReportModal(String title, PostModel post) {
    try {
      setState(() {
        _isModalOpen = true;
        for (var ad in _bannerAds.values) {
          ad?.dispose();
        }
        _bannerAds.clear();
      });
      logger.d('Open report modal');
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return ReportDialog(
                title: title, type: ReportType.post, target: post);
          }).then((_) {
        setState(() {
          _isModalOpen = false;
          if (_shouldShowAds) {
            _loadAds();
          }
        });
      });
    } catch (e, s) {
      logger.e('Error: $e, StackTrace: $s');
    }
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
