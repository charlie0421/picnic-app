#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 앱 디렉토리 경로
const appDir = path.join(__dirname, '..', 'app');

// 리소스 목록 (app 폴더의 서브 디렉터리 중 CRUD 구조를 가진 것들)
const getResources = () => {
  try {
    return fs
      .readdirSync(appDir, { withFileTypes: true })
      .filter(
        (dirent) =>
          dirent.isDirectory() &&
          !['api', 'login', 'forgot-password'].includes(dirent.name) &&
          fs.existsSync(path.join(appDir, dirent.name, 'page.tsx')),
      )
      .map((dirent) => dirent.name);
  } catch (error) {
    console.error('Error reading resources:', error);
    return [];
  }
};

// 파일이 존재하는지 확인
const fileExists = (filePath) => {
  try {
    return fs.existsSync(filePath);
  } catch (error) {
    return false;
  }
};

// 표준화할 파일 목록 수집
const collectFiles = (resources) => {
  const files = [];

  resources.forEach((resource) => {
    // 리스트 페이지
    const listPage = path.join(appDir, resource, 'page.tsx');
    if (fileExists(listPage)) {
      files.push({ path: listPage, type: 'list', resource });
    }

    // 생성 페이지
    const createPage = path.join(appDir, resource, 'create', 'page.tsx');
    if (fileExists(createPage)) {
      files.push({ path: createPage, type: 'create', resource });
    }

    // 수정 페이지
    const editPage = path.join(appDir, resource, 'edit', '[id]', 'page.tsx');
    if (fileExists(editPage)) {
      files.push({ path: editPage, type: 'edit', resource });
    }

    // 상세 페이지
    const showPage = path.join(appDir, resource, 'show', '[id]', 'page.tsx');
    if (fileExists(showPage)) {
      files.push({ path: showPage, type: 'show', resource });
    }
  });

  return files;
};

// 리소스 표준화 가이드 메시지 출력
const printStandardizationGuide = (files) => {
  console.log('\n=== 리소스 컴포넌트 표준화 가이드 ===\n');
  console.log('다음 리소스 파일들을 표준화해야 합니다:\n');

  // 리소스별로 그룹화
  const resourceGroups = files.reduce((acc, file) => {
    if (!acc[file.resource]) {
      acc[file.resource] = [];
    }
    acc[file.resource].push(file);
    return acc;
  }, {});

  Object.entries(resourceGroups).forEach(([resource, files], index) => {
    console.log(`${index + 1}. ${resource} 리소스`);
    files.forEach((file) => {
      const relativePath = path.relative(process.cwd(), file.path);
      console.log(`   - ${file.type}: ${relativePath}`);

      // Cursor AI 명령어 출력
      console.log(`\n다음 명령어로 Cursor AI에 요청하세요:
"${relativePath} 파일을 다음 기준으로 리팩토링해주세요:

1. import 섹션:
   - AuthorizePage import 추가
   - useResource 훅 import 추가
   - UI 컴포넌트들을 @/components/ui에서 import
   - 불필요한 import 제거

2. 컴포넌트 선언부:
   - 페이지 컴포넌트를 AuthorizePage로 감싸기
   - useResource 훅 사용하여 title 설정
   예시:
   const ${file.type}Page = () => {
     const { resource } = useResource({ title: "${resource}" });
     return (
       <AuthorizePage>
         {/* 컴포넌트 내용 */}
       </AuthorizePage>
     );
   };

3. 리소스 훅 사용:
   - ${
     file.type === 'list'
       ? 'useTable'
       : file.type === 'create'
       ? 'useForm'
       : file.type === 'edit'
       ? 'useForm'
       : 'useShow'
   }에 resource 이름 명시
   예시: ${
     file.type === 'list'
       ? 'useTable({ resource: "' + resource + '" })'
       : file.type === 'create'
       ? 'useForm({ resource: "' + resource + '" })'
       : file.type === 'edit'
       ? 'useForm({ resource: "' + resource + '" })'
       : 'useShow({ resource: "' + resource + '" })'
   }

4. 문자열 표기법:
   - 모든 문자열을 큰따옴표로 통일
   - 작은따옴표를 큰따옴표로 변경

5. 코드 스타일:
   - 불필요한 공백과 주석 제거
   - 일관된 들여쓰기 적용
   - 컴포넌트 이름을 PascalCase로 통일"
      `);
    });
    console.log('\n');
  });

  console.log('\n주의사항:');
  console.log('1. 각 파일 수정 후 ./scripts/check-standardization.js로 검증');
  console.log('2. 한 리소스의 모든 파일이 완료되면 다음 리소스로 진행');
  console.log('3. 변경사항 커밋 후 테스트 진행');
};

// 메인 함수
const main = () => {
  console.log('리소스 컴포넌트 표준화 스크립트 실행 중...');

  const resources = getResources();
  console.log(`발견된 리소스: ${resources.join(', ')}`);

  const files = collectFiles(resources);
  console.log(`표준화할 파일 수: ${files.length}개`);

  printStandardizationGuide(files);
};

// 실행
main();
