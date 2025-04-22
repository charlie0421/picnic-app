# 인증 테스트 가이드

## 목차
- [테스트 환경 설정](#테스트-환경-설정)
- [소셜 로그인 테스트](#소셜-로그인-테스트)
- [일반 로그인 테스트](#일반-로그인-테스트)
- [로그아웃 테스트](#로그아웃-테스트)
- [문제 해결](#문제-해결)

## 관련 문서
- [인증 가이드](./authentication.md) - 전체 인증 시스템 설정
- [ngrok 설정 가이드](./ngrok-setup-guide.md) - 개발 환경 설정

## 1. 테스트 환경 설정

### 1.1 Supabase 프로젝트 설정
1. [Supabase 대시보드](https://app.supabase.com)에 접속
2. 프로젝트 선택 또는 새 프로젝트 생성
3. Authentication > URL Configuration 메뉴로 이동
   - Site URL: `http://localhost:3000` (개발), `https://www.picnic.fan` (프로덕션)
   - Redirect URLs: 
     - `http://localhost:3000/auth/callback` (개발)
     - `https://www.picnic.fan/auth/callback` (프로덕션)

### 1.2 로컬 환경 변수 설정
`.env.local` 파일에 다음 환경 변수 추가:
```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 2. 소셜 로그인 테스트

### 2.1 Google 로그인 테스트
1. Google Cloud Console에서 테스트 사용자 추가
2. 로그인 페이지에서 Google 로그인 버튼 클릭
3. 테스트 계정으로 로그인
4. 콜백 처리 확인
5. 세션 유지 확인

### 2.2 Kakao 로그인 테스트
1. Kakao Developers에서 테스트 계정 설정
2. 로그인 페이지에서 Kakao 로그인 버튼 클릭
3. 테스트 계정으로 로그인
4. 콜백 처리 확인
5. 세션 유지 확인

### 2.3 WeChat 로그인 테스트
1. WeChat Open Platform에서 테스트 계정 설정
2. 로그인 페이지에서 WeChat 로그인 버튼 클릭
3. 테스트 계정으로 로그인
4. 콜백 처리 확인
5. 세션 유지 확인

## 3. 일반 로그인 테스트

### 3.1 이메일/비밀번호 로그인
1. 회원가입 테스트
2. 로그인 테스트
3. 비밀번호 재설정 테스트
4. 이메일 인증 테스트

### 3.2 세션 관리 테스트
1. 세션 유지 시간 확인
2. 자동 로그아웃 테스트
3. 다중 기기 로그인 테스트

## 4. 로그아웃 테스트

1. 로그아웃 버튼 클릭
2. 세션 삭제 확인
3. 리디렉션 확인
4. 재로그인 가능 확인

## 5. 문제 해결

### 5.1 일반적인 오류
- `Invalid redirect URL`: 리디렉션 URI 설정 확인
- `Invalid credentials`: 클라이언트 ID와 Secret 확인
- `Network error`: 서버 연결 상태 확인

### 5.2 디버깅
1. 브라우저 개발자 도구
   - Console 탭에서 오류 메시지 확인
   - Network 탭에서 요청/응답 확인
   - Application 탭에서 세션 스토리지 확인

2. Supabase 로그
   - Authentication > Logs에서 인증 이벤트 확인
   - 에러 메시지 분석

3. 서버 로그
   - 로컬 서버 로그 확인
   - 에러 스택 트레이스 분석

## 6. 보안 테스트

1. CSRF 공격 방어 테스트
2. XSS 공격 방어 테스트
3. 세션 하이재킹 방어 테스트
4. 비밀번호 복잡도 검증 테스트

## 7. 성능 테스트

1. 동시 로그인 테스트
2. 응답 시간 측정
3. 리소스 사용량 모니터링
4. 세션 관리 효율성 확인 