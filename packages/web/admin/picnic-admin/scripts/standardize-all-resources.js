#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 앱 디렉토리 경로
const appDir = path.join(process.cwd(), 'app');

// 리소스 목록 (app 폴더의 서브 디렉터리 중 CRUD 구조를 가진 것들)
const getResources = () => {
  try {
    return fs
      .readdirSync(appDir, { withFileTypes: true })
      .filter(dirent => 
        dirent.isDirectory() && 
        !['api', 'login', 'forgot-password'].includes(dirent.name) &&
        fs.existsSync(path.join(appDir, dirent.name, 'page.tsx'))
      )
      .map(dirent => dirent.name);
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
  
  resources.forEach(resource => {
    // 리스트 페이지
    const listPage = path.join(appDir, resource, 'page.tsx');
    if (fileExists(listPage)) {
      files.push(listPage);
    }
    
    // 생성 페이지
    const createPage = path.join(appDir, resource, 'create', 'page.tsx');
    if (fileExists(createPage)) {
      files.push(createPage);
    }
    
    // 수정 페이지
    const editPage = path.join(appDir, resource, 'edit', '[id]', 'page.tsx');
    if (fileExists(editPage)) {
      files.push(editPage);
    }
    
    // 상세 페이지
    const showPage = path.join(appDir, resource, 'show', '[id]', 'page.tsx');
    if (fileExists(showPage)) {
      files.push(showPage);
    }
  });
  
  return files;
};

// 리소스 표준화 가이드 메시지 출력
const printStandardizationGuide = (files) => {
  console.log('\n=== 리소스 컴포넌트 표준화 가이드 ===\n');
  console.log('다음 리소스 파일에 표준 코드 스타일을 적용해야 합니다:\n');
  
  files.forEach((file, index) => {
    const relativePath = path.relative(process.cwd(), file);
    console.log(`${index + 1}. ${relativePath}`);
  });
  
  console.log('\n각 파일을 Cursor에서 열고 다음 프롬프트를 사용하세요:\n');
  console.log('```');
  console.log('이 파일을 표준 코드 스타일로 리팩토링해주세요:');
  console.log('1. AuthorizePage 컴포넌트로 감싸기');
  console.log('2. resource 이름 명시 (useTable, useForm, useShow 등에서)');
  console.log('3. useResource 훅 사용 및 title 적용');
  console.log('4. 불필요한 import 제거 및 import 정리');
  console.log('5. 가독성을 위한 적절한 공백 추가');
  console.log('6. 모든 문자열은 큰따옴표로 통일');
  console.log('7. UI 컴포넌트 import 방식 통일 (@/components/ui에서 가져오기)');
  console.log('```');
  
  console.log('\n표준화 체크리스트:');
  console.log('- [ ] 모든 페이지가 AuthorizePage로 감싸져 있는지 확인');
  console.log('- [ ] Resource 이름이 모든 관련 훅에 명시되어 있는지 확인');
  console.log('- [ ] useResource 훅을 사용하고 title 속성에 적용되어 있는지 확인');
  console.log('- [ ] 불필요한 import가 제거되었는지 확인');
  console.log('- [ ] 코드 포맷팅이 통일되었는지 확인');
  console.log('- [ ] UI 컴포넌트 import 방식이 통일되었는지 확인\n');
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