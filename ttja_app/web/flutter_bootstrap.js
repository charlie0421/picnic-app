// 이 파일은 더 이상 사용되지 않습니다. index.html에서 직접 초기화 코드가 실행됩니다.

// flutter_bootstrap.js 안전 구현 버전
(function() {
  console.log('flutter_bootstrap.js 안전 버전 실행');
  
  // _flutter 객체가 없으면 만들기
  if (!window._flutter) {
    console.log('_flutter 객체 생성');
    window._flutter = {
      loader: {},
      buildConfig: {
        engineRevision: "f73bfc4522dd0bc87bbcdb4bb3088082755c5e87",
        builds: [
          {
            compileTarget: "dart2js",
            renderer: "canvaskit",
            mainJsPath: "main.dart.js"
          }
        ]
      }
    };
  }
  
  // 로더 메서드 구현 또는 재정의
  var safeMethods = {
    load: function(options) {
      console.log('bootstrap: load 메서드 호출됨');
      
      // main.dart.js 직접 로드
      var scriptExists = document.querySelector('script[src="main.dart.js"]');
      if (!scriptExists) {
        var script = document.createElement('script');
        script.src = 'main.dart.js';
        document.body.appendChild(script);
      }
      
      return Promise.resolve();
    }
  };
  
  // 메서드 적용
  window._flutter.loader = window._flutter.loader || {};
  window._flutter.loader.load = window._flutter.loader.load || safeMethods.load;
  
  // 즉시 main.dart.js 로드
  var scriptExists = document.querySelector('script[src="main.dart.js"]');
  if (!scriptExists) {
    console.log('bootstrap: main.dart.js 직접 로드');
    var script = document.createElement('script');
    script.src = 'main.dart.js';
    document.body.appendChild(script);
  } else {
    console.log('bootstrap: main.dart.js가 이미 로드됨');
  }
})();
