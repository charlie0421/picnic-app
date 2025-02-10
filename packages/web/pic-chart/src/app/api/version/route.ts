import { NextResponse } from 'next/server';

export async function GET() {
  // VERCEL_GIT_COMMIT_SHA는 서버 사이드에서만 접근 가능
  const hash = process.env.VERCEL_GIT_COMMIT_SHA || 'dev';
  return NextResponse.json({ hash });
}
