// Flutter 앱 로더 - 초기화 문제 해결
(function() {
  // Flutter.js가 이미 로드되었는지 확인
  if (window._flutter) {
    console.log('Flutter가 이미 초기화됨. 중복 초기화 방지.');
    return;
  }
  
  // 기본 Flutter 객체 생성
  window._flutter = {
    loader: {
      // 공식 load 함수를 재정의하여 오류 방지
      load: function(options) {
        console.log('Flutter 커스텀 로더 실행');
        
        // 메인 스크립트 로드 (기존에 로드되었을 수 있음)
        if (!window._flutterMainLoaded) {
          var mainScript = document.createElement('script');
          mainScript.src = "main.dart.js";
          mainScript.id = "flutter-main-script";
          
          document.body.appendChild(mainScript);
          window._flutterMainLoaded = true;
        }
        
        return Promise.resolve();
      },
      // 레거시 loadEntrypoint 함수도 지원
      loadEntrypoint: function(options) {
        console.log('Flutter 레거시 로더 실행');
        
        // 메인 스크립트 로드 (중복 방지)
        if (!window._flutterMainLoaded) {
          var mainScript = document.createElement('script');
          mainScript.src = "main.dart.js";
          mainScript.id = "flutter-main-script";
          
          if (options && options.onEntrypointLoaded) {
            var mockInitializer = {
              initializeEngine: function(config) {
                return Promise.resolve({
                  runApp: function() {
                    console.log('Flutter 앱 실행');
                    return Promise.resolve();
                  }
                });
              }
            };
            
            mainScript.onload = function() {
              options.onEntrypointLoaded(mockInitializer);
            };
          }
          
          document.body.appendChild(mainScript);
          window._flutterMainLoaded = true;
        }
        
        return Promise.resolve();
      }
    },
    // 필수 buildConfig 설정 (find 메서드 오류 해결)
    buildConfig: {
      engineRevision: "", // 빈 값으로 설정
      builds: [{
        compileTarget: "dart2js",
        renderer: "canvaskit",
        mainJsPath: "main.dart.js"
      }]
    }
  };
  
  console.log('Flutter 로더 초기화 완료');
})(); 