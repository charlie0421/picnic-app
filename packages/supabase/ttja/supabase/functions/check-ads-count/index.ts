import { serve } from 'http/server';
import { decode } from '@shared/services/jwt/index.ts';
import { createErrorResponse } from '@shared/response.ts';
import { AdCountCheckService } from '@shared/services/ad-count-check/index.ts';

serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return createErrorResponse('No authorization header', 401);
    }

    const token = authHeader.split(' ')[1];
    const [_header, payload] = decode(token);
    const user_id = (payload as { sub: string }).sub;
    if (!user_id) {
      return createErrorResponse('Invalid token', 401);
    }

    // URL에서 플랫폼 파라미터 추출
    const url = new URL(req.url);
    const platformParam = url.searchParams.get('platform') || 'admob';
    const platform = platformParam as 'admob' | 'unity' | 'pangle' | undefined;

    console.log('광고 조회 카운트 체크 시작', { user_id, platform });

    const adCountCheckService = new AdCountCheckService();
    const result = await adCountCheckService.checkAdLimits(user_id, {
      platform,
    });
    console.log('광고 조회 카운트 체크 완료', { user_id, platform, result });

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  } catch (error) {
    return createErrorResponse('Internal server error', 500, 'INTERNAL_ERROR', {
      error,
    });
  }
});
