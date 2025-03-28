import { walk } from 'https://deno.land/std@0.208.0/fs/walk.ts';

// 공통 import map 정의
const commonImports = {
  '@supabase/supabase-js': 'https://esm.sh/@supabase/supabase-js@2.49.3',
  'crypto-js': 'https://esm.sh/crypto-js',
  postgres: 'https://deno.land/x/postgres@v0.19.3/mod.ts',
  'http/server': 'https://deno.land/std@0.224.0/http/server.ts',
};

// 공통 compiler options 정의
const commonCompilerOptions = {
  allowJs: true,
  lib: ['deno.window', 'deno.ns', 'deno.unstable', 'dom', 'esnext'],
  strict: true,
  checkJs: false,
};

async function createOrUpdateDenoJson(filePath: string) {
  try {
    let denoJson;
    try {
      // deno.json 파일 읽기
      const content = await Deno.readTextFile(filePath);
      denoJson = JSON.parse(content);
    } catch {
      // 파일이 없거나 읽기 실패 시 새로 생성
      denoJson = {
        tasks: {
          start: 'deno run --allow-net --allow-env index.ts',
        },
        imports: {},
        compilerOptions: {},
      };
    }

    // shared 경로 계산
    const sharedRelativePath = '../../../../shared/';

    // imports 업데이트
    denoJson.imports = {
      ...commonImports,
      '@shared/': sharedRelativePath,
    };

    // compilerOptions 업데이트
    denoJson.compilerOptions = {
      ...commonCompilerOptions,
      types: [`${sharedRelativePath}types.d.ts`],
    };

    // tasks가 없다면 추가
    if (!denoJson.tasks) {
      denoJson.tasks = {
        start: 'deno run --allow-net --allow-env index.ts',
      };
    }

    // 파일 쓰기
    await Deno.writeTextFile(filePath, JSON.stringify(denoJson, null, 2));
    console.log(`Updated ${filePath}`);
  } catch (error) {
    console.error(`Error updating ${filePath}:`, error);
  }
}

async function updateProjectFunctions(projectDir: string) {
  console.log(`\nProcessing ${projectDir}...`);
  const rootDir = new URL('..', import.meta.url).pathname;
  const functionsPath = `${rootDir}${projectDir}/supabase/functions`;

  try {
    // functions 디렉토리 내의 모든 디렉토리 찾기
    for await (const entry of walk(functionsPath, {
      includeDirs: true,
      includeFiles: false,
    })) {
      // deno.json 파일 경로 생성
      const denoJsonPath = `${entry.path}/deno.json`;

      // index.ts 파일이 있는 경우에만 deno.json 생성/업데이트
      try {
        await Deno.stat(`${entry.path}/index.ts`);
        await createOrUpdateDenoJson(denoJsonPath);
      } catch {
        // index.ts 파일이 없으면 건너뛰기
        continue;
      }
    }
  } catch (error) {
    console.error(`Error processing ${projectDir}:`, error);
  }
}

async function main() {
  // picnic과 ttja 프로젝트 모두 처리
  await updateProjectFunctions('picnic');
  await updateProjectFunctions('ttja');
}

if (import.meta.main) {
  main();
}
