// 이 파일은 사용되지 않습니다.
console.log('경고: 이 flutter.js 파일은 사용되지 않습니다. 메인 HTML에서 직접 main.dart.js를 로드합니다.');

// 오류 방지용 flutter.js 완전 대체 버전
(function() {
  console.log('커스텀 flutter.js 로드됨 - 오류 해결 버전');
  
  // 전역 변수 정의
  window._flutter = window._flutter || {};
  
  // 자주 호출되는 load 및 loadEntrypoint 메서드
  var safeLoader = {
    // find 메서드를 사용하는 부분에서 오류가 발생하는 load 메서드 안전하게 구현
    load: function(options) {
      console.log('안전한 flutter.js load 메서드 호출됨');
      
      // main.dart.js 로드 여부 확인 및 로드
      var mainDartScript = document.querySelector('script[src="main.dart.js"]');
      if (!mainDartScript) {
        console.log('main.dart.js 로드 시작');
        var script = document.createElement('script');
        script.src = 'main.dart.js';
        document.body.appendChild(script);
      } else {
        console.log('main.dart.js가 이미 로드됨');
      }
      
      return Promise.resolve();
    },
    
    // 이전 버전의 API 호환성 유지
    loadEntrypoint: function(options) {
      console.log('안전한 flutter.js loadEntrypoint 메서드 호출됨');
      
      // main.dart.js 로드 여부 확인 및 로드
      var mainDartScript = document.querySelector('script[src="main.dart.js"]');
      if (!mainDartScript) {
        var script = document.createElement('script');
        script.src = 'main.dart.js';
        
        if (options && typeof options.onEntrypointLoaded === 'function') {
          script.onload = function() {
            var fakeInitializer = {
              initializeEngine: function(config) {
                return {
                  then: function(callback) {
                    var fakeAppRunner = {
                      runApp: function() {
                        return Promise.resolve();
                      }
                    };
                    callback(fakeAppRunner);
                    return Promise.resolve(fakeAppRunner);
                  }
                };
              }
            };
            
            try {
              options.onEntrypointLoaded(fakeInitializer);
            } catch (e) {
              console.error('onEntrypointLoaded 콜백 실행 중 오류:', e);
            }
          };
        }
        
        document.body.appendChild(script);
      } else {
        console.log('main.dart.js가 이미 로드됨');
        
        // 이미 로드된 경우에도 콜백 실행
        if (options && typeof options.onEntrypointLoaded === 'function') {
          setTimeout(function() {
            var fakeInitializer = {
              initializeEngine: function(config) {
                return {
                  then: function(callback) {
                    var fakeAppRunner = {
                      runApp: function() {
                        return Promise.resolve();
                      }
                    };
                    callback(fakeAppRunner);
                    return Promise.resolve(fakeAppRunner);
                  }
                };
              }
            };
            
            try {
              options.onEntrypointLoaded(fakeInitializer);
            } catch (e) {
              console.error('onEntrypointLoaded 콜백 실행 중 오류:', e);
            }
          }, 0);
        }
      }
      
      return Promise.resolve();
    }
  };
  
  // _flutter.loader 속성 설정
  window._flutter.loader = window._flutter.loader || {};
  
  // 안전한 구현체로 대체
  window._flutter.loader.load = safeLoader.load;
  window._flutter.loader.loadEntrypoint = safeLoader.loadEntrypoint;
  
  // buildConfig 설정 (find 메서드 오류 해결을 위한 핵심 부분)
  window._flutter.buildConfig = {
    engineRevision: "f73bfc4522dd0bc87bbcdb4bb3088082755c5e87",
    builds: [
      {
        compileTarget: "dart2js",
        renderer: "canvaskit",
        mainJsPath: "main.dart.js"
      },
      {
        compileTarget: "dart2js",
        renderer: "html",
        mainJsPath: "main.dart.js"
      }
    ]
  };
  
  // 기타 모든 가능한 메서드 안전하게 구현
  var safeMethods = {
    didCreateEngineInitializer: function() {},
    loadEntrypoint: safeLoader.loadEntrypoint,
    load: safeLoader.load
  };
  
  // _flutter 객체의 모든 속성을 안전하게 설정
  for (var key in safeMethods) {
    if (typeof window._flutter.loader[key] === 'undefined') {
      window._flutter.loader[key] = safeMethods[key];
    }
  }
  
  console.log('flutter.js 안전 대체 버전 초기화 완료');
})();
