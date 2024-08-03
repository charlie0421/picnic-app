import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { config } from "https://deno.land/x/dotenv/mod.ts";
const env = config();
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
Deno.serve(async (req)=>{
  try {
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    const { accessToken } = await req.json();
    console.log('Kakao accessToken:', accessToken);
    const kakaoResponse = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });
    if (!kakaoResponse.ok) {
      throw new Error("Failed to fetch Kakao user info");
    }
    const kakaoUser = await kakaoResponse.json();
    const kakaoId = kakaoUser.id;
    const email = kakaoUser.kakao_account.email;
    const nickname = kakaoUser.properties.nickname;
    const profileImageUrl = kakaoUser.properties.profile_image;
    console.log('Kakao user:', kakaoUser);
    console.log('Kakao ID:', kakaoId);
    console.log('Email:', email);
    console.log('Nickname:', nickname);
    console.log('Profile image URL:', profileImageUrl);
    const { data: existingUser, error: findUserError } = await supabaseClient.rpc('find_user_by_email', {
      user_email: email
    }).single();
    console.log('Supabase user:', existingUser);
    console.log('Supabase error:', findUserError);
    if (findUserError && findUserError.code !== 'PGRST116') {
      throw findUserError;
    }
    let userId;
    if (existingUser) {
      userId = existingUser.id;
      const { error: updateError } = await supabaseClient.rpc('update_user_metadata', {
        meta_data: {
          raw_user_meta_data: {
            iss: "https://kapi.kakao.com",
            provider_id: kakaoId,
            sub: kakaoId,
            name: nickname,
            user_name: nickname,
            preferred_username: nickname,
            nickname: nickname,
            email: email,
            user_id: userId,
            avatar_url: profileImageUrl,
            email_verified: true,
            phone_verified: false
          },
          raw_app_meta_data: {
            provider: "kakao",
            providers: [
              "kakao"
            ]
          }
        }
      });
      if (updateError) throw updateError;
    } else {
      console.info({
        iss: "https://kapi.kakao.com",
        provider_id: kakaoId,
        sub: kakaoId,
        name: nickname,
        user_name: nickname,
        preferred_username: nickname,
        nickname: nickname,
        email: email,
        user_id: userId,
        avatar_url: profileImageUrl,
        email_verified: true,
        phone_verified: false
      });
      const { data: newUser, error: signUpError } = await supabaseClient.auth.admin.createUser({
        iss: "https://kapi.kakao.com",
        provider_id: kakaoId,
        sub: kakaoId,
        name: nickname,
        user_name: nickname,
        preferred_username: nickname,
        nickname: nickname,
        email: email,
        user_id: userId,
        avatar_url: profileImageUrl,
        email_verified: true,
        phone_verified: false
      });
      if (signUpError) throw signUpError;
      userId = newUser.id;
    }
    const { data: tokenData, error: tokenError } = await supabaseClient.auth.api.generateLink({
      email: email,
      provider: 'kakao'
    });
    if (tokenError) throw tokenError;
    const jwt = tokenData.session.access_token;
    console.log('Supabase JWT:', jwt);
    return new Response(JSON.stringify({
      token: jwt
    }), {
      status: 200,
      headers: {
        "Content-Type": "application/json"
      }
    });
  } catch (error) {
    console.error('Error:', error);
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 400,
      headers: {
        "Content-Type": "application/json"
      }
    });
  }
});
