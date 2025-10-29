# YouTube 30초 시청 증빙 PoC 가이드 (1장 스크린샷)

## 사용자 캡처 가이드
- 영상 재생 중 화면을 한 번 탭해 컨트롤(경과/전체 시간, 진행바, 버튼)이 보이게 한 뒤 캡처 1장 촬영
- 30초 이상 경과가 보이도록 촬영(예: 0:30 이상)
- 가능하면 영상 끝 근접(진행바 90%+)에서 촬영하면 승인 확률 상승
- Shorts의 경우: 숫자 시간표시가 없으면 승인 어려울 수 있으므로 Long-form 영상 권장

## 앱 UX 플로우
1) 앱에서 미션 가이드 화면 진입 → “YouTube로 이동(더보기)” 클릭
2) 유튜브에서 30초 이상 시청 후 캡처 1장 촬영(컨트롤 표시 필수)
3) 앱으로 돌아와 “스크린샷 업로드” → 자동 검증 결과 확인(approve/review/reject)

## 승인 정책(간단)
- 승인(approve)
  - 숫자 시간표시가 존재하고, 경과시간 ≥ 30초
  - 경과/전체 비율과 진행바 추정치의 차이 ≤ 0.1
- 보류(review)
  - 시간표시 없음 또는 진행바/시간 불일치로 확신 부족
- 반려(reject)
  - 경과시간 < 30초 또는 조작/중복 의심

## 반부정(간단)
- 동일 이미지 중복 제출 방지: 이미지 SHA-256 지문 비교
- 의심 시 수동검수로 전환(보류)

## 엔드포인트 요약(Supabase Edge)
- POST /ads-create-click
  - body: { "campaignId": string, "userId"?: string }
  - res: { clickId, videoId, youtubeUrl }
- POST /ads-sign-url (upload)
  - body: { "path": "proofs/<file>", "type": "upload" }
  - res: { signedUrl }
- POST /ads-sign-url (download)
  - body: { "path": "proofs/<file>", "type": "download", "expiresIn"?: number }
  - res: { signedUrl }
- POST /ads-validate-proof
  - body: { "clickId": string, "proofUrl": string }
  - res: { decision: "approve|review|reject", metrics: { elapsed, duration, progressRatio } }

## 환경 변수(Functions)
- OPENAI_API_KEY: OpenAI Vision(gpt-4o-mini)
- SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY: 서버 삽입용
- 스토리지 버킷: picnic-prod-cdn 하위 `proofs/` 경로 사용(업로드 비공개 권장)

## 테스트 팁
- 정상: 0:37/3:12 캡처 → 승인
- 경계: 0:29 → 반려
- 불일치: elapsed 0:37인데 진행바 5% → 보류
- Shorts: 시간표시 없음 → 보류(정책상 Long-form 권장)


