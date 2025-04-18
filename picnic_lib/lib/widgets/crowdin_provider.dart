import 'package:flutter/material.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';

/// Crowdin OTA 로컬라이제이션을 사용하기 위한 프로바이더 위젯
/// 앱 트리 최상단에 위치시켜 모든 하위 위젯에서 Crowdin 번역에 접근할 수 있게 함
class CrowdinProvider extends StatefulWidget {
  /// 생성자
  const CrowdinProvider({
    super.key,
    required this.distributionHash,
    required this.child,
    this.sourceLanguage = 'en',
    this.connectionType = InternetConnectionType.any,
    this.updatesInterval = const Duration(minutes: 15),
  });

  /// Crowdin 배포 해시
  final String distributionHash;

  /// 기본 언어
  final String sourceLanguage;

  /// 인터넷 연결 타입
  final InternetConnectionType connectionType;

  /// 업데이트 간격
  final Duration updatesInterval;

  /// 자식 위젯
  final Widget child;

  @override
  State<CrowdinProvider> createState() => _CrowdinProviderState();
}

class _CrowdinProviderState extends State<CrowdinProvider> {
  @override
  void initState() {
    super.initState();
    _initializeCrowdin();
  }

  Future<void> _initializeCrowdin() async {
    try {
      await Crowdin.init(
        distributionHash: widget.distributionHash,
        connectionType: widget.connectionType,
        updatesInterval: widget.updatesInterval,
      );

      // 기본적으로 현재 로케일의 번역을 로드
      await Crowdin.loadTranslations(Locale(widget.sourceLanguage));
    } catch (e) {
      debugPrint('Crowdin 초기화 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
