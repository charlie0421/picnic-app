/**
 * 서버 컴포넌트 데이터 페칭 성능 측정 유틸리티
 * 
 * 이 파일은 서버 컴포넌트 데이터 페칭 성능을 측정하기 위한 유틸리티 함수를 제공합니다.
 * 개발 환경에서만 사용되며, 프로덕션 환경에서는 자동으로 비활성화됩니다.
 */

// 개발 환경에서만 활성화
const isDev = process.env.NODE_ENV === 'development';

/**
 * 성능 측정 래퍼 함수
 * 
 * 데이터 페칭 함수를 감싸서 실행 시간을 측정합니다.
 * 개발 환경에서만 로그를 출력하며, 프로덕션 환경에서는 원래 함수만 실행합니다.
 * 
 * @param name 측정할 작업의 이름
 * @param fn 측정할 함수
 * @returns 원래 함수의 반환값
 */
export async function measurePerformance<T>(
  name: string,
  fn: () => Promise<T>
): Promise<T> {
  if (!isDev) {
    return fn();
  }

  const startTime = performance.now();
  try {
    const result = await fn();
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    console.log(`[Performance] ${name}: ${duration.toFixed(2)}ms`);
    
    return result;
  } catch (error) {
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    console.error(`[Performance] ${name} (Error): ${duration.toFixed(2)}ms`);
    throw error;
  }
}

/**
 * 캐시 적중률 측정 함수
 * 
 * 데이터 페칭 함수의 캐시 적중률을 측정합니다.
 * 측정 결과는 개발 도구 콘솔에 출력됩니다.
 */
class CacheMetrics {
  private static instance: CacheMetrics;
  private metrics: Record<string, { hits: number; misses: number }> = {};

  private constructor() {}

  public static getInstance(): CacheMetrics {
    if (!CacheMetrics.instance) {
      CacheMetrics.instance = new CacheMetrics();
    }
    return CacheMetrics.instance;
  }

  public recordHit(key: string): void {
    if (!isDev) return;
    
    if (!this.metrics[key]) {
      this.metrics[key] = { hits: 0, misses: 0 };
    }
    this.metrics[key].hits += 1;
  }

  public recordMiss(key: string): void {
    if (!isDev) return;
    
    if (!this.metrics[key]) {
      this.metrics[key] = { hits: 0, misses: 0 };
    }
    this.metrics[key].misses += 1;
  }

  public getHitRatio(key: string): number {
    if (!this.metrics[key]) return 0;
    
    const { hits, misses } = this.metrics[key];
    const total = hits + misses;
    return total ? hits / total : 0;
  }

  public getAllMetrics(): Record<string, { hits: number; misses: number; ratio: number }> {
    const result: Record<string, { hits: number; misses: number; ratio: number }> = {};
    
    for (const [key, { hits, misses }] of Object.entries(this.metrics)) {
      const total = hits + misses;
      result[key] = {
        hits,
        misses,
        ratio: total ? hits / total : 0
      };
    }
    
    return result;
  }

  public printMetrics(): void {
    if (!isDev) return;
    
    console.group('[Cache Metrics]');
    
    for (const [key, { hits, misses, ratio }] of Object.entries(this.getAllMetrics())) {
      console.log(
        `${key}: ${(ratio * 100).toFixed(2)}% hit ratio (${hits} hits, ${misses} misses)`
      );
    }
    
    console.groupEnd();
  }

  public clearMetrics(): void {
    this.metrics = {};
  }
}

export const cacheMetrics = CacheMetrics.getInstance();

/**
 * 렌더링 워터폴 감지 함수
 * 
 * 중첩된 데이터 페칭이 순차적으로 발생하는 워터폴 패턴을 감지합니다.
 * 개발 환경에서만 작동하며, 워터폴이 감지되면 콘솔에 경고를 출력합니다.
 */
class WaterfallDetector {
  private static instance: WaterfallDetector;
  private activeRequests: Map<string, { startTime: number; parent: string | null }> = new Map();
  private waterfalls: Array<{ parent: string; child: string; delay: number }> = [];

  private constructor() {}

  public static getInstance(): WaterfallDetector {
    if (!WaterfallDetector.instance) {
      WaterfallDetector.instance = new WaterfallDetector();
    }
    return WaterfallDetector.instance;
  }

  public startRequest(id: string, parent: string | null = null): void {
    if (!isDev) return;
    
    this.activeRequests.set(id, {
      startTime: performance.now(),
      parent
    });
  }

  public endRequest(id: string): void {
    if (!isDev) return;
    
    const request = this.activeRequests.get(id);
    if (!request) return;
    
    this.activeRequests.delete(id);
    
    // 워터폴 패턴 감지
    if (request.parent) {
      const parentRequest = this.activeRequests.get(request.parent);
      if (parentRequest) {
        const delay = request.startTime - parentRequest.startTime;
        if (delay > 10) { // 10ms 이상 지연되면 워터폴로 간주
          this.waterfalls.push({
            parent: request.parent,
            child: id,
            delay
          });
        }
      }
    }
  }

  public getWaterfalls(): Array<{ parent: string; child: string; delay: number }> {
    return [...this.waterfalls];
  }

  public printWaterfalls(): void {
    if (!isDev || this.waterfalls.length === 0) return;
    
    console.group('[Waterfall Warnings]');
    
    for (const { parent, child, delay } of this.waterfalls) {
      console.warn(
        `Potential waterfall detected: ${parent} -> ${child} (${delay.toFixed(2)}ms delay)`
      );
    }
    
    console.groupEnd();
  }

  public clearWaterfalls(): void {
    this.waterfalls = [];
  }
}

export const waterfallDetector = WaterfallDetector.getInstance();

/**
 * 과도한 데이터 페칭 감지 함수
 * 
 * 동일한 데이터를 반복적으로 페칭하는 패턴을 감지합니다.
 * 개발 환경에서만 작동하며, 과도한 페칭이 감지되면 콘솔에 경고를 출력합니다.
 */
class OverFetchingDetector {
  private static instance: OverFetchingDetector;
  private fetchCounts: Record<string, number> = {};
  private thresholds: Record<string, number> = {};

  private constructor() {}

  public static getInstance(): OverFetchingDetector {
    if (!OverFetchingDetector.instance) {
      OverFetchingDetector.instance = new OverFetchingDetector();
    }
    return OverFetchingDetector.instance;
  }

  public recordFetch(key: string): void {
    if (!isDev) return;
    
    this.fetchCounts[key] = (this.fetchCounts[key] || 0) + 1;
  }

  public setThreshold(key: string, threshold: number): void {
    this.thresholds[key] = threshold;
  }

  public getOverFetchedKeys(): Array<{ key: string; count: number; threshold: number }> {
    const result: Array<{ key: string; count: number; threshold: number }> = [];
    
    for (const [key, count] of Object.entries(this.fetchCounts)) {
      const threshold = this.thresholds[key] || 3; // 기본 임계값
      if (count > threshold) {
        result.push({ key, count, threshold });
      }
    }
    
    return result;
  }

  public printWarnings(): void {
    if (!isDev) return;
    
    const overFetched = this.getOverFetchedKeys();
    if (overFetched.length === 0) return;
    
    console.group('[Over-fetching Warnings]');
    
    for (const { key, count, threshold } of overFetched) {
      console.warn(
        `Potential over-fetching detected: ${key} (${count} fetches, threshold: ${threshold})`
      );
    }
    
    console.groupEnd();
  }

  public clearCounts(): void {
    this.fetchCounts = {};
  }
}

export const overFetchingDetector = OverFetchingDetector.getInstance();

/**
 * 종합 성능 리포트 생성 함수
 * 
 * 캐시 적중률, 워터폴, 과도한 페칭 등 모든 성능 지표를 종합한 리포트를 생성합니다.
 * 개발 환경에서만 작동하며, 콘솔에 출력됩니다.
 */
export function generatePerformanceReport(): void {
  if (!isDev) return;
  
  console.group('[Server Component Performance Report]');
  
  // 캐시 지표 출력
  cacheMetrics.printMetrics();
  
  // 워터폴 경고 출력
  waterfallDetector.printWaterfalls();
  
  // 과도한 페칭 경고 출력
  overFetchingDetector.printWarnings();
  
  console.groupEnd();
}

/**
 * 성능 지표 초기화 함수
 * 
 * 모든 성능 지표를 초기화합니다.
 */
export function clearPerformanceMetrics(): void {
  cacheMetrics.clearMetrics();
  waterfallDetector.clearWaterfalls();
  overFetchingDetector.clearCounts();
}

// Next.js 앱 라우터에서 사용할 수 있는 미들웨어 함수
export function withPerformanceTracking<T>(
  component: () => Promise<T>,
  options: {
    name: string;
    parent?: string;
    cacheKey?: string;
  }
): () => Promise<T> {
  if (!isDev) {
    return component;
  }
  
  return async () => {
    const { name, parent, cacheKey } = options;
    
    if (parent) {
      waterfallDetector.startRequest(name, parent);
    }
    
    if (cacheKey) {
      overFetchingDetector.recordFetch(cacheKey);
    }
    
    try {
      const result = await measurePerformance(name, component);
      return result;
    } finally {
      if (parent) {
        waterfallDetector.endRequest(name);
      }
    }
  };
} 