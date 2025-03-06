# Next.js 사이드바 컴포넌트

이 프로젝트는 Flutter 웹 앱의 좌우 사이드바를 Next.js로 구현한 것입니다. 이 사이드바는 iframe을 통해 Flutter 앱과 통합됩니다.

## 설치 및 실행 방법

1. 의존성 설치:
```bash
npm install
```

2. 개발 서버 실행:
```bash
npm run dev
```

3. 빌드 및 내보내기:
```bash
npm run export
```

## 프로젝트 구조

- `/components`: 사이드바 컴포넌트
  - `LeftSidebar.js`: 왼쪽 사이드바 컴포넌트
  - `RightSidebar.js`: 오른쪽 사이드바 컴포넌트
- `/pages`: Next.js 페이지
  - `index.js`: 메인 페이지
  - `left-sidebar.js`: 왼쪽 사이드바 페이지
  - `right-sidebar.js`: 오른쪽 사이드바 페이지
- `/styles`: 스타일시트
  - `globals.css`: 글로벌 스타일

## Flutter 앱과의 통합 방법

Flutter 웹 앱의 `index.html` 파일에 다음과 같이 iframe을 추가하여 사이드바를 통합합니다:

```html
<div class="layout-container">
  <!-- 좌측 사이드바 -->
  <div id="sidebar-left" class="sidebar-left">
    <iframe 
      src="http://localhost:3001/left-sidebar" 
      frameborder="0" 
      width="100%" 
      height="100%" 
      style="border: none;"
      title="Left Sidebar"
    ></iframe>
  </div>
  
  <!-- 중앙 Flutter 앱 컨테이너 -->
  <div class="flutter-container">
    <!-- Flutter 앱 내용 -->
  </div>
  
  <!-- 우측 사이드바 -->
  <div id="sidebar-right" class="sidebar-right">
    <iframe 
      src="http://localhost:3001/right-sidebar" 
      frameborder="0" 
      width="100%" 
      height="100%" 
      style="border: none;"
      title="Right Sidebar"
    ></iframe>
  </div>
</div>
```

## 통신 방법

iframe과 부모 창 간의 통신은 `postMessage` API를 사용합니다:

```javascript
// Next.js 컴포넌트에서 Flutter 앱으로 메시지 전송
window.parent.postMessage({
  type: 'MENU_SELECTED',
  menuId: id
}, '*');

// Flutter 앱에서 Next.js 컴포넌트로 메시지 전송
const iframe = document.querySelector('iframe');
iframe.contentWindow.postMessage({
  type: 'UPDATE_NOTIFICATIONS',
  notifications: [...]
}, '*');
``` 