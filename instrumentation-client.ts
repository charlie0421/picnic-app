// 앱 초기화 성능 측정 시작
performance.mark('app-init');

// 페이지 전환 추적을 위한 설정
const capturePageTransitions = () => {
  if (typeof window !== 'undefined') {
    // 페이지 전환 시작 시간 추적
    window.addEventListener('beforeunload', () => {
      performance.mark('page-transition-start');
    });

    // 페이지 로드 완료 시간 추적
    window.addEventListener('load', () => {
      performance.mark('page-transition-end');
      performance.measure('page-transition', 'page-transition-start', 'page-transition-end');
      
      // 페이지 로드 시간 측정 및 콘솔 출력 (실제로는 분석 서비스로 전송)
      const pageLoadTime = performance.getEntriesByName('page-transition')[0]?.duration;
      if (pageLoadTime) {
        console.log(`Page load time: ${pageLoadTime}ms`);
        // 여기에 분석 서비스로 데이터 전송 코드 추가
      }
    });
  }
};

// 오류 추적 설정
const setupErrorTracking = () => {
  if (typeof window !== 'undefined') {
    window.addEventListener('error', (event) => {
      // Sentry 또는 다른 오류 추적 서비스가 이미 설정되어 있을 수 있으므로
      // 필요한 경우 여기에 추가적인 오류 처리 로직 구현
      console.error('Client error captured:', event.error);
    });
  }
};

// 로깅 및 분석 설정
console.log('Client instrumentation initialized');

// 함수 실행
capturePageTransitions();
setupErrorTracking();

// 초기화 완료 표시
performance.mark('app-init-end');
performance.measure('app-initialization', 'app-init', 'app-init-end');

export {}; 