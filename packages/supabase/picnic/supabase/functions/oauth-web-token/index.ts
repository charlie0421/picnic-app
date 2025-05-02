import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

serve(async (req) => {
  const { provider, code, codeVerifier, redirect_uri } = await req.json();
  let tokenUrl = '';
  let params: URLSearchParams | null = null;

  if (provider === 'apple') {
    tokenUrl = 'https://appleid.apple.com/auth/token';
    params = new URLSearchParams({
      client_id: Deno.env.get('APPLE_WEB_CLIENT_ID')!,
      client_secret: Deno.env.get('APPLE_WEB_SECRET')!,
      code,
      grant_type: 'authorization_code',
      code_verifier: codeVerifier,
      redirect_uri,
    });
  } else if (provider === 'kakao') {
    tokenUrl = 'https://kauth.kakao.com/oauth/token';
    params = new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: Deno.env.get('KAKAO_CLIENT_ID')!,
      redirect_uri,
      code,
    });
  } else if (provider === 'wechat') {
    const appid = Deno.env.get('WECHAT_APP_ID')!;
    const secret = Deno.env.get('WECHAT_APP_SECRET')!;
    tokenUrl = `https://api.weixin.qq.com/sns/oauth2/access_token?appid=${appid}&secret=${secret}&code=${code}&grant_type=authorization_code`;
  } else {
    return new Response(JSON.stringify({ error: 'Unsupported provider' }), {
      status: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }

  const res = await fetch(tokenUrl, {
    method: provider === 'wechat' ? 'GET' : 'POST',
    headers:
      provider === 'wechat'
        ? undefined
        : { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: provider === 'wechat' ? undefined : params,
  });

  const data = await res.json();

  const responseData: any = {
    error: data.error || data.error_description || data.errmsg || null,
  };

  if (provider === 'apple') {
    responseData.id_token = data.id_token;
    responseData.access_token = data.access_token;
  } else if (provider === 'kakao') {
    responseData.access_token = data.access_token;
  } else if (provider === 'wechat') {
    responseData.access_token = data.access_token;
    responseData.openid = data.openid;
  }

  return new Response(JSON.stringify(responseData), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
});
