import { NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';

export async function GET() {
  try {
    // 1. Vercel의 Git hash 확인
    let hash = process.env.VERCEL_GIT_COMMIT_SHA;

    // 2. 없으면 .git-hash 파일에서 읽기
    if (!hash) {
      try {
        const gitHashPath = path.join(process.cwd(), '.git-hash');
        hash = await fs.readFile(gitHashPath, 'utf-8');
        hash = hash.trim();
      } catch (err) {
        console.log('Failed to read .git-hash:', err);
        hash = 'dev';
      }
    }

    console.log('Returning hash:', hash);
    return NextResponse.json({ hash });
  } catch (error) {
    console.error('Version API error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 },
    );
  }
}
