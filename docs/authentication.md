# 인증 가이드

## 목차
- [소셜 로그인 설정](#소셜-로그인-설정)
- [환경 변수 설정](#환경-변수-설정)
- [로그인 플로우](#로그인-플로우)
- [보안 고려사항](#보안-고려사항)

## 관련 문서
- [ngrok 설정 가이드](./ngrok-setup-guide.md) - 개발 환경 설정
- [인증 테스트 가이드](./auth-testing-guide.md) - 테스트 방법
- [Apple 웹 인증 설정 가이드](./apple-web-auth-guide.md) - Apple 로그인 상세 설정

## 소셜 로그인 설정

### 1. Google 로그인
- Google Cloud Console에서 프로젝트 생성
- OAuth 2.0 클라이언트 ID 생성
- 승인된 리디렉션 URI 설정:
  - 개발 환경: `http://localhost:3000/auth/callback`
  - ngrok 사용 시: `https://[your-ngrok-subdomain].ngrok-free.app/auth/callback`
  - 프로덕션: `https://www.picnic.fan/auth/callback`

### 2. Apple 로그인
- Apple Developer 계정에서 서비스 ID 생성
- 웹 인증 설정 구성 (자세한 내용은 [Apple 웹 인증 설정 가이드](./apple-web-auth-guide.md) 참조)
- 도메인 및 리디렉션 URL 등록:
  - 개발 환경: `http://localhost:3000/auth/callback`
  - ngrok 사용 시: `https://[your-ngrok-subdomain].ngrok-free.app/auth/callback`
  - 프로덕션: `https://www.picnic.fan/auth/callback`

### 3. Kakao 로그인
- Kakao Developers에서 애플리케이션 등록
- 플랫폼 설정에서 웹 플랫폼 추가
- 사이트 도메인 등록:
  - 개발 환경: `http://localhost:3000`
  - ngrok 사용 시: `https://[your-ngrok-subdomain].ngrok-free.app`
  - 프로덕션: `https://www.picnic.fan`
- 리디렉션 URI 설정:
  - 개발 환경: `http://localhost:3000/auth/callback`
  - ngrok 사용 시: `https://[your-ngrok-subdomain].ngrok-free.app/auth/callback`
  - 프로덕션: `https://www.picnic.fan/auth/callback`

### 4. WeChat 로그인
- WeChat Open Platform에서 웹사이트 애플리케이션 등록
- 도메인 및 리디렉션 URL 설정:
  - 개발 환경: `http://localhost:3000/auth/callback`
  - ngrok 사용 시: `https://[your-ngrok-subdomain].ngrok-free.app/auth/callback`
  - 프로덕션: `https://www.picnic.fan/auth/callback`

## 환경 변수 설정

Supabase 프로젝트 설정을 위한 환경 변수를 `.env.local` 파일에 설정:

```env
# Supabase 설정
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 로그인 플로우

1. 사용자가 소셜 로그인 버튼 클릭
2. 해당 제공자의 OAuth 인증 페이지로 리디렉션
3. 사용자 인증 후 콜백 URL로 리디렉션
4. Supabase Auth에서 사용자 정보 처리
5. 로그인 완료 및 세션 생성

## 보안 고려사항

- 모든 환경 변수는 비밀로 관리
- HTTPS 사용 필수
- CSRF 보호 구현
- 세션 타임아웃 설정
- 로그인 시도 제한 구현
- 프로덕션 환경에서는 ngrok 사용 금지 