/**
 * 테스트 환경 설정 파일
 * 
 * 이 파일은 모든 테스트가 실행되기 전에 로드됩니다.
 */

// @ts-nocheck
import '@testing-library/jest-dom';

// 콘솔 경고 억제 - 필요한 경우에만 사용
const originalConsoleError = console.error;
const originalConsoleWarn = console.warn;

// 특정 경고나 에러를 필터링하는 함수
console.error = (...args) => {
  // React 18 관련 경고 필터링
  const suppressedMessages = [
    'Warning: ReactDOM.render is no longer supported',
    'Warning: useLayoutEffect does nothing on the server',
    // 다른 필터링할 메시지 추가
  ];
  
  if (!suppressedMessages.some(msg => args[0]?.includes(msg))) {
    originalConsoleError(...args);
  }
};

console.warn = (...args) => {
  // 특정 경고 필터링
  const suppressedMessages = [
    'Warning: React does not recognize the',
    'Warning: The tag <xxx> is unrecognized in this browser',
    // 다른 필터링할 메시지 추가
  ];
  
  if (!suppressedMessages.some(msg => args[0]?.includes(msg))) {
    originalConsoleWarn(...args);
  }
};

// 테스트 환경 설정 추가
beforeAll(() => {
  // Object.defineProperty를 사용하여 window.matchMedia 모킹
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: jest.fn().mockImplementation(query => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      dispatchEvent: jest.fn(),
    })),
  });

  // ResizeObserver 모킹
  global.ResizeObserver = jest.fn().mockImplementation(() => ({
    observe: jest.fn(),
    unobserve: jest.fn(),
    disconnect: jest.fn(),
  }));
  
  // IntersectionObserver 모킹
  global.IntersectionObserver = jest.fn().mockImplementation(() => ({
    observe: jest.fn(),
    unobserve: jest.fn(),
    disconnect: jest.fn(),
  }));
  
  // Fetch API 모킹 (필요한 경우)
  global.fetch = jest.fn();
});

// 각 테스트 후 모킹 상태 초기화
afterEach(() => {
  jest.clearAllMocks();
});

// 모든 테스트 후 정리
afterAll(() => {
  console.error = originalConsoleError;
  console.warn = originalConsoleWarn;
});

// 사용자 정의 matchers 추가
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    if (pass) {
      return {
        message: () => `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      };
    }
  },
}); 