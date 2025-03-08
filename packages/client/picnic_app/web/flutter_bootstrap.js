{{flutter_js}}
{{flutter_build_config}}

// 커스텀 초기화 로직
window.addEventListener('DOMContentLoaded', function() {
  console.log('Flutter 부트스트랩 초기화 시작...');
  
  // Flutter 앱 로드
  _flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
      try {
        console.log('Flutter 엔트리포인트 로드됨, 엔진 초기화 중...');
        
        // 엔진 초기화
        const appRunner = await engineInitializer.initializeEngine({
          hostElement: document.getElementById('flutter-app-container'),
          renderer: 'html',
          width: 393
        });
        
        console.log('Flutter 엔진 초기화 완료, 앱 실행 중...');
        await appRunner.runApp();
        
        // 초기화 완료 이벤트 발생
        console.log('Flutter 앱 실행 완료, 이벤트 발생');
        window.dispatchEvent(new Event('flutter-initialized'));
      } catch (error) {
        console.error('Flutter 엔진 초기화 또는 실행 오류:', error);
      }
    }
  });
}); 