/**
 * 개발 및 디버깅용 유틸리티 함수
 */

// 타입 확장 선언
declare global {
  interface XMLHttpRequest {
    _requestMethod?: string;
    _requestUrl?: string;
    _requestTime?: number;
  }
}

// 글로벌 네트워크 요청 모니터링 설정
export function setupNetworkMonitoring() {
  if (typeof window === 'undefined') return;

  // 원본 fetch 함수 저장
  const originalFetch = window.fetch;

  // fetch 모니터링
  window.fetch = async (...args) => {
    const [resource, config] = args;
    
    // 요청 URL
    let url: string;
    if (typeof resource === 'string') {
      url = resource;
    } else if (resource instanceof URL) {
      url = resource.toString();
    } else if (resource instanceof Request) {
      url = resource.url;
    } else {
      url = String(resource);
    }
    
    console.log(`[네트워크 요청] ${config?.method || 'GET'} ${url}`, {
      headers: config?.headers,
      body: config?.body
    });
    
    try {
      const response = await originalFetch(...args);
      
      // 응답 복제 (응답은 한번만 사용 가능)
      const clonedResponse = response.clone();
      
      // 응답 로그
      const status = clonedResponse.status;
      let body = null;
      
      try {
        // 응답 본문 읽기 시도 (JSON 형식인 경우)
        body = await clonedResponse.json();
      } catch (e) {
        // JSON이 아닌 경우 무시
      }
      
      console.log(`[네트워크 응답] ${status} ${url}`, {
        status,
        ok: clonedResponse.ok,
        body: body ? '있음' : '없음',
      });
      
      return response;
    } catch (error) {
      console.error(`[네트워크 오류] ${url}`, error);
      throw error;
    }
  };
  
  console.log('네트워크 모니터링이 활성화되었습니다.');
}

// XMLHttpRequest 모니터링 설정
export function setupXHRMonitoring() {
  if (typeof window === 'undefined') return;
  
  const originalOpen = XMLHttpRequest.prototype.open;
  const originalSend = XMLHttpRequest.prototype.send;
  
  // XMLHttpRequest.open 오버라이드
  XMLHttpRequest.prototype.open = function(method, url, ...rest) {
    this._requestMethod = method;
    this._requestUrl = typeof url === 'string' ? url : url.toString();
    this._requestTime = Date.now();
    return originalOpen.call(this, method, url, ...(rest.length ? rest : [true]));
  };
  
  // XMLHttpRequest.send 오버라이드
  XMLHttpRequest.prototype.send = function(body) {
    const reqMethod = this._requestMethod || 'GET';
    const reqUrl = this._requestUrl || 'unknown';
    
    console.log(`[XHR 요청] ${reqMethod} ${reqUrl}`, {
      body: body || '없음'
    });
    
    // 응답 이벤트 리스너 추가
    this.addEventListener('load', function() {
      const duration = Date.now() - (this._requestTime || 0);
      console.log(`[XHR 응답] ${this.status} ${this._requestUrl || 'unknown'} (${duration}ms)`, {
        status: this.status,
        response: this.response ? '있음' : '없음'
      });
    });
    
    this.addEventListener('error', function(e) {
      console.error(`[XHR 오류] ${this._requestUrl || 'unknown'}`, e);
    });
    
    return originalSend.apply(this, arguments);
  };
  
  console.log('XHR 모니터링이 활성화되었습니다.');
}

// 모든 네트워크 디버깅 설정 활성화
export function enableDebugging() {
  setupNetworkMonitoring();
  setupXHRMonitoring();
  
  // 글로벌 오류 핸들러 추가
  if (typeof window !== 'undefined') {
    window.addEventListener('error', (event) => {
      console.error('[글로벌 오류]', event.error);
    });
    
    window.addEventListener('unhandledrejection', (event) => {
      console.error('[처리되지 않은 Promise 오류]', event.reason);
    });
    
    console.log('글로벌 오류 모니터링이 활성화되었습니다.');
  }
}

// 환경 정보 로그
export function logEnvironmentInfo() {
  if (typeof window === 'undefined') return;
  
  console.log('환경 정보:', {
    userAgent: window.navigator.userAgent,
    url: window.location.href,
    hostname: window.location.hostname,
    protocol: window.location.protocol,
    mode: process.env.NODE_ENV,
    isNgrok: window.location.hostname.includes('ngrok'),
  });
} 