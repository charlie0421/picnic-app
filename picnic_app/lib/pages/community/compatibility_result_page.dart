import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_error.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_loading_view.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_result.dart';
import 'package:picnic_app/components/loading_view.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_footer.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'dart:io';

import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/vote_share_util.dart';

class CompatibilityResultScreen extends ConsumerStatefulWidget {
  const CompatibilityResultScreen({
    super.key,
    required this.compatibilityId,
  });

  final String compatibilityId;

  @override
  ConsumerState<CompatibilityResultScreen> createState() =>
      _CompatibilityResultScreenState();
}

class _CompatibilityResultScreenState
    extends ConsumerState<CompatibilityResultScreen> {
  final GlobalKey _printKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCompatibility();
  }

  Future<void> _loadCompatibility() async {
    final compatibility = ref.read(compatibilityProvider);
    if (compatibility == null || compatibility.id != widget.compatibilityId) {
      try {
        await ref.read(compatibilityProvider.notifier).refreshCompatibility();
      } catch (e) {
        logger.e('Error loading compatibility', error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compatibility = ref.watch(compatibilityProvider);

    if (compatibility == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RepaintBoundary(
              key: _printKey,
              child: Container(
                color: AppColors.grey00,
                child: Column(
                  children: [
                    CompatibilityInfo(
                        artist: compatibility.artist,
                        ref: ref,
                        birthDate: compatibility.birthDate),
                    switch (compatibility.status) {
                      CompatibilityStatus.pending =>
                        const CompatibilityLoadingView(),
                      CompatibilityStatus.error => CompatibilityErrorView(
                          error: compatibility.errorMessage ??
                              '알 수 없는 오류가 발생했습니다.',
                        ),
                      CompatibilityStatus.completed => CompatibilityResultView(
                          compatibility: compatibility,
                        ),
                    },
                  ],
                ),
              ),
            ),
            VoteCardInfoFooter(
              saveButtonText: '이미지 저장',
              shareButtonText: '공유하기',
              onSave: () => VoteShareUtils.captureAndSaveImage(
                _printKey,
                context,
                onStart: () {},
                onComplete: () {},
              ),
              onShare: () => VoteShareUtils.shareToTwitter(
                _printKey,
                title: getLocaleTextFromJson(compatibility.artist.name),
                context,
                onStart: () {},
                onComplete: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
