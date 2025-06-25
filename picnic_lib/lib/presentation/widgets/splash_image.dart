import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:universal_platform/universal_platform.dart';

class SplashImageData {
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;

  SplashImageData({
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
  });
}

class SplashImage extends ConsumerStatefulWidget {
  final String? statusMessage; // 패치 상태 메시지를 받을 수 있는 파라미터 추가

  const SplashImage({
    super.key,
    this.statusMessage,
  });

  @override
  ConsumerState<SplashImage> createState() => _OptimizedSplashImageState();
}

class _OptimizedSplashImageState extends ConsumerState<SplashImage> {
  String? scheduledSplashUrl;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();

    // 웹 환경에서는 스플래시 이미지를 가져오지 않음
    if (UniversalPlatform.isWeb) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchScheduledSplashImage();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // setState 호출을 안전하게 하기 위한 헬퍼 메서드
  void setStateIfMounted(VoidCallback fn) {
    if (!mounted || _disposed) return;
    setState(fn);
  }

  Future<void> _fetchScheduledSplashImage() async {
    logger.d('스플래시 이미지 fetch 시작');
    try {
      // Supabase RPC 함수 호출
      final response =
          await supabase.rpc('get_current_splash_image').maybeSingle();

      logger.d('스플래시 response: $response');

      // response.data가 null 이면, 현재 노출할 이미지가 없다는 의미
      if (response == null) {
        logger.d('스플래시 이미지 없음');
        return;
      }

      final splashData = SplashImageData(
        imageUrl: getLocaleTextFromJson(response['image']),
        startDate: DateTime.parse(response['start_at'] as String),
        endDate: DateTime.parse(response['end_at'] as String),
      );

      logger.d('스플래시 데이터: $splashData');

      setStateIfMounted(() {
        scheduledSplashUrl = splashData.imageUrl;
        logger.d('스플래시 이미지 url: $scheduledSplashUrl');
      });
    } catch (e, stack) {
      logger.e('스플래시 이미지 fetch 실패: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹 환경에서는 스플래시 이미지를 표시하지 않음
    if (UniversalPlatform.isWeb) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) 기본(로컬) 스플래시 이미지
        Image.asset(
          'assets/splash.webp',
          fit: BoxFit.cover,
        ),

        // 2) 서버에서 조회된 이미지가 있으면 덮어씌우기
        if (scheduledSplashUrl != null)
          PicnicCachedNetworkImage(
            imageUrl: scheduledSplashUrl!,
            fit: BoxFit.contain,
          ),

        // 3) 상태 메시지 표시 (패치 체크 진행 상황 등)
        if (widget.statusMessage != null && widget.statusMessage!.isNotEmpty)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: SizedBox(
                height: 32,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.statusMessage!,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey00)
                          .copyWith(decoration: TextDecoration.none),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 16),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: SmallPulseLoadingIndicator(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
