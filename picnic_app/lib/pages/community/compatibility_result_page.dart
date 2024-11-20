import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_error.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_info.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_loading_view.dart';
import 'package:picnic_app/components/community/compatibility/compatibility_result.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_footer.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/providers/community/compatibility_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/vote_share_util.dart';

class CompatibilityResultPage extends ConsumerStatefulWidget {
  const CompatibilityResultPage({
    super.key,
    required this.compatibility,
  });

  final CompatibilityModel compatibility;

  @override
  ConsumerState<CompatibilityResultPage> createState() =>
      _CompatibilityResultScreenState();
}

class _CompatibilityResultScreenState
    extends ConsumerState<CompatibilityResultPage> {
  final GlobalKey _printKey = GlobalKey();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeIfNeeded();
  }

  void _initializeIfNeeded() {
    if (!_isInitialized &&
        widget.compatibility.status == CompatibilityStatus.pending) {
      _isInitialized = true;
      // 위젯 빌드 후에 provider 상태 초기화
      Future.microtask(() {
        if (!mounted) return;

        final currentState = ref.read(compatibilityProvider);
        // 이미 동일한 ID의 상태가 있다면 스킵
        if (currentState?.id == widget.compatibility.id) return;

        ref.read(compatibilityProvider.notifier).state = widget.compatibility;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compatibility =
        ref.watch(compatibilityProvider) ?? widget.compatibility;
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
                      birthDate: compatibility.birthDate,
                      birthTime: compatibility.birthTime,
                    ),
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
            if (compatibility.isCompleted) ...[
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
          ],
        ),
      ),
    );
  }
}
