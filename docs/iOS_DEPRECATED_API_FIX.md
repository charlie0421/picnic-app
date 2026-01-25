# iOS Deprecated API 수정 가이드

## 개요

iOS 15부터 `UIApplication.shared.windows` API가 deprecated 되었습니다. iOS 18에서는 이 deprecated API 사용 시 앱이 백그라운드로 전환될 때 stack overflow 크래시가 발생할 수 있습니다.

## 크래시 증상

```
Exception Type:  EXC_BAD_ACCESS (SIGSEGV)
Exception Subtype: KERN_PROTECTION_FAILURE
VM Region Info: STACK GUARD

Thread 0 Crashed:
_UIViewVisitorRecursivelyEntertainDescendingVisitors
_UITintColorVisitor::visitView
```

- iOS 18.x에서 주로 발생
- 앱이 백그라운드로 전환될 때 `tintColor` 전파 과정에서 스택 오버플로우

## 수정된 파일

### 1. PangleAdManager.swift

**수정 위치:** `showRewardedAd()` 메서드

**Before (deprecated):**
```swift
guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
    // ...
}
```

**After (iOS 15+ compatible):**
```swift
guard let windowScene = UIApplication.shared.connectedScenes
    .compactMap({ $0 as? UIWindowScene })
    .first(where: { $0.activationState == .foregroundActive }),
      let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
    // ...
}
```

### 2. PincruxOfferwallManager.swift

**수정 위치:** `startOfferwall`, `startPincruxOfferwallAdDetail`, `startPincruxOfferwallContact` 메서드

**Before (deprecated):**
```swift
let controller = UIApplication.shared.windows.first?.rootViewController
```

**After (iOS 15+ compatible):**
```swift
// 헬퍼 함수 추가
private func getRootViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }),
          let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
        return nil
    }
    return rootVC
}

// 사용
let controller = getRootViewController()
```

## UIWindowScene 방식 설명

```swift
UIApplication.shared.connectedScenes          // 모든 연결된 씬 가져오기
    .compactMap({ $0 as? UIWindowScene })     // UIWindowScene만 필터링
    .first(where: { $0.activationState == .foregroundActive })  // 활성화된 씬 선택
    ?.windows.first(where: { $0.isKeyWindow }) // 키 윈도우 가져오기
    ?.rootViewController                       // 루트 뷰컨트롤러 가져오기
```

## 향후 유의사항

1. 새로운 네이티브 Swift 코드 작성 시 `UIApplication.shared.windows` 사용 금지
2. 서드파티 SDK 업데이트 시 deprecated API 사용 여부 확인
3. iOS 15 미만 지원이 필요한 경우 버전 분기 처리 필요:

```swift
var rootViewController: UIViewController? {
    if #available(iOS 15.0, *) {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow })?.rootViewController
    } else {
        return UIApplication.shared.windows.first?.rootViewController
    }
}
```

## 관련 커밋

- `ae082804` - fix: replace deprecated UIApplication.shared.windows API for iOS 15+

## 참고 자료

- [Apple Documentation - UIApplication.shared.windows (Deprecated)](https://developer.apple.com/documentation/uikit/uiapplication/1623104-windows)
- [Apple Documentation - UIWindowScene](https://developer.apple.com/documentation/uikit/uiwindowscene)
