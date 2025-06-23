<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# 🌟 PicnicLib LoadingOverlay

Flutter 앱을 위한 **포괄적인 로딩 오버레이 라이브러리**입니다. 다양한 애니메이션, 테마, 그리고 **앱 아이콘 애니메이션**을 지원하는 전체화면 로딩 화면을 제공합니다.

## ✨ 주요 기능

- 🎯 **5가지 로딩 오버레이 타입** (기본, 앱 아이콘, 간단, 고급, 매니저)
- 🎨 **앱 아이콘 애니메이션** (회전, 스케일, 페이드 효과)
- 🎭 **4가지 테마** (다크, 라이트, 투명, 블러)
- 🎪 **5가지 애니메이션** (페이드, 스케일, 슬라이드, 회전)
- 🚀 **성능 최적화** (RepaintBoundary, 지연 초기화, FPS 모니터링)
- 🎛️ **Riverpod 상태 관리** 지원
- 🔧 **커스터마이징** (메시지, 색상, 애니메이션 설정)
- ♿ **접근성** 지원

## 🚀 빠른 시작

### 1. LoadingOverlayWithIcon (추천!)
**앱 아이콘이 중앙에서 애니메이션되는 로딩 화면**

```dart
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_widgets.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey = 
      GlobalKey<LoadingOverlayWithIconState>();

  @override
  Widget build(BuildContext context) {
    return LoadingOverlayWithIcon(
      key: _loadingKey,
      iconAssetPath: 'assets/app_icon_128.png', // 앱 아이콘 경로
      enableScale: true,        // 크기 변화 애니메이션
      enableFade: true,         // 투명도 변화
      enableRotation: false,    // 회전 비활성화
      minScale: 0.98,          // 최소 크기 (미묘한 변화)
      maxScale: 1.02,          // 최대 크기
      showProgressIndicator: false, // 하단 로딩바 숨김
      child: Scaffold(
        appBar: AppBar(title: Text('내 페이지')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              _loadingKey.currentState?.show(); // 로딩 시작
              
              await _performAsyncOperation(); // 비동기 작업
              
              _loadingKey.currentState?.hide(); // 로딩 종료
            },
            child: Text('작업 시작'),
          ),
        ),
      ),
    );
  }
  
  Future<void> _performAsyncOperation() async {
    // API 호출, 파일 저장 등의 작업
    await Future.delayed(Duration(seconds: 3));
  }
}
```

### 2. 기본 LoadingOverlay
**간단한 Context 확장 사용**

```dart
LoadingOverlay(
  child: Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () {
          context.showLoading(); // 로딩 표시
          
          Future.delayed(Duration(seconds: 3), () {
            context.hideLoading(); // 로딩 숨김
          });
        },
        child: Text('3초 로딩'),
      ),
    ),
  ),
)
```

### 3. Simple LoadingOverlay
**Boolean 상태 기반**

```dart
class SimpleExample extends StatefulWidget {
  @override
  State<SimpleExample> createState() => _SimpleExampleState();
}

class _SimpleExampleState extends State<SimpleExample> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SimpleLoadingOverlay(
      isLoading: _isLoading,
      message: '데이터를 처리하는 중...',
      theme: LoadingOverlayTheme.dark,
      child: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              await Future.delayed(Duration(seconds: 3));
              setState(() => _isLoading = false);
            },
            child: Text('처리 시작'),
          ),
        ),
      ),
    );
  }
}
```

## 🎨 애니메이션 & 테마

### 애니메이션 타입
```dart
enum LoadingAnimationType {
  fade,      // 페이드 인/아웃
  scale,     // 크기 변화
  slideUp,   // 위로 슬라이드
  slideDown, // 아래로 슬라이드
  rotate,    // 회전
}
```

### 테마
```dart
enum LoadingOverlayTheme {
  dark,        // 어두운 배경
  light,       // 밝은 배경
  transparent, // 투명 배경
  blur,        // 블러 효과
}
```

## 🎯 실제 사용 사례

### vote_detail_page.dart에서의 활용
```dart
class VoteDetailPage extends StatefulWidget {
  @override
  State<VoteDetailPage> createState() => _VoteDetailPageState();
}

class _VoteDetailPageState extends State<VoteDetailPage> {
  final GlobalKey<LoadingOverlayWithIconState> _loadingKey = 
      GlobalKey<LoadingOverlayWithIconState>();

  @override
  Widget build(BuildContext context) {
    return LoadingOverlayWithIcon(
      key: _loadingKey,
      iconAssetPath: 'assets/app_icon_128.png',
      enableScale: true,
      enableFade: true,
      enableRotation: false,
      minScale: 0.98,
      maxScale: 1.02,
      showProgressIndicator: false,
      child: Scaffold(
        // ... 나머지 UI
      ),
    );
  }

  Future<void> _saveImageToGallery() async {
    _loadingKey.currentState?.show();
    
    try {
      // 이미지 저장 로직
      await ImageService.saveToGallery(imageUrl);
      
      // 성공 메시지
      showSuccessToast('이미지가 저장되었습니다');
    } catch (e) {
      // 에러 처리
      showErrorToast('저장에 실패했습니다');
    } finally {
      _loadingKey.currentState?.hide();
    }
  }
}
```

## 🔧 고급 기능

### Riverpod 상태 관리
```dart
class AdvancedExample extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdvancedLoadingOverlay(
      animationType: LoadingAnimationType.scale,
      theme: LoadingOverlayTheme.blur,
      child: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              ref.showLoadingWithRiverpod(
                message: '고급 로딩 중...',
                animationType: LoadingAnimationType.scale,
                theme: LoadingOverlayTheme.blur,
              );
              
              Future.delayed(Duration(seconds: 3), () {
                ref.hideLoadingWithRiverpod();
              });
            },
            child: Text('고급 로딩'),
          ),
        ),
      ),
    );
  }
}
```

### 글로벌 매니저
```dart
final manager = LoadingOverlayManager.instance;

// 키별 로딩 관리
manager.showWithKey(
  key: 'upload',
  message: '파일 업로드 중...',
  theme: LoadingOverlayTheme.dark,
);

manager.showWithKey(
  key: 'download', 
  message: '파일 다운로드 중...',
  theme: LoadingOverlayTheme.light,
);

// 개별 종료
manager.hideWithKey('upload');

// 전체 종료
manager.hideAll();
```

## 🚀 성능 최적화

```dart
LoadingOverlayWithIcon(
  enablePerformanceOptimization: true,  // 성능 최적화 활성화
  showPerformanceDebugInfo: true,       // 개발 시 FPS 표시
  child: MyWidget(),
)
```

**최적화 기능:**
- ✅ RepaintBoundary 자동 적용
- ✅ 지연 초기화로 메모리 절약  
- ✅ 단일 AnimatedBuilder 사용
- ✅ GPU 가속 활용
- ✅ 실시간 FPS 모니터링

## 📖 완전한 예제

더 많은 예제와 데모는 [`example/loading_overlay_example.dart`](example/loading_overlay_example.dart)를 참조하세요.

**6가지 예제 화면:**
1. 기본 LoadingOverlay
2. Simple LoadingOverlay  
3. Advanced LoadingOverlay
4. 글로벌 매니저
5. **앱 아이콘 애니메이션** ⭐
6. 성능 최적화 데모

## 🎯 언제 사용하나요?

- 📁 **파일 업로드/다운로드**
- 🌐 **API 요청 처리**  
- 🔄 **데이터 동기화**
- 🖼️ **이미지 저장/공유**
- ⚡ **복잡한 계산 작업**
- 📱 **앱 전환 효과**

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
