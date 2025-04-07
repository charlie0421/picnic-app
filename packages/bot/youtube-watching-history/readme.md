# 유튜브 계정 관리 & Fargate 실행 아키텍처 (EventBridge 기반)

## 1. 개요

### 목적
- 다수의 Gmail/YouTube 계정을 중앙에서 관리하며, 매 계정마다 "특정 시간에 유튜브 시청" 작업을 자동으로 실행
- 상시 인스턴스를 두지 않고, AWS Fargate에서 컨테이너를 짧게 실행 후 종료 → 비용 절감
- YouTube 시청 이력(원한다면 공식 YouTube API/OAuth)까지 관리자 대시보드(Refine)에서 확인
- 이중 실행 방지, Slack 알림, 로그 추적 등의 기능을 포함

### 핵심 포인트
1. 계정 정보, 예약 시간, 상태(in_use 등)는 Supabase DB에서 관리
2. 스케줄링은 AWS EventBridge(Schedule Rule)로 구현 (Supabase Cron은 사용하지 않음)
3. Fargate 태스크 기동 시 계정 식별자를 전달, 컨테이너 내부에서 Puppeteer 실행
4. 유튜브 자동화 로직은 Node.js + Puppeteer로 Docker 컨테이너에 탑재
5. 완료/에러 시 Slack 알림, 실행 로그를 DB나 CloudWatch Logs에 기록

---

## 2. 아키텍처 다이어그램

```ascii
┌─────────────────────────────┐
│         Admin UI            │
│ (Refine)                    │
│ - 계정 등록/편집            │
│ - 예약 시간 설정            │
│ - 실행 상태/로그 조회       │
└─────────────┬───────────────┘
              │ (HTTPS/REST)
              ▼
┌─────────────────────────────────────────┐
│        Supabase (PostgreSQL DB)       │
│ - accounts 테이블 (email, pw, in_use..)│
│ - watch_logs 테이블 (실행 결과 등)     │
└─────────────┬──────────────────────────┘
              │ (SQL/REST)
              ▼
┌─────────────────────────────────────────┐
│ AWS EventBridge (Schedule Rule)        │
│ - 매 분/매 시간/특정 cron에 따라       │
│   Lambda 혹은 RunTask 직접 호출       │
└─────────────┬──────────────────────────┘
              │ (run-task, or Lambda -> run-task)
              ▼
┌──────────────────────────────────────────────────┐
│ AWS ECS (Fargate)                               │
│ - Docker 컨테이너: Node.js + Puppeteer          │
│ - 실행 시: 계정 ID 받아 Supabase에서 pw 조회    │
│ - 유튜브 로그인/시청 후 watch_logs 기록         │
│ - 종료 시 Slack 알림 (또는 EventBridge 이벤트)  │
└──────────────────────────────────────────────────┘
```

### 주요 컴포넌트 설명
1. **Admin UI(Refine)**: 계정과 예약 정보를 편리하게 수정·조회
2. **Supabase**: 유튜브 계정, 예약 스케줄, 실행 로그 등 저장
3. **EventBridge**: 스케줄을 관리. 특정 시간마다(또는 매 분/매 시) 이벤트를 발생
4. **Fargate**: Puppeteer 컨테이너를 서버리스로 실행. 시청 로직 후 종료

---

## 3. 아키텍처 주요 흐름

1. 관리자가 Admin UI(Refine)에서 계정 정보(email, password)와 "예약 시간(start_time), 시청 지속 시간(duration)" 등을 입력 (Supabase DB에 저장)
2. EventBridge에 Schedule Rule을 생성 (예: 매 분/매 시각 등), 규칙이 트리거되면 Lambda를 호출 (또는 직접 RunTask)
3. Lambda(선택) 내 로직:
   - Supabase에서 "현재 시점에 실행해야 할 계정"을 조회 (예: scheduled_time <= now AND in_use=false)
   - 해당 계정에 대해 in_use=true로 업데이트(이중 실행 방지)
   - RunTask API로 Fargate 태스크 실행, ACCOUNT_ID를 오버라이드 env로 전달
4. Fargate 컨테이너(Docker: Node.js + Puppeteer) 시작
   - watch.js 실행 시:
     1. ACCOUNT_ID로 DB에서 email/password/keyword 등을 가져옴
     2. 유튜브 로그인 → 일정 시간 시청 → 완료
     3. Supabase에 watch_logs 업데이트, in_use=false로 계정 플래그 해제
     4. 종료 직전 Slack Webhook 호출(또는 EventBridge ECS Task State Change → Lambda → Slack)
5. Admin UI에서 실행 로그와 상태(in_use, 로그 메시지, 시청 이력)를 실시간 모니터링

---

## 4. 구현 단계별 실행 아이템

### 4.1 Supabase DB 스키마 구성
1. **accounts 테이블**
   - 예: id (PK), email, password, keyword, scheduled_time, duration, in_use (bool), updated_at 등
   - email/password는 민감정보이므로 암호화 또는 Secrets 저장 고려
2. **watch_logs 테이블**
   - 예: id (PK), account_id, start_time, end_time, status, error_message, etc.

### 4.2 Docker + Puppeteer 환경
1. **Node.js + Puppeteer 의존성**
   - npm install puppeteer
   - Linux 환경에서 apt-get install chromium (또는 Puppeteer 내장 Chromium)
2. **Dockerfile 작성**
   ```dockerfile
   FROM node:16
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   RUN npm run build  # (TS -> JS 컴파일)
   CMD ["node", "dist/watch.js"]
   ```
3. **코드(watch.js)**
   - process.env.ACCOUNT_ID를 통해 DB에서 계정 정보 조회
   - Puppeteer로 유튜브 로그인, 시청 로직, 완료 후 Supabase watch_logs 업데이트

### 4.3 ECR (Docker 이미지) 업로드
1. AWS ECR 리포지토리 생성
2. docker build -t my-yt-watcher .
3. docker push <ECR-URL>/my-yt-watcher:latest

### 4.4 ECS Fargate 설정
1. 클러스터 생성 (Network only)
2. Task Definition
   - Launch type: Fargate
   - CPU/Memory (예: 0.25 vCPU, 0.5GB)
   - 컨테이너: 이미지 <ECR-URL>/my-yt-watcher:latest
   - Log configuration(awslogs) → CloudWatch Logs 그룹
3. (선택) IAM Task Role → DB/S3/Secrets 등 접근 권한 설정

### 4.5 EventBridge 스케줄 + Lambda
1. **Lambda 함수(Node.js or Python)**
   - DB에서 "지금 실행해야 할 계정" 쿼리
   - 각 계정에 대해 "in_use 상태 업데이트 + RunTask" 호출
2. **EventBridge Rule**
   - cron 식(예: cron(0/1 * * * ? *) → 매 분마다)
   - Target = 위 Lambda
   - Lambda가 runTask 여러 번 호출 or 0번(조건 없으면 스킵)

### 4.6 Slack 알림
1. **ECS Task State Change 이벤트 → EventBridge → Lambda**
   - 상세: CloudWatch Events (EventBridge)에서 "ECS Task State Change" rule 생성
   - Task가 STOPPED 상태 → Lambda → Slack Webhook 호출
   - 메시지: "Task {taskArn} finished with status {stopCode}"
2. (대안) Puppeteer 내부에서 종료 시 Slack Webhook 호출

### 4.7 Admin UI(Refine) 통합
1. Refine에서 Supabase 연결 (REST, GraphQL, or Direct Postgres)
2. 테이블 목록
   - accounts(CRUD)
   - watch_logs(조회)
3. 예약 시간(scheduled_time), in_use, 시청 로그 등을 UI로 표시

### 4.8 YouTube 시청 이력 (API)
1. YouTube Data API로 개인 계정 시청 기록을 가져오려면 OAuth 2.0 인증 필요
2. 각 계정별로 OAuth 토큰 발급 → DB 저장
3. Refine UI에서 API 호출 or Puppeteer로 대체 스크래핑(공식적이지 않음)
4. 구현 난이도와 정책을 고려하여 선택

---

## 5. 최종 아키텍처 요약
1. Supabase DB: 계정/예약/로그 저장
2. AWS EventBridge: 스케줄 엔진 (cron)
3. AWS Lambda: 매 분/시간마다 DB 조회해 "실행할 계정"을 판단, RunTask 호출
4. Fargate: Puppeteer 컨테이너가 떠서 시청 → 종료 (DB에 로그 기록, Slack 알림)
5. Admin UI(Refine): 계정/예약 설정, 실행 현황, 로그 모니터링, (유튜브 API 연동 시) 시청 이력 확인

---

## 6. 다운로드/배포 가이드

이 문서는 Markdown 형식이므로, 다음 방법 중 하나로 다운로드할 수 있습니다:

1. **복사 & 붙여넣기**
   - 현재 문서 내용을 전부 복사하여, VSCode / Notion / Obsidian / Google Docs 등 원하는 에디터에 붙여 넣은 뒤, "PDF로 내보내기"
2. **Markdown 파일로 저장**
   - 새로운 .md 파일을 만든 뒤, 이 내용을 저장 → 마크다운 뷰어(예: Typora)에서 PDF나 HTML로 변환
3. **GitHub Gist**
   - 새 Gist를 만들고 이 내용을 넣으면 웹에서 Markdown으로도 볼 수 있고, "Download ZIP" 등으로 받을 수 있음

이 과정을 통해 PDF나 docx 형태로도 자유롭게 배포 가능합니다.

---

## 7. 추가 참고 사항

### 7.1 보안
- 이메일/비번 평문 → 가능하면 Secrets Manager 또는 암호화 저장
- Fargate 태스크 Role → 최소 권한 (DynamoDB/SecretsManager 접근 등)

### 7.2 확장성
- 계정이 수백, 수천 개로 늘어난다면 스케줄 호출 횟수 증가. EventBridge + Lambda 성능 주의
- 병렬 Fargate 태스크 실행 시 CPU/Memory/Network 부하

### 7.3 비용
- Fargate는 실행 시간 단위 과금, 짧게 실행 시 비용 효율↑
- EventBridge는 소량 호출은 거의 무료 수준
- Supabase는 플랜/사용량에 따라 비용 검토

### 7.4 YouTube 정책
- 부정 시청(조회수 조작) 가능성이 크다면 계정 차단, IP 차단 리스크
- 테스트/연구 목적이라면 문제 없지만, 실제 운영 시 주의