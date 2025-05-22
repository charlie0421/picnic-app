# Apple 웹 인증 설정 가이드

## 목차
- [Apple Developer 계정 설정](#apple-developer-계정-설정)
- [서비스 ID 생성](#서비스-id-생성)
- [키 생성](#키-생성)
- [Supabase 설정](#supabase-설정)
- [문제 해결](#문제-해결)

## Apple Developer 계정 설정

1. [Apple Developer 웹사이트](https://developer.apple.com)에 로그인
2. Certificates, Identifiers & Profiles 메뉴로 이동
3. 계정이 Apple Developer Program에 등록되어 있는지 확인
   - 등록되어 있지 않은 경우, Apple Developer Program에 가입 필요

## 서비스 ID 생성

### 1. 프로덕션 환경용 서비스 ID
1. Identifiers 섹션에서 "+" 버튼 클릭
2. Services IDs 선택 후 Continue
3. 서비스 ID 정보 입력:
   - Description: "Sign in with Apple for Picnic (Production)"
   - Identifier: "io.iconcasting.picnic.app.dev" (또는 적절한 식별자)
4. Sign In with Apple 기능 활성화
5. Configure 버튼 클릭
6. 웹 인증 설정:
   - Primary App ID: 선택 (없으면 새로 생성)
   - Domains and Subdomains: `www.picnic.fan`
   - Return URLs: `https://www.picnic.fan/auth/callback`
7. Save 클릭

### 2. 개발 환경용 서비스 ID
1. Identifiers 섹션에서 "+" 버튼 클릭
2. Services IDs 선택 후 Continue
3. 서비스 ID 정보 입력:
   - Description: "Sign in with Apple for Picnic (Development)"
   - Identifier: "io.iconcasting.picnic.app.dev" (또는 적절한 식별자)
4. Sign In with Apple 기능 활성화
5. Configure 버튼 클릭
6. 웹 인증 설정:
   - Primary App ID: 선택 (없으면 새로 생성)
   - Domains and Subdomains:
     - `localhost:3000`
     - `*.ngrok-free.app` (ngrok 사용 시)
   - Return URLs:
     - `http://localhost:3000/auth/callback`
     - `https://*.ngrok-free.app/auth/callback`
7. Save 클릭

> **참고**: 
> - 개발 환경용 서비스 ID는 `*.ngrok-free.app` 와일드카드를 사용하여 모든 ngrok 서브도메인을 허용합니다.
> - 프로덕션 환경용 서비스 ID는 정확한 도메인만 허용합니다.

## 키 생성

1. Keys 섹션에서 "+" 버튼 클릭
2. 키 정보 입력:
   - Key Name: "Sign in with Apple Key"
   - Key Services: "Sign In with Apple" 선택
3. Configure 버튼 클릭
4. Primary App ID 선택
5. Save 클릭
6. 생성된 키 다운로드 (`.p8` 파일)
7. Key ID와 Team ID 복사

## Supabase 설정

### 1. 프로덕션 환경 설정
1. Supabase 대시보드 접속
2. Authentication > Providers 메뉴로 이동
3. Apple 제공자 활성화
4. 다음 정보 입력:
   - Client ID: 프로덕션 서비스 ID
   - Team ID: Apple Developer 계정의 팀 ID
   - Key ID: 생성한 키의 ID
   - Private Key: 다운로드한 `.p8` 파일의 내용
   - Redirect URL: `https://www.picnic.fan/auth/callback`

### 2. 개발 환경 설정
1. Supabase 대시보드 접속
2. Authentication > Providers 메뉴로 이동
3. Apple 제공자 활성화
4. 다음 정보 입력:
   - Client ID: 개발 서비스 ID
   - Team ID: Apple Developer 계정의 팀 ID
   - Key ID: 생성한 키의 ID
   - Private Key: 다운로드한 `.p8` 파일의 내용
   - Redirect URL: 
     - `http://localhost:3000/auth/callback`
     - `https://*.ngrok-free.app/auth/callback`

## 문제 해결

### 일반적인 오류
1. `Invalid client_id`
   - 서비스 ID가 올바르게 생성되었는지 확인
   - 서비스 ID가 Sign In with Apple 기능이 활성화되어 있는지 확인
   - 개발/프로덕션 환경에 맞는 서비스 ID를 사용 중인지 확인

2. `Invalid redirect_uri`
   - Supabase와 Apple Developer Console의 리디렉션 URL이 일치하는지 확인
   - 도메인이 올바르게 등록되어 있는지 확인
   - 개발 환경에서는 ngrok URL이 `*.ngrok-free.app` 패턴과 일치하는지 확인

3. `Invalid key`
   - 키가 올바르게 생성되었는지 확인
   - `.p8` 파일의 내용이 올바르게 복사되었는지 확인

### 디버깅
1. Apple Developer Console에서 로그 확인
2. Supabase Authentication > Logs에서 인증 이벤트 확인
3. 브라우저 개발자 도구의 Network 탭에서 요청/응답 확인

## 보안 고려사항

1. `.p8` 파일은 절대 공개 저장소에 커밋하지 않기
2. 키는 최소 권한 원칙에 따라 생성
3. 정기적으로 키 순환
4. 프로덕션 환경에서는 HTTPS 사용 필수
5. 개발 환경용 서비스 ID는 프로덕션 환경에서 사용하지 않기

## 추가 리소스

- [Apple Sign In with Apple 웹 설정 가이드](https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_js/configuring_your_webpage_for_sign_in_with_apple)
- [Apple Developer 인증 가이드](https://developer.apple.com/documentation/authenticationservices)
- [Supabase Apple 인증 문서](https://supabase.com/docs/guides/auth/social-login/auth-apple) 