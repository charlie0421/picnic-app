const nextJest = require('next/jest')

const createJestConfig = nextJest({
  // Next.js 앱의 경로를 제공하여 테스트 환경에서 next.config.js와 .env 파일을 로드합니다
  dir: './',
})

// Jest에 전달할 사용자 정의 설정
const customJestConfig = {
  setupFilesAfterEnv: [
    '<rootDir>/jest.setup.js',
    '<rootDir>/__tests__/setup.ts'
  ],
  testEnvironment: 'jest-environment-jsdom',
  moduleDirectories: ['node_modules', '<rootDir>/'],
  moduleNameMapper: {
    // 경로 별칭 핸들링
    '^@/(.*)$': '<rootDir>/$1',
  },
  collectCoverageFrom: [
    'app/**/*.{js,jsx,ts,tsx}',
    'components/**/*.{js,jsx,ts,tsx}',
    'lib/**/*.{js,jsx,ts,tsx}',
    'hooks/**/*.{js,jsx,ts,tsx}',
    'utils/**/*.{js,jsx,ts,tsx}',
    'contexts/**/*.{js,jsx,ts,tsx}',
    'stores/**/*.{js,jsx,ts,tsx}',
    '!**/*.d.ts',
    '!**/node_modules/**',
    '!**/.next/**',
    '!**/types/**',
    '!**/constants/**',
    '!**/__mocks__/**',
    '!**/__tests__/**',
    '!**/coverage/**',
  ],
  testPathIgnorePatterns: [
    '<rootDir>/node_modules/',
    '<rootDir>/.next/',
    '<rootDir>/__tests__/setup.ts',
    '<rootDir>/__tests__/utils/test-utils.tsx',
  ],
  // 병렬 실행 설정 (기본값은 OS 논리 CPU 수 - 1)
  maxWorkers: '50%',
  // 각 테스트 파일에 대해 최대 테스트 실행 시간 설정 (밀리초)
  testTimeout: 15000,
  // 최소 커버리지 기준 설정
  coverageThreshold: {
    global: {
      statements: 10, // 점진적으로 증가시킬 목표
      branches: 10,
      functions: 10,
      lines: 10,
    },
    // 중요 디렉터리/파일에 대한 더 높은 커버리지 요구 설정
    './utils/api/': {
      statements: 60,
      branches: 50,
      functions: 60,
      lines: 60,
    },
    './components/ui/': {
      statements: 40,
      branches: 30,
      functions: 40,
      lines: 40,
    },
  },
  // 커버리지 보고서 설정
  coverageReporters: ['json', 'lcov', 'text', 'clover', 'html'],
  // 캐시 설정
  cache: true,
  cacheDirectory: '<rootDir>/.jest-cache',
  // 테스트 파일 패턴 최적화
  testMatch: ['**/__tests__/**/*.(spec|test).[jt]s?(x)'],
  // 변경된 파일만 테스트하는 옵션 (CI에서는 false로 설정)
  watchPathIgnorePatterns: [
    '<rootDir>/node_modules/',
    '<rootDir>/.next/',
    '<rootDir>/coverage/',
  ],
}

// createJestConfig는 next/jest가 비동기 설정을 제공할 수 있도록 내보내기를 자동으로 처리합니다
module.exports = createJestConfig(customJestConfig) 