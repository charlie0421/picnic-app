// 앱 초기화 성능 측정 시작
performance.mark('app-init');

// Sentry SDK를 위한 설정
import * as Sentry from '@sentry/nextjs';

// Sentry 네비게이션 추적을 위한 함수 추가
export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;

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
      
      // 마크가 존재하는지 확인 후 측정
      try {
        const entries = performance.getEntriesByName('page-transition-start', 'mark');
        if (entries.length > 0) {
          performance.measure('page-transition', 'page-transition-start', 'page-transition-end');
          
          // 페이지 로드 시간 측정 및 콘솔 출력 (실제로는 분석 서비스로 전송)
          const pageLoadTime = performance.getEntriesByName('page-transition')[0]?.duration;
          if (pageLoadTime) {
            console.log(`Page load time: ${pageLoadTime}ms`);
            // 여기에 분석 서비스로 데이터 전송 코드 추가
          }
        } else {
          console.log('페이지 전환 시작 마크가 없습니다. 첫 페이지 로드인 것 같습니다.');
          // 첫 페이지 로드의 경우 navigation 타이밍을 대신 사용할 수 있습니다
          const navTiming = performance.getEntriesByType('navigation')[0];
          if (navTiming) {
            console.log(`Page load time (navigation): ${navTiming.duration}ms`);
          }
        }
      } catch (error) {
        console.error('Performance measurement error:', error);
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