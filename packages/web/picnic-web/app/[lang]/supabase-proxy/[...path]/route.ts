import { NextRequest, NextResponse } from 'next/server';

// Supabase API URL
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export async function GET(request: NextRequest, { params }: { params: { path: string[], lang: string } }) {
  console.log(`[lang] 프록시 GET 요청 처리: /${params.lang}/supabase-proxy/${params.path.join('/')}`);
  return handleRequest(request, params.path, 'GET');
}

export async function POST(request: NextRequest, { params }: { params: { path: string[], lang: string } }) {
  console.log(`[lang] 프록시 POST 요청 처리: /${params.lang}/supabase-proxy/${params.path.join('/')}`);
  return handleRequest(request, params.path, 'POST');
}

export async function PUT(request: NextRequest, { params }: { params: { path: string[], lang: string } }) {
  console.log(`[lang] 프록시 PUT 요청 처리: /${params.lang}/supabase-proxy/${params.path.join('/')}`);
  return handleRequest(request, params.path, 'PUT');
}

export async function DELETE(request: NextRequest, { params }: { params: { path: string[], lang: string } }) {
  console.log(`[lang] 프록시 DELETE 요청 처리: /${params.lang}/supabase-proxy/${params.path.join('/')}`);
  return handleRequest(request, params.path, 'DELETE');
}

export async function OPTIONS(request: NextRequest, { params }: { params: { path: string[], lang: string } }) {
  console.log(`[lang] 프록시 OPTIONS 요청 처리: /${params.lang}/supabase-proxy/${params.path.join('/')}`);
  return handleRequest(request, params.path, 'OPTIONS');
}

export async function PATCH(request: NextRequest, { params }: { params: { path: string[], lang: string } }) {
  console.log(`[lang] 프록시 PATCH 요청 처리: /${params.lang}/supabase-proxy/${params.path.join('/')}`);
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

    console.log(`[lang] 프록시 요청: ${method} ${targetUrl}`);

    // 원본 요청 헤더 복사
    const headers = new Headers(request.headers);
    
    // Supabase API 키 헤더 추가 
    if (supabaseKey) {
      headers.set('apikey', supabaseKey);
      headers.set('Authorization', `Bearer ${supabaseKey}`);
      
      console.log("[lang] API 키 헤더 설정 완료:", 
        headers.has('apikey'), 
        headers.has('Authorization')
      );
    } else {
      console.error("[lang] API 키가 환경 변수에 설정되지 않았습니다!");
    }

    // 필요없는 헤더 제거
    headers.delete('host');
    
    // OPTIONS 요청에 대한 CORS 프리플라이트 응답
    if (method === 'OPTIONS') {
      const origin = request.headers.get('origin') || '*';
      return new NextResponse(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': origin,
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, X-Custom-Environment, apikey',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // 요청 본문 복사
    let body = null;
    if (method !== 'GET' && method !== 'HEAD' && request.body) {
      body = await request.arrayBuffer();
    }

    // 요청 URL의 쿼리 파라미터 보존
    const url = new URL(targetUrl);
    const searchParams = new URL(request.url).searchParams;
    searchParams.forEach((value, key) => {
      url.searchParams.append(key, value);
    });
    
    // apikey URL 파라미터 추가 (URL을 통한 인증 지원)
    if (supabaseKey && !url.searchParams.has('apikey')) {
      url.searchParams.append('apikey', supabaseKey);
    }
    
    console.log(`[lang] 최종 요청 URL: ${url.toString()}`);

    // Supabase API로 요청 전송
    const response = await fetch(url, {
      method,
      headers,
      body,
      redirect: 'follow',
    });

    // 응답 헤더 복사
    const responseHeaders = new Headers(response.headers);
    const origin = request.headers.get('origin') || '*';
    responseHeaders.set('Access-Control-Allow-Origin', origin);
    responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
    responseHeaders.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Client-Info, X-Custom-Environment, apikey');
    responseHeaders.set('Access-Control-Allow-Credentials', 'true');

    // 응답 상태 코드와 본문
    const status = response.status;
    const responseData = await response.arrayBuffer();

    // 응답 로깅
    console.log(`[lang] 프록시 응답: ${status} ${response.statusText}`);
    
    // 오류 응답인 경우 로그 출력
    if (status >= 400) {
      const responseText = new TextDecoder().decode(responseData);
      console.error(`[lang] 프록시 오류 응답 본문:`, responseText);
    }
    
    // 응답 생성
    return new NextResponse(responseData, {
      status,
      statusText: response.statusText,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error('[lang] Supabase 프록시 오류:', error);
    return NextResponse.json(
      { error: 'Internal Server Error', message: String(error) },
      { status: 500 }
    );
  }
} 