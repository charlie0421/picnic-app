const fs = require('fs');
const path = require('path');

function copyDependenciesToWorkspace(apiSubfolders) {
  // 루트의 package.json 파일 경로 설정
  const rootPackageJsonPath = path.join(__dirname, 'package.json');
  // 루트의 package.json 파일에서 dependencies와 devDependencies 필드 읽기
  const rootPackageJson = require(rootPackageJsonPath);

  // 각 워크스페이스의 package.json 파일을 처리
  apiSubfolders.forEach(subfolder => {
    // 워크스페이스의 package.json 파일 경로 설정
    const workspaceFolder = path.join(__dirname, 'packages', 'api', subfolder);
    const workspacePackageJsonPath = path.join(workspaceFolder, 'package.json');

    // 워크스페이스의 package.json 파일에서 dependencies와 devDependencies 필드 읽기
    if (fs.existsSync(workspacePackageJsonPath)) {
      const workspacePackageJson = require(workspacePackageJsonPath);

      // 루트의 dependencies와 devDependencies를 병합하여 워크스페이스의 package.json 파일에 쓰기
      // 단, 이미 존재하는 의존성은 덮어쓰지 않도록 하기 위해 Object.assign을 사용합니다.
      workspacePackageJson.dependencies = Object.assign({}, rootPackageJson.dependencies, workspacePackageJson.dependencies);
      workspacePackageJson.devDependencies = Object.assign({}, rootPackageJson.devDependencies, workspacePackageJson.devDependencies);

      // 워크스페이스의 package.json 파일에 쓴 내용 저장
      fs.writeFileSync(workspacePackageJsonPath, JSON.stringify(workspacePackageJson, null, 2));
    } else {
      console.error(`Package.json not found in ${workspaceFolder}`);
    }
  });
}

// 파라미터로 받은 여러 개의 폴더명을 워크스페이스 폴더로 사용하여 실행
const apiSubfolders = process.argv.slice(2);
copyDependenciesToWorkspace(apiSubfolders);
