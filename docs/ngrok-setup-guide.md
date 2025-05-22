# ngrok을 사용한 로컬 개발 환경 설정 가이드

## 목차
- [ngrok 설치](#ngrok-설치)
- [ngrok 계정 설정](#ngrok-계정-설정)
- [로컬 개발 환경 설정](#로컬-개발-환경-설정)
- [보안 고려사항](#보안-고려사항)
- [문제 해결](#문제-해결)

## 관련 문서
- [인증 가이드](./authentication.md) - 전체 인증 시스템 설정
- [인증 테스트 가이드](./auth-testing-guide.md) - 테스트 방법

## 1. ngrok 설치

### macOS
```bash
brew install ngrok
```

### Windows
1. [ngrok 다운로드 페이지](https://ngrok.com/download)에서 설치 파일 다운로드
2. 다운로드한 파일 실행하여 설치

### Linux
```bash
sudo snap install ngrok
```

## 2. ngrok 계정 설정

1. [ngrok 웹사이트](https://ngrok.com)에서 회원가입
2. 대시보드에서 Authtoken 확인
3. 로컬에서 ngrok 인증
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

## 3. 로컬 개발 환경 설정

### 3.1 개발 서버 실행
```bash
npm run dev
```

### 3.2 ngrok 터널 생성
```bash
ngrok http 3000
```

실행 후 다음과 같은 정보가 표시됩니다:
```
Session Status                online
Account                       Your Account
Version                       3.x.x
Region                       United States (us)
Latency                      21ms
Web Interface                http://127.0.0.1:4040
Forwarding                   https://xxxx-xxx-xxx-xxx-xxx.ngrok-free.app -> http://localhost:3000
```

> **참고**: 
> - 최신 버전의 ngrok은 `ngrok-free.app` 도메인을 사용합니다.
> - 무료 계정의 경우 세션 시간이 제한되어 있습니다.
> - 프로덕션 환경(`www.picnic.fan`)에서는 ngrok을 사용하지 않습니다.

### 3.3 Supabase 설정

1. Supabase 대시보드 접속
2. Authentication > URL Configuration 메뉴로 이동
3. Site URL 설정:
   - 개발 환경 (ngrok): `https://xxxx-xxx-xxx-xxx-xxx.ngrok-free.app`
   - 프로덕션: `https://www.picnic.fan`
4. Redirect URLs 설정:
   - 개발 환경 (ngrok): `https://xxxx-xxx-xxx-xxx-xxx.ngrok-free.app/auth/callback`
   - 프로덕션: `https://www.picnic.fan/auth/callback`

## 4. 소셜 로그인 제공자 설정

각 소셜 로그인 제공자의 개발 환경 설정에 ngrok URL을 추가합니다:

### 4.1 Google OAuth
- 승인된 리디렉션 URI: `https://xxxx-xxx-xxx-xxx-xxx.ngrok-free.app/auth/callback`

### 4.2 Kakao
- 사이트 도메인: `xxxx-xxx-xxx-xxx-xxx.ngrok-free.app`
- 리디렉션 URI: `https://xxxx-xxx-xxx-xxx-xxx.ngrok-free.app/auth/callback`

### 4.3 WeChat
- 도메인: `xxxx-xxx-xxx-xxx-xxx.ngrok-free.app`
- 리디렉션 URI: `https://xxxx-xxx-xxx-xxx-xxx.ngrok-free.app/auth/callback`

## 5. 주의사항

1. ngrok URL은 세션마다 변경됩니다. 개발 중에는 URL이 변경되지 않도록 주의
2. 무료 계정의 경우 세션 시간이 제한되어 있음
3. 프로덕션 환경(`www.picnic.fan`)에서는 절대 ngrok URL을 사용하지 않기
4. ngrok은 개발 목적으로만 사용

## 6. 문제 해결

### 6.1 일반적인 오류
- `Invalid redirect URL`: ngrok URL이 올바르게 설정되었는지 확인
- `Connection refused`: 로컬 개발 서버가 실행 중인지 확인
- `Tunnel session failed`: ngrok 인증이 올바른지 확인

### 6.2 디버깅
1. ngrok 웹 인터페이스 (http://127.0.0.1:4040)에서 요청/응답 확인
2. 브라우저 개발자 도구의 Network 탭에서 요청 확인
3. 로컬 서버 로그 확인

## 7. 보안 고려사항

1. ngrok URL은 공개적으로 접근 가능하므로 민감한 정보 노출 주의
2. 개발 중에만 ngrok 사용
3. 테스트용 계정만 사용
4. 세션 종료 후 ngrok 터널 닫기

## 8. 추가 리소스

- [ngrok 공식 문서](https://ngrok.com/docs)
- [Supabase Auth 문서](https://supabase.com/docs/guides/auth)
- [Google OAuth 설정 가이드](https://developers.google.com/identity/protocols/oauth2)
- [Kakao 로그인 설정 가이드](https://developers.kakao.com/docs/latest/ko/kakaologin/common)
- [WeChat 로그인 설정 가이드](https://open.wechat.com/cgi-bin/newreadtemplate?t=overseas_open/docs/web/login/guide)

## 인증 연동
ngrok을 사용한 인증 설정에 대한 자세한 내용은 [인증 가이드](./authentication.md)를 참조하세요. 