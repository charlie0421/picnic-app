#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// 앱 디렉토리 경로
const appDir = path.join(__dirname, '..', 'app');

// 리소스 목록 가져오기
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

// 파일 존재 여부 확인
const fileExists = (filePath) => {
  try {
    return fs.existsSync(filePath);
  } catch (error) {
    return false;
  }
};

// 파일 내용 검사
const checkFileContent = (filePath) => {
  try {
    const content = fs.readFileSync(filePath, 'utf8');

    const checks = {
      authorizePage: content.includes('AuthorizePage'),
      resourceName:
        /use(Table|Form|Show|List)\s*\(\s*{\s*resource:\s*["'][^"']+["']/.test(
          content,
        ),
      useResource:
        content.includes('useResource') &&
        /title:\s*["'][^"']+["']/.test(content),
      uiImports: content.includes('@/components/ui'),
      doubleQuotes: !content.includes("'"), // 작은따옴표가 없어야 함
    };

    return checks;
  } catch (error) {
    console.error(`Error checking file ${filePath}:`, error);
    return null;
  }
};

// 표준화 상태 출력
const printStandardizationStatus = (resourceChecks) => {
  console.log('\n=== 리소스 컴포넌트 표준화 상태 ===\n');

  Object.entries(resourceChecks).forEach(([resource, pages]) => {
    console.log(`\n📁 ${resource}`);

    Object.entries(pages).forEach(([page, checks]) => {
      if (!checks) {
        console.log(`  ❌ ${page}: 파일을 읽을 수 없음`);
        return;
      }

      console.log(`  📄 ${page}:`);
      console.log(
        `    ${checks.authorizePage ? '✅' : '❌'} AuthorizePage 사용`,
      );
      console.log(
        `    ${checks.resourceName ? '✅' : '❌'} Resource 이름 명시`,
      );
      console.log(
        `    ${checks.useResource ? '✅' : '❌'} useResource 및 title 사용`,
      );
      console.log(
        `    ${checks.uiImports ? '✅' : '❌'} UI 컴포넌트 import 방식`,
      );
      console.log(`    ${checks.doubleQuotes ? '✅' : '❌'} 큰따옴표 사용`);
    });
  });
};

// 메인 함수
const main = () => {
  console.log('리소스 컴포넌트 표준화 검사 중...');

  const resources = getResources();
  console.log(`발견된 리소스: ${resources.join(', ')}`);

  const resourceChecks = {};

  resources.forEach((resource) => {
    resourceChecks[resource] = {};

    // 리스트 페이지
    const listPage = path.join(appDir, resource, 'page.tsx');
    if (fileExists(listPage)) {
      resourceChecks[resource]['list'] = checkFileContent(listPage);
    }

    // 생성 페이지
    const createPage = path.join(appDir, resource, 'create', 'page.tsx');
    if (fileExists(createPage)) {
      resourceChecks[resource]['create'] = checkFileContent(createPage);
    }

    // 수정 페이지
    const editPage = path.join(appDir, resource, 'edit', '[id]', 'page.tsx');
    if (fileExists(editPage)) {
      resourceChecks[resource]['edit'] = checkFileContent(editPage);
    }

    // 상세 페이지
    const showPage = path.join(appDir, resource, 'show', '[id]', 'page.tsx');
    if (fileExists(showPage)) {
      resourceChecks[resource]['show'] = checkFileContent(showPage);
    }
  });

  printStandardizationStatus(resourceChecks);
};

// 실행
main();
