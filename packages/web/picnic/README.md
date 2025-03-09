# Picnic Web

Picnic 웹 사이드바 애플리케이션입니다.

## 개발 모드 실행

```bash
npm run dev
```

## Vercel 배포 방법

이 프로젝트는 Vercel에 독립적인 프로젝트로 배포할 수 있습니다.

### Vercel CLI 배포

1. Vercel CLI 설치
```bash
npm i -g vercel
```

2. 로그인
```bash
vercel login
```

3. 배포
```bash
vercel
```

### Vercel 대시보드를 통한 배포

1. [Vercel 웹사이트](https://vercel.com)에 접속하여 로그인
2. 프로젝트 생성 및 GitHub 저장소 연결
3. 다음 설정을 지정:
   - 프레임워크 프리셋: Next.js
   - 루트 디렉토리: packages/web/picnic_web
   - 빌드 명령어: npm run build
   - 출력 디렉토리: .next

## 정적 내보내기 방식 (기존 방식)

필요시 정적 HTML로 내보내기 위해서는 다음 명령어를 실행합니다:

```bash
npm run export
```

이 경우 `out` 디렉토리에 정적 파일이 생성되고, Flutter 웹 앱으로 복사됩니다. 