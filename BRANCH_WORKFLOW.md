# 🌳 브랜치 관리 워크플로우 가이드

## 빠른 시작 명령어

### 새로운 기능 개발
```bash
git checkout main && git pull origin main
git checkout -b feature/기능명
# 개발 후 PR → main
```

### 패치 배포 (Shorebird)
```bash
git checkout production && git pull origin production
git checkout -b patch/패치명
# 수정 후 푸시 → 자동 배포
git push origin patch/패치명
```

### 긴급 수정 (Shorebird)
```bash
git checkout production && git pull origin production
git checkout -b hotfix/수정명
# 긴급 수정 후 푸시 → 즉시 배포
git push origin hotfix/수정명
```

### 프로덕션 릴리즈
```bash
git checkout production && git pull origin production
git merge main
git push origin production
# 또는 태그 생성
git tag picnic-v1.2.0 && git push origin picnic-v1.2.0
```

## 브랜치별 배포 방식

| 브랜치 패턴 | 배포 방식 | 소요 시간 | 용도 |
|-------------|-----------|-----------|------|
| `production` | 앱스토어 + Shorebird | 60-120분 | 새 버전 |
| `patch/*` | Shorebird만 | 30-60분 | 개선사항 |
| `hotfix/*` | Shorebird만 | 30-60분 | 긴급수정 |
| `picnic-patch-*` (태그) | Shorebird만 | 30-60분 | 패치 |

## 작업 흐름

1. **기능 개발**: feature → main → production
2. **패치**: production → patch/* → Shorebird
3. **긴급수정**: production → hotfix/* → Shorebird → main 반영

## 주의사항

- ⚠️ patch/hotfix는 반드시 **production**에서 분기
- ⚠️ 긴급수정 후 main에도 반영 필요
- ⚠️ Shorebird 패치는 Dart 코드만 가능 (네이티브 코드 변경 불가)
- ✅ 배포 전 충분한 테스트 필수 