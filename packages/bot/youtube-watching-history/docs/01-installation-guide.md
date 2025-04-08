# 1. 설치 및 환경 설정 가이드

## 목차
1. [필수 요구사항](#필수-요구사항)
2. [개발 환경 설정](#개발-환경-설정)
3. [프로젝트 초기화](#프로젝트-초기화)
4. [환경 변수 설정](#환경-변수-설정)
5. [데이터베이스 설정](#데이터베이스-설정)
6. [테스트 환경 설정](#테스트-환경-설정)

## 필수 요구사항

### 시스템 요구사항
- Node.js 18.x 이상
- npm 9.x 이상
- Docker 24.x 이상
- AWS CLI 2.x 이상
- Git 2.x 이상

### AWS 계정 설정
1. AWS 계정 생성
2. IAM 사용자 생성 및 권한 설정
   - AdministratorAccess 권한 부여
   - 액세스 키 생성
3. AWS CLI 설정
   ```bash
   aws configure
   ```

### Google Cloud 설정
1. Google Cloud Console 접속
2. 새 프로젝트 생성
3. YouTube Data API v3 활성화
4. OAuth 2.0 클라이언트 ID 생성
   - 애플리케이션 유형: 웹 애플리케이션
   - 승인된 리디렉션 URI: http://localhost:3000/auth/callback

## 개발 환경 설정

### 1. Node.js 설치
```bash
# nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Node.js 18 설치
nvm install 18
nvm use 18
```

### 2. 프로젝트 디렉토리 생성
```bash
mkdir youtube-watching-history
cd youtube-watching-history
```

### 3. TypeScript 설정
```bash
# TypeScript 설치
npm install -g typescript

# tsconfig.json 생성
tsc --init
```

### 4. ESLint 및 Prettier 설정
```bash
# ESLint 설치
npm install --save-dev eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin

# Prettier 설치
npm install --save-dev prettier eslint-config-prettier eslint-plugin-prettier
```

### 5. Git 설정
```bash
# Git 초기화
git init

# .gitignore 생성
echo "node_modules/
.env
dist/
*.log
" > .gitignore
```

## 프로젝트 초기화

### 1. package.json 생성
```bash
npm init -y
```

### 2. 필수 패키지 설치
```bash
# 핵심 의존성
npm install dotenv google-auth-library googleapis puppeteer @supabase/supabase-js

# 개발 의존성
npm install --save-dev typescript @types/node @types/puppeteer ts-node nodemon
```

### 3. 프로젝트 구조 생성
```bash
mkdir -p src/services src/utils src/types src/config
mkdir -p tests/unit tests/integration
```

## 환경 변수 설정

### 1. .env 파일 생성
```bash
touch .env
```

### 2. 환경 변수 설정
```env
# YouTube API 설정
YOUTUBE_CLIENT_ID=your_client_id
YOUTUBE_CLIENT_SECRET=your_client_secret
YOUTUBE_REDIRECT_URI=http://localhost:3000/auth/callback

# Supabase 설정
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key

# AWS 설정
AWS_REGION=ap-northeast-2
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# OpenAI 설정
OPENAI_API_KEY=your_openai_api_key
```

## 데이터베이스 설정

### 1. Supabase 프로젝트 생성
1. Supabase 대시보드 접속
2. 새 프로젝트 생성
3. 프로젝트 URL과 API 키 확인

### 2. 데이터베이스 스키마 생성
```sql
-- accounts 테이블
CREATE TABLE accounts (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  in_use BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- youtube_tokens 테이블
CREATE TABLE youtube_tokens (
  id SERIAL PRIMARY KEY,
  account_id INTEGER REFERENCES accounts(id),
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- watch_logs 테이블
CREATE TABLE watch_logs (
  id SERIAL PRIMARY KEY,
  account_id INTEGER REFERENCES accounts(id),
  video_id VARCHAR(255) NOT NULL,
  watch_duration INTEGER NOT NULL,
  watch_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

## 테스트 환경 설정

### 1. Jest 설치
```bash
npm install --save-dev jest @types/jest ts-jest
```

### 2. Jest 설정 파일 생성
```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.ts'],
  setupFiles: ['dotenv/config'],
};
```

### 3. 테스트 스크립트 추가
```json
// package.json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

### 4. 테스트 환경 변수 설정
```bash
cp .env .env.test
```

## 다음 단계
- [YouTube API 구현 가이드](../docs/02-youtube-api-guide.md)로 이동 