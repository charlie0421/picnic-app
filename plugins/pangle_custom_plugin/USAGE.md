# Pangle 커스텀 플러그인 사용 예제

## 기본 사용법

```dart
import 'package:pangle_custom_plugin/pangle_custom_plugin.dart';

void main() async {
  // 앱 시작 시 Pangle SDK 초기화
  await PanglePlugin.initPangle('your_pangle_app_id');
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAdLoaded = false;
  
  @override
  void initState() {
    super.initState();
    // 광고 미리 로드 (옵션)
    _loadAd();
  }
  
  Future<void> _loadAd() async {
    // 광고 로드
    final isLoaded = await PanglePlugin.loadRewardedAd('your_placement_id');
    
    setState(() {
      _isAdLoaded = isLoaded;
    });
  }
  
  Future<void> _showAd() async {
    if (!_isAdLoaded) {
      // 광고가 아직 로드되지 않았으면 다시 로드
      await _loadAd();
      
      if (!_isAdLoaded) {
        // 광고 로드 실패시 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('광고를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.'))
        );
        return;
      }
    }
    
    // 보상형 광고 표시
    final isRewarded = await PanglePlugin.showRewardedAd();
    
    if (isRewarded) {
      // 보상 지급 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('보상이 지급되었습니다!'))
      );
      
      // 광고 시청 후 다시 광고 로드 (다음 시청을 위해)
      _loadAd();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('광고 시청이 완료되지 않았습니다.'))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pangle 광고 예제')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('광고 상태: ${_isAdLoaded ? "준비됨" : "로드 중"}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAd,
              child: Text('보상형 광고 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 주의사항

1. 실제 개발 시에는 앱 ID와 광고 ID를 실제 Pangle 대시보드에서 발급받은 값으로 변경해야 합니다.
2. Android와 iOS 플랫폼에 대한 네이티브 설정이 필요합니다. README.md 파일을 참조하세요.
3. 광고 로드 실패, 네트워크 연결 오류 등의 예외 상황을 적절히 처리해야 합니다.
4. 보상형 광고는 사용자에게 광고 시청 여부를 명확히 안내하고 동의를 얻은 후 표시해야 합니다. 