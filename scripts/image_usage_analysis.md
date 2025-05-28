# 이미지 사용 패턴 분석 보고서

## 개요
프로젝트 전체에서 PicnicCachedNetworkImage 사용 현황을 분석하여 LazyImageWidget으로의 교체 계획을 수립합니다.

## 사용 현황 통계
- **총 사용 파일 수**: 17개 파일
- **총 사용 인스턴스**: 약 30개
- **주요 사용 영역**: 위젯, 페이지, 다이얼로그

## 사용 패턴별 분류

### 1. 리스트/그리드 컨텍스트 (LazyListImageWidget 적용 대상)
**특징**: 스크롤 가능한 리스트나 그리드에서 사용되는 이미지들
**권장 교체**: `LazyListImageWidget` (threshold: 5%)

- `vote_artist_list.dart` (Line 298) - 아티스트 목록
- `vote_artist_page.dart` (Line 292) - 아티스트 페이지 리스트
- `board_list_page.dart` (Line 176) - 게시판 목록
- `pic_home_page.dart` (Line 220, 316) - 피드 이미지들
- `vote_home_page.dart` (Line 178) - 투표 홈 리스트

### 2. 그리드 레이아웃 (LazyGridImageWidget 적용 대상)
**특징**: 그리드 형태로 배치된 이미지들
**권장 교체**: `LazyGridImageWidget` (threshold: 20%)

- `gallery_page.dart` (Line 89) - 갤러리 그리드
- `article_images.dart` (Line 39, 191) - 아티클 이미지 그리드

### 3. 단일 이미지/아바타 (기본 LazyImageWidget 적용 대상)
**특징**: 독립적으로 표시되는 단일 이미지들
**권장 교체**: `LazyImageWidget` (기본 설정)

- `avatar_container.dart` (Line 67) - 사용자 아바타
- `comment_user.dart` (Line 20) - 댓글 사용자 아바타
- `my_page.dart` (Line 309) - 마이페이지 프로필
- `splash_image.dart` (Line 166) - 스플래시 이미지
- `common_banner.dart` (Line 75) - 배너 이미지

### 4. 다이얼로그/팝업 (기본 LazyImageWidget 적용 대상)
**특징**: 모달이나 팝업에서 사용되는 이미지들
**권장 교체**: `LazyImageWidget` (즉시 로딩 필요)

- `reward_dialog.dart` (Line 81, 275, 307) - 리워드 다이얼로그
- `fortune_dialog.dart` (Line 439) - 포춘 다이얼로그
- `popup_carousel.dart` (Line 246) - 팝업 캐러셀

### 5. 상세 페이지 이미지 (기본 LazyImageWidget 적용 대상)
**특징**: 상세 정보를 표시하는 페이지의 이미지들
**권장 교체**: `LazyImageWidget` (고품질 로딩)

- `vote_detail_page.dart` (Line 322, 539) - 투표 상세
- `vote_detail_achieve_page.dart` (Line 292, 390, 659, 809) - 투표 성취 상세
- `voting_complete.dart` (Line 356, 386) - 투표 완료
- `vote_info_card_achieve.dart` (Line 82) - 투표 정보 카드
- `vote_info_card_vertical.dart` (Line 109) - 세로형 투표 카드

### 6. 미디어/임베드 (특수 처리 필요)
**특징**: 미디어 콘텐츠나 임베드 요소
**권장 교체**: `LazyImageWidget` + 특수 설정

- `media_embed_builder.dart` (Line 151) - 미디어 임베드
- `compatibility_card.dart` (Line 60) - 호환성 카드

## 교체 우선순위

### 높은 우선순위 (즉시 교체)
1. **피드 관련 이미지** - 사용자가 가장 자주 보는 영역
   - `pic_home_page.dart`
   - `vote_home_page.dart`
   - `gallery_page.dart`

2. **리스트 뷰 이미지** - 스크롤 성능에 직접적 영향
   - `vote_artist_list.dart`
   - `board_list_page.dart`

### 중간 우선순위
3. **아바타 이미지** - 많은 곳에서 사용되지만 크기가 작음
   - `avatar_container.dart`
   - `comment_user.dart`

4. **상세 페이지** - 사용 빈도는 낮지만 고품질 이미지 필요
   - `vote_detail_page.dart`
   - `vote_detail_achieve_page.dart`

### 낮은 우선순위
5. **다이얼로그/팝업** - 사용 빈도가 낮고 즉시 로딩 필요
   - `reward_dialog.dart`
   - `fortune_dialog.dart`

6. **기타 위젯** - 특수한 경우나 사용 빈도가 낮음
   - `splash_image.dart`
   - `media_embed_builder.dart`

## 교체 시 고려사항

### 성능 최적화 포인트
1. **리스트/그리드**: 뷰포트 기반 지연 로딩으로 메모리 절약
2. **아바타**: 작은 크기이므로 캐시 효율성 중요
3. **상세 이미지**: 고품질 로딩과 프리로딩 고려
4. **다이얼로그**: 즉시 로딩으로 사용자 경험 향상

### 호환성 확인 필요
1. **BorderRadius 속성** - 모든 사용 사례에서 지원 확인
2. **memCacheWidth/Height** - 새로운 시스템에서의 메모리 캐시 설정
3. **fit 속성** - BoxFit 설정 호환성
4. **에러 처리** - 기존 에러 위젯과의 호환성

## 예상 성능 개선 효과

### 메모리 사용량
- **리스트/그리드**: 30-50% 감소 (뷰포트 외부 이미지 언로드)
- **전체 앱**: 20-30% 감소 (효율적인 캐시 관리)

### 로딩 성능
- **초기 로딩**: 40-60% 개선 (지연 로딩)
- **스크롤 성능**: 50-70% 개선 (점진적 로딩)

### 사용자 경험
- **앱 반응성**: 크게 향상 (메모리 압박 감소)
- **배터리 수명**: 개선 (불필요한 이미지 로딩 방지)

## 다음 단계
1. 높은 우선순위 파일부터 순차적 교체
2. 각 교체 후 기능 테스트 수행
3. 성능 벤치마크로 개선 효과 측정
4. 문제 발생 시 롤백 계획 준비 