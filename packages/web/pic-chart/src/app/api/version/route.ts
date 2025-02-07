import { NextResponse } from 'next/server';

// 실제로는 package.json, Git commit hash 혹은 ENV에서 가져올 수도 있음
const CURRENT_VERSION = '1.0.0';

export async function GET() {
  return NextResponse.json({ version: CURRENT_VERSION });
}
