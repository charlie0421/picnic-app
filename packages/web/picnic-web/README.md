# 피크닉 웹 (Picnic Web)

피크닉 웹은 Next.js를 기반으로 한 웹 애플리케이션입니다. 플러터 앱과 유사한 기능을 제공합니다.

## 주요 기능

- **포탈 시스템**: 투표, 커뮤니티, PIC, 소설 등 다양한 포털 제공
- **인증 시스템**: 회원가입, 로그인, 프로필 관리 기능
- **투표 기능**: 투표 생성, 참여, 조회 기능
- **Supabase 연동**: 데이터베이스 및 인증 시스템 연동
- **반응형 웹 디자인**: 모바일과 데스크톱 모두 지원
- **구글 애드센스**: 배너 광고 표시

## 구조

### 주요 페이지

- **메인 페이지**: 포탈 메뉴 및 최근 콘텐츠 표시
- **투표 페이지**: 투표 목록 및 상세 보기
- **커뮤니티 페이지**: 게시글 목록 및 상세 보기
- **마이페이지**: 사용자 정보 및 활동 내역

### 컴포넌트

- **Portal**: 플러터 앱의 Portal과 유사한 구조로 메인 레이아웃 제공
- **PortalMenuItem**: 다양한 포탈로 이동할 수 있는 메뉴 아이템
- **TopMenu**: 각 포탈 타입에 맞는 상단 메뉴 제공
- **ProfileImageContainer**: 사용자 프로필 이미지 표시
- **BannerAd**: 애드센스 광고 표시

### 상태 관리

- **AuthContext**: 사용자 인증 상태 관리
- **NavigationContext**: 현재 화면 및 포탈 타입 관리

## 시작하기

### 필수 조건

- Node.js 14.0.0 이상
- npm 또는 yarn
- Supabase CLI (타입 생성에 필요)

### 설치

1. 저장소를 클론합니다.

```bash
git clone <repository-url>
cd picnic-web
```

2. 필요한 패키지를 설치합니다.

```bash
npm install
# 또는
yarn install
```

3. `.env.local.example` 파일을 복사하여 `.env.local` 파일을 생성하고 환경 변수를 설정합니다.

```bash
cp .env.local.example .env.local
```

4. 개발 서버를 실행합니다.

```bash
npm run dev
# 또는
yarn dev
```

## Supabase 타입 생성 가이드

Supabase 타입 생성을 위해 Supabase CLI를 사용하는 방법입니다.

### 1. Supabase CLI 설치

Supabase CLI는 전역 모듈로 설치하는 것이 지원되지 않으므로, 아래의 방법 중 하나를 사용하세요:

**MacOS / Linux**
```bash
brew install supabase/tap/supabase
```

**Windows**
```bash
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**Docker 사용 (참고)**
```bash
# Docker를 통한 실행은 아래와 같이 합니다
# 최신 이미지 확인: https://hub.docker.com/r/supabase/cli
docker run --rm -it -v $(pwd):/workdir --entrypoint supabase ghcr.io/supabase/cli:latest <command>
```

**프로젝트 내 설치 (권장)**
```bash
# package.json에 devDependency로 이미 추가되어 있음
npm install --save-dev supabase
# 또는 
yarn add --dev supabase

# npx를 통해 사용 (npm 설치 시)
npx supabase <command>
# 또는 (yarn 설치 시)
yarn supabase <command>
```

### 2. Supabase CLI 로그인 (반드시 필요)

로그인이 필요합니다. Supabase 계정의 액세스 토큰이 필요합니다.

```bash
# npx 사용하여 로그인
npx supabase login

# 또는 환경 변수로 설정 (CI/CD 환경에서 유용)
export SUPABASE_ACCESS_TOKEN=your_access_token
```

액세스 토큰은 Supabase 웹 대시보드에서 얻을 수 있습니다:
1. [https://supabase.com/dashboard](https://supabase.com/dashboard)에 로그인
2. 오른쪽 상단의 프로필 아이콘 클릭
3. "Account" 선택
4. "Access Tokens" 탭으로 이동
5. "Generate New Token" 버튼 클릭
6. 토큰 이름 입력 후 생성
7. 생성된 토큰을 복사하여 로그인 명령어에 사용

### 3. 프로젝트 연결

```bash
npx supabase link --project-ref <프로젝트-레퍼런스>
```

프로젝트 레퍼런스는 Supabase 대시보드의 Settings > API > Project ID에서 확인할 수 있습니다.
우리 프로젝트의 경우 `xtijtefcycoeqludlngc`입니다.

### 4. 타입 생성

```bash
# 기본 타입 생성 (package.json의 스크립트 사용)
# 주의: 먼저 로그인이 필요합니다!
npm run gen:types

# 또는 직접 명령어 실행
npx supabase gen types typescript --project-id xtijtefcycoeqludlngc > types/supabase.ts

# 사용자 정의 스키마 포함
npx supabase gen types typescript --project-id xtijtefcycoeqludlngc --schema public,auth > types/supabase.ts

# 액세스 토큰을 환경 변수로 설정한 경우
SUPABASE_ACCESS_TOKEN=your_access_token npx supabase gen types typescript --project-id xtijtefcycoeqludlngc > types/supabase.ts
```

### 5. 타입 사용

```typescript
// Supabase 클라이언트 생성 시 타입 추가
import { createClient } from '@supabase/supabase-js'
import { Database } from '../types/supabase'

const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey)
```

## 배포

```bash
npm run build
npm run start
# 또는
yarn build
yarn start
```

## 플러터 앱과의 차이점

웹 버전은 다음과 같은 차이점이 있습니다:

1. **UI/UX**: 웹 환경에 맞게 UI를 최적화하였습니다.
2. **리워드 광고**: 웹 버전에서는 리워드 광고가 제외되었습니다.
3. **성능**: 일부 네이티브 기능에 대한 제한이 있을 수 있습니다.

## 기술 스택

- [Next.js](https://nextjs.org/)
- [React](https://reactjs.org/)
- [TypeScript](https://www.typescriptlang.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Supabase](https://supabase.io/)
- [Google AdSense](https://www.google.com/adsense/) 