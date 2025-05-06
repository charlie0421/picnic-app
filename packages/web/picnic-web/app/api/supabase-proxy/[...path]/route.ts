import { NextRequest, NextResponse } from 'next/server';

// Supabase API URL
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export async function GET(request: NextRequest, { params }: { params: { path: string[] } }) {
  return handleRequest(request, params.path, 'GET');
}

export async function POST(request: NextRequest, { params }: { params: { path: string[] } }) {
  return handleRequest(request, params.path, 'POST');
}

export async function PUT(request: NextRequest, { params }: { params: { path: string[] } }) {
  return handleRequest(request, params.path, 'PUT');
}

export async function DELETE(request: NextRequest, { params }: { params: { path: string[] } }) {
  return handleRequest(request, params.path, 'DELETE');
}

export async function OPTIONS(request: NextRequest, { params }: { params: { path: string[] } }) {
  return handleRequest(request, params.path, 'OPTIONS');
}

export async function PATCH(request: NextRequest, { params }: { params: { path: string[] } }) {
  return handleRequest(request, params.path, 'PATCH');
}

// 모든 HTTP 메서드를 처리하는 공통 함수
async function handleRequest(
  request: NextRequest,
  pathSegments: string[],
  method: string
): Promise<NextResponse> {
  try {
    // 요청 경로 생성
    const path = pathSegments.join('/');
    const targetUrl = `${supabaseUrl}/${path}`;

    console.log(`프록시 요청: ${method} ${targetUrl}`);

    // 원본 요청 헤더 복사
    const headers = new Headers(request.headers);
    
    // Authorization 헤더 추가 (anon key 사용)
    if (!headers.has('Authorization') && supabaseKey) {
      headers.set('Authorization', `Bearer ${supabaseKey}`);
    }

    // 필요없는 헤더 제거
    headers.delete('host');
    
    // OPTIONS 요청에 대한 CORS 프리플라이트 응답
    if (method === 'OPTIONS') {
      return new NextResponse(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, X-Custom-Environment',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // 요청 본문 복사
    let body = null;
    if (method !== 'GET' && method !== 'HEAD' && request.body) {
      body = await request.arrayBuffer();
    }

    // Supabase API로 요청 전송
    const response = await fetch(targetUrl, {
      method,
      headers,
      body,
      redirect: 'follow',
    });

    // 응답 헤더 복사
    const responseHeaders = new Headers(response.headers);
    responseHeaders.set('Access-Control-Allow-Origin', '*');
    responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
    responseHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Client-Info, X-Custom-Environment');

    // 응답 본문 복사
    const responseData = await response.arrayBuffer();

    // 응답 생성
    return new NextResponse(responseData, {
      status: response.status,
      statusText: response.statusText,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error('Supabase 프록시 오류:', error);
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
} 