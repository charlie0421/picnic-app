import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const hash = process.env.VERCEL_GIT_COMMIT_SHA || 'dev';
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
