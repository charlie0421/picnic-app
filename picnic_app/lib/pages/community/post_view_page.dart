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
import 'package:picnic_app/components/community/write/embed_builder/link_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/media_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/youtube_embed_builder.dart';
import 'package:picnic_app/config/config_service.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/comminuty_navigation_provider.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/ui.dart';

class PostViewPage extends ConsumerStatefulWidget {
  const PostViewPage(
    this.post, {
    super.key,
  });

  final PostModel post;

  @override
  ConsumerState<PostViewPage> createState() => _PostViewPageState();
}

class _PostViewPageState extends ConsumerState<PostViewPage> {
  quill.QuillController? _quillController;
  String? _errorMessage;
  BannerAd? _topBannerAd;
  BannerAd? _bottomBannerAd;
  bool _isTopAdLoaded = false;
  bool _isBottomAdLoaded = false;
  int _topAdRetryAttempt = 0;
  int _bottomAdRetryAttempt = 0;
  final int _maxRetryAttempts = 3;
  final int _retryDelay = 1000; // milliseconds

  bool get _shouldShowAds => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
    if (_shouldShowAds) {
      _preloadAds();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentBoardName = ref.read(
        communityNavigationInfoProvider
            .select((value) => value.currentBoardName),
      );

      logger.d('currentBoardName: $currentBoardName');

      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          showBottomNavigation: false,
          pageTitle: currentBoardName,
          topRightMenu: TopRightType.none);
    });
  }

  void _initializeQuillController() {
    try {
      final content = _parseContent(widget.post.content);
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(content),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      logger.i('Error initializing QuillController: $e');
      setState(() {
        _errorMessage = '내용을 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  List<dynamic> _parseContent(dynamic content) {
    if (content is String) {
      try {
        final List<dynamic> parsedContent = jsonDecode(content);
        return parsedContent.map((item) {
          if (item is String) {
            return jsonDecode(item);
          }
          return item;
        }).toList();
      } catch (e) {
        throw FormatException('Failed to parse content as JSON: $e');
      }
    } else if (content is List) {
      return content.map((item) {
        if (item is String) {
          return jsonDecode(item);
        }
        return item;
      }).toList();
    } else {
      throw const FormatException('Unexpected content format');
    }
  }

  void _preloadAds() async {
    ConfigService configService = ref.read(configServiceProvider);
    String? adUnitIdTop = await (Platform.isIOS
        ? configService.getConfig('ADMOB_IOS_POSTVIEW_TOP')
        : configService.getConfig('ADMOB_ANDROID_POSTVIEW_TOP'));
    String? adUnitIdBBottom = await (Platform.isIOS
        ? configService.getConfig('ADMOB_IOS_POSTVIEW_BOTTOM')
        : configService.getConfig('ADMOB_ANDROID_POSTVIEW_BOTTOM'));

    if (adUnitIdTop == null || adUnitIdBBottom == null) {
      logger.i('Failed to get ad unit ID');
      return;
    }

    _loadTopAd(adUnitIdTop);
    _loadBottomAd(adUnitIdBBottom);
  }

  void _loadTopAd(String adUnitId) {
    _topBannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isTopAdLoaded = true;
          });
          logger.i('Top ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          logger.i('Top ad failed to load: $error');
          _retryTopAdLoad(adUnitId);
        },
      ),
    );

    _topBannerAd?.load();
  }

  void _loadBottomAd(String adUnitId) {
    _bottomBannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBottomAdLoaded = true;
          });
          logger.i('Bottom ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          logger.i('Bottom ad failed to load: $error');
          _retryBottomAdLoad(adUnitId);
        },
      ),
    );

    _bottomBannerAd?.load();
  }

  void _retryTopAdLoad(String adUnitId) {
    if (_topAdRetryAttempt < _maxRetryAttempts) {
      _topAdRetryAttempt++;
      Future.delayed(Duration(milliseconds: _retryDelay * _topAdRetryAttempt),
          () {
        _loadTopAd(adUnitId);
      });
    }
  }

  void _retryBottomAdLoad(String adUnitId) {
    if (_bottomAdRetryAttempt < _maxRetryAttempts) {
      _bottomAdRetryAttempt++;
      Future.delayed(
          Duration(milliseconds: _retryDelay * _bottomAdRetryAttempt), () {
        _loadBottomAd(adUnitId);
      });
    }
  }

  @override
  void dispose() {
    _quillController?.dispose();
    _topBannerAd?.dispose();
    _bottomBannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_shouldShowAds) _buildTopAdSpace(),
          Padding(
            padding: EdgeInsets.only(left: 16.cw, right: 16.cw),
            child: Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.cw, right: 16.cw, top: 8),
            child: Text(
              widget.post.user_profiles?.nickname ?? '',
              style: getTextStyle(AppTypo.caption12B, AppColors.primary500),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.cw, right: 16.cw, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '조회: ${widget.post.view_count}',
                      style: getTextStyle(
                          AppTypo.caption10SB, const Color(0XFF8E8E8E)),
                    ),
                    SizedBox(width: 8.cw),
                    Text(
                      '댓글: ${widget.post.reply_count}',
                      style: getTextStyle(
                          AppTypo.caption10SB, const Color(0XFF8E8E8E)),
                    ),
                    SizedBox(width: 8.cw),
                    Text(
                      formatDateTimeYYYYMMDDHHM(widget.post.created_at),
                      style: getTextStyle(
                          AppTypo.caption10SB, const Color(0XFF8E8E8E)),
                    ),
                  ],
                ),
                Text(
                  '신고',
                  style: getTextStyle(
                      AppTypo.caption10SB, const Color(0XFF8E8E8E)),
                )
              ],
            ),
          ),
          const Divider(color: AppColors.grey500),
          Padding(
            padding: EdgeInsets.all(16.cw),
            child: _buildContent(),
          ),
          if (_shouldShowAds) _buildBottomAdSpace(),
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
        focusNode: FocusNode(),
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

  Widget _buildTopAdSpace() {
    return SizedBox(
      height: 50, // Height of a standard banner ad
      child: _isTopAdLoaded && _topBannerAd != null
          ? AdWidget(ad: _topBannerAd!)
          : Container(),
    );
  }

  Widget _buildBottomAdSpace() {
    return SizedBox(
      height: 250, // Height of a medium rectangle ad
      child: _isBottomAdLoaded && _bottomBannerAd != null
          ? AdWidget(ad: _bottomBannerAd!)
          : Container(),
    );
  }

  Widget _buildCommentsList() {
    return Container(
      padding: EdgeInsets.all(16.cw),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary500),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - 120),
                  builder: (context) {
                    return CommentList(
                        id: widget.post.post_id,
                        commentsProvider,
                        'title',
                        postComment);
                  });
            },
            child: FutureBuilder(
              future: comments(ref, widget.post.post_id, 1, 3),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data == null) {
                  return const Center(child: Text('댓글이 없습니다.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    CommentModel? comment = snapshot.data?[index];
                    return CommentItem(
                      commentModel: snapshot.data![index],
                      pagingController: null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
