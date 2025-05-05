import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import crypto from "crypto";
import { createBrowserSupabaseClient } from "@/utils/supabase-client";

export const config = {
    runtime: "edge",
    api: {
        bodyParser: false,
    },
};

export const dynamic = "force-dynamic";
export const revalidate = 0;

export async function POST(request: NextRequest): Promise<Response> {
    try {
        console.log(`Apple OAuth Callback Request (POST):`, {
            url: request.url,
            method: request.method,
            headers: Object.fromEntries(request.headers.entries()),
            contentType: request.headers.get("content-type"),
        });

        const formData = await request.formData();
        const code = formData.get("code") as string | null;
        const state = formData.get("state") as string | null;

        console.log("Apple OAuth Callback Data:", {
            hasCode: !!code,
            hasState: !!state,
            state: state ? "present" : "missing",
        });

        if (!code || !state) {
            console.error("Missing required parameters:", {
                hasCode: !!code,
                hasState: !!state,
            });
            return NextResponse.redirect(
                new URL("/login?error=missing_params", request.url),
            );
        }

        let stateData;
        try {
            const decodedState = atob(state);
            console.log("Decoded state:", decodedState);
            stateData = JSON.parse(decodedState);
            console.log("Parsed state data:", {
                redirectUrl: stateData.redirect_url,
                codeVerifier: stateData.code_verifier,
                codeChallenge: stateData.code_challenge,
                rawStateData: stateData,
            });
        } catch (error) {
            console.error("Failed to parse state data:", {
                error,
                state,
                decodedState: state ? atob(state) : null,
            });
            return NextResponse.redirect(
                new URL("/login?error=invalid_state", request.url),
            );
        }

        const redirectUrl = stateData.redirect_url || "/";
        console.log("Final redirect URL from state:", { 
            redirectUrl,
            isAbsoluteUrl: redirectUrl.startsWith('http'),
            stateHasRedirectUrl: 'redirect_url' in stateData,
        });

        // ngrok URL 처리 - 프로덕션 환경의 URL로 변환
        let finalRedirectUrl = redirectUrl;
        if (redirectUrl.startsWith('http')) {
            // 외부 URL인 경우 프로덕션 URL로 변환
            if (redirectUrl.includes("ngrok")) {
                finalRedirectUrl = redirectUrl.replace(
                    /https?:\/\/.*?ngrok(-free)?\.app/,
                    "https://www.picnic.fan"
                );
            } else if (!redirectUrl.includes("picnic.fan")) {
                // picnic.fan 도메인이 아닌 경우 홈페이지로 리다이렉트
                finalRedirectUrl = "https://www.picnic.fan/";
            }
        } else {
            // 상대 URL인 경우 www.picnic.fan 도메인으로 설정
            finalRedirectUrl = `https://www.picnic.fan${redirectUrl.startsWith('/') ? '' : '/'}${redirectUrl}`;
        }

        console.log("Modified redirect URL:", {
            original: redirectUrl,
            modified: finalRedirectUrl,
            isProduction: process.env.NODE_ENV === "production",
        });

        const codeVerifier = stateData.code_verifier;
        const codeChallenge = stateData.code_challenge;

        console.log("PKCE parameters:", {
            codeVerifier,
            codeChallenge,
            stateData,
        });

        if (!codeVerifier || !codeChallenge) {
            console.error("Missing PKCE parameters for Apple login:", {
                hasCodeVerifier: !!codeVerifier,
                hasCodeChallenge: !!codeChallenge,
                stateData: stateData,
            });
            return NextResponse.redirect(
                new URL("/login?error=missing_pkce_params", request.url),
            );
        }

        const supabase = createClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
            {
                auth: {
                    flowType: "pkce",
                    detectSessionInUrl: true,
                    autoRefreshToken: true,
                    persistSession: true,
                    storageKey: "picnic-auth",
                },
                global: {
                    headers: {
                        'X-Apple-Client-Id': 'fan.picnic.web',
                        'X-Apple-Client-Secret': process.env.APPLE_CLIENT_SECRET || '',
                        'X-Auth-Flow': 'pkce',
                        'X-Auth-Return-Redirect': 'true',
                        'X-Client-Origin': new URL(request.url).origin,
                        'X-Client-Info': 'picnicweb',
                        'X-OAuth-Provider': 'apple',
                    }
                }
            },
        );

        console.log("Supabase client created with enhanced configuration:", {
            url: process.env.NEXT_PUBLIC_SUPABASE_URL,
            requestOrigin: new URL(request.url).origin,
            flowType: "pkce",
            appleClientId: "fan.picnic.web",
            hasAppleSecret: !!process.env.APPLE_CLIENT_SECRET,
            appleSecretLength: (process.env.APPLE_CLIENT_SECRET || '').length,
            authCodeLength: code?.length,
            referer: request.headers.get('referer'),
            userAgent: request.headers.get('user-agent'),
        });

        console.log("Exchanging code for session:", {
            hasCode: !!code,
            codeVerifier: !!codeVerifier,
            codeLength: code?.length,
            verifierLength: codeVerifier?.length,
        });

        // code와 verifier가 비어있지 않은지 철저히 확인
        if (!code || code.trim() === '') {
            console.error("Auth code is empty or missing", { code });
            return NextResponse.redirect(
                new URL("/login?error=missing_auth_code", request.url),
                302
            );
        }

        if (!codeVerifier || codeVerifier.trim() === '') {
            console.error("Code verifier is empty or missing", { codeVerifier });
            return NextResponse.redirect(
                new URL("/login?error=missing_code_verifier", request.url),
                302
            );
        }

        console.log("Code and Verifier details:", {
            codeFirstChars: code.substring(0, 10),
            codeLength: code.length,
            verifierFirstChars: codeVerifier.substring(0, 10),
            verifierLength: codeVerifier.length,
        });

        console.log("code", code);

        // PKCE 검증
        const calculatedChallenge = crypto
            .createHash("sha256")
            .update(codeVerifier)
            .digest("base64")
            .replace(/\+/g, "-")
            .replace(/\//g, "_")
            .replace(/=/g, "");

        if (calculatedChallenge !== codeChallenge) {
            console.error("PKCE challenge verification failed:", {
                expected: codeChallenge,
                actual: calculatedChallenge,
            });
            return NextResponse.redirect(
                new URL("/login?error=invalid_pkce_challenge", request.url),
            );
        }

        // 세션 교환 시도
        console.log("About to exchange code for session with the following details:", {
            codeLength: code.length,
            codePrefix: code.substring(0, 10) + "...",
            codeSuffix: "..." + code.substring(code.length - 10),
            verifierLength: codeVerifier?.length || 0,
            flowType: "pkce",
            tokenEndpoint: process.env.NEXT_PUBLIC_SUPABASE_URL + "/auth/v1/token",
        });

        try {
            // 상태 데이터에서 코드 검증자 사용
            const stateVerifier = codeVerifier;
            
            // 추가적인 에러 정보 기록
            console.log("Using verifier from state:", {
                verifierLength: stateVerifier?.length || 0,
                hasStateVerifier: !!stateVerifier,
                stateSource: "stateData",
                clientId: "fan.picnic.web",
                tokenUrl: process.env.NEXT_PUBLIC_SUPABASE_URL + "/auth/v1/token",
            });
            
            // 세션 교환 시도
            console.log("Attempting code exchange with parameters:", {
                codeLength: code.length,
                verifierLength: stateVerifier?.length || 0,
                supabaseUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
                hasAnonKey: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
                authEndpoint: "/auth/v1/token",
            });
            
            try {
                // 세션 획득을 위해 Supabase API 직접 호출
                console.log("Sending token request with:", {
                    url: `${process.env.NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token`,
                    grant_type: 'authorization_code',
                    code_verifier_length: stateVerifier?.length || 0,
                    code_length: code.length,
                    redirect_uri: 'https://www.picnic.fan/auth/callback/apple',
                    client_id: 'fan.picnic.web',
                    has_apikey: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
                });
                
                const tokenResponse = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
                        'X-Client-Info': 'picnicweb',
                    },
                    body: JSON.stringify({
                        grant_type: 'authorization_code',
                        code_verifier: stateVerifier,
                        code: code,
                        redirect_uri: 'https://www.picnic.fan/auth/callback/apple',
                        client_id: 'fan.picnic.web'
                    }),
                });
                
                if (!tokenResponse.ok) {
                    // 토큰 획득 실패 로그
                    console.error("Token response not OK:", {
                        status: tokenResponse.status,
                        statusText: tokenResponse.statusText,
                        headers: Object.fromEntries(tokenResponse.headers.entries()),
                    });
                    
                    // 응답 내용 로깅 시도
                    let errorJson;
                    let responseText;
                    try {
                        // 먼저 텍스트로 읽기 시도
                        responseText = await tokenResponse.text();
                        console.error("Raw response text:", responseText);
                        
                        // JSON 파싱 시도
                        try {
                            errorJson = JSON.parse(responseText);
                            console.error("Parsed error JSON:", errorJson);
                        } catch (parseError) {
                            console.error("Failed to parse response as JSON:", {
                                parseError,
                                responseText
                            });
                        }
                    } catch (textError) {
                        console.error("Failed to read response as text:", textError);
                    }
                    
                    // 직접 리다이렉트
                    console.log("Token exchange failed, redirecting to homepage anyway:", finalRedirectUrl);
                    return NextResponse.redirect(
                        new URL(finalRedirectUrl, request.url),
                        302
                    );
                }
                
                // 토큰 획득 성공
                const tokenData = await tokenResponse.json();
                console.log("Token exchange successful:", {
                    hasAccessToken: !!tokenData.access_token,
                    hasRefreshToken: !!tokenData.refresh_token,
                    expiresIn: tokenData.expires_in,
                });
                
                // 세션 정보를 쿠키에 저장
                const redirectResponse = NextResponse.redirect(
                    new URL(finalRedirectUrl, request.url),
                    302,
                );
                
                // 현재 요청의 호스트명 추출
                const hostName = new URL(request.url).hostname;
                const cookieDomain = process.env.NODE_ENV === "production" 
                    ? hostName.includes("picnic.fan") ? "picnic.fan" : hostName
                    : undefined;
                    
                // 세션 쿠키 설정
                if (tokenData.access_token) {
                    redirectResponse.cookies.set({
                        name: "sb-access-token",
                        value: tokenData.access_token,
                        path: "/",
                        domain: cookieDomain,
                        secure: process.env.NODE_ENV === "production",
                        sameSite: "lax",
                        httpOnly: true,
                    });
                    
                    if (tokenData.refresh_token) {
                        redirectResponse.cookies.set({
                            name: "sb-refresh-token",
                            value: tokenData.refresh_token,
                            path: "/",
                            domain: cookieDomain,
                            secure: process.env.NODE_ENV === "production",
                            sameSite: "lax",
                            httpOnly: true,
                        });
                    }
                    
                    console.log("Auth cookies set, redirecting to:", finalRedirectUrl);
                    return redirectResponse;
                } else {
                    console.log("No access token received, redirecting without auth cookies");
                    return NextResponse.redirect(
                        new URL(finalRedirectUrl, request.url),
                        302
                    );
                }
            } catch (tokenError) {
                console.error("Error during token exchange:", {
                    error: tokenError,
                    message: tokenError instanceof Error ? tokenError.message : "Unknown error",
                });
                
                // 오류 발생 시 홈페이지로 리다이렉트
                return NextResponse.redirect(
                    new URL(finalRedirectUrl, request.url),
                    302
                );
            }
        } catch (error) {
            console.error("Unexpected error during session exchange:", {
                error,
                message: error instanceof Error ? error.message : "Unknown error",
                stack: error instanceof Error ? error.stack : undefined,
                url: request.url,
            });
            return NextResponse.redirect(
                new URL("/login?error=session_exchange_error", request.url),
                302,
            );
        }
    } catch (error) {
        console.error("Unexpected error during Apple OAuth callback:", {
            error,
            message: error instanceof Error ? error.message : "Unknown error",
            stack: error instanceof Error ? error.stack : undefined,
            url: request.url,
        });
        return NextResponse.redirect(
            new URL("/login?error=callback_error", request.url),
            302,
        );
    }
}

// GET 요청도 처리하도록 추가
export async function GET(request: NextRequest): Promise<Response> {
    try {
        console.log(`Apple OAuth Callback Request (GET) at /auth/callback/apple:`, {
            url: request.url,
            method: request.method,
            headers: Object.fromEntries(request.headers.entries()),
            searchParams: Object.fromEntries(new URL(request.url).searchParams.entries()),
        });

        // URL 파라미터에서 코드와 상태를 추출
        const url = new URL(request.url);
        const code = url.searchParams.get("code");
        const state = url.searchParams.get("state");
        const error = url.searchParams.get("error");
        const errorDescription = url.searchParams.get("error_description");

        console.log("Apple OAuth GET Callback Data:", {
            hasCode: !!code,
            hasState: !!state,
            state: state ? "present" : "missing",
            error,
            errorDescription,
            allParams: Object.fromEntries(url.searchParams.entries())
        });

        // 오류 파라미터 확인
        if (error) {
            console.error(`Apple OAuth Error Response: ${error}`, {
                error,
                errorDescription,
                url: request.url,
            });
            return NextResponse.redirect(
                new URL(`/login?error=${error}&error_description=${encodeURIComponent(errorDescription || 'Unknown error')}`, request.url),
                302
            );
        }

        if (!code) {
            console.error("Auth code missing on GET request");
            return NextResponse.redirect(
                new URL("/login?error=missing_auth_code", request.url),
                302
            );
        }

        // state 파라미터 없이 진행 (필요한 경우)
        let stateData: any = {
            redirect_url: '/'
        };

        // state 파라미터가 있는 경우 파싱 시도
        if (state) {
            try {
                const decodedState = atob(state);
                console.log("Decoded state (GET):", decodedState);
                stateData = JSON.parse(decodedState);
                console.log("Parsed state data (GET):", stateData);
            } catch (error) {
                console.error("Failed to parse state data on GET request:", {
                    error,
                    state,
                });
                // 파싱에 실패하더라도 계속 진행 (기본값 사용)
            }
        } else {
            console.log("No state parameter provided, using default values");
        }

        // 여기서부터는 POST 핸들러와 유사한 로직을 따름
        const redirectUrl = stateData.redirect_url || "/";
        console.log("Final redirect URL from state (GET):", { 
            redirectUrl,
            isAbsoluteUrl: redirectUrl.startsWith('http'),
            stateHasRedirectUrl: 'redirect_url' in stateData,
        });
        
        // ngrok URL 처리 - 프로덕션 환경의 URL로 변환
        let finalRedirectUrl = redirectUrl;
        if (redirectUrl.startsWith('http')) {
            // 외부 URL인 경우 프로덕션 URL로 변환
            if (redirectUrl.includes("ngrok")) {
                finalRedirectUrl = redirectUrl.replace(
                    /https?:\/\/.*?ngrok(-free)?\.app/,
                    "https://www.picnic.fan"
                );
            } else if (!redirectUrl.includes("picnic.fan")) {
                // picnic.fan 도메인이 아닌 경우 홈페이지로 리다이렉트
                finalRedirectUrl = "https://www.picnic.fan/";
            }
        } else {
            // 상대 URL인 경우 www.picnic.fan 도메인으로 설정
            finalRedirectUrl = `https://www.picnic.fan${redirectUrl.startsWith('/') ? '' : '/'}${redirectUrl}`;
        }

        console.log("Modified redirect URL (GET):", {
            original: redirectUrl,
            modified: finalRedirectUrl,
            isProduction: process.env.NODE_ENV === "production",
        });

        // 코드 검증자 확인 (state 객체에서 추출)
        const stateVerifier = stateData.code_verifier;
        
        try {
            // 세션 획득을 위해 Supabase API 직접 호출
            console.log("Sending token request with:", {
                url: `${process.env.NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token`,
                grant_type: 'authorization_code',
                code_verifier_length: stateVerifier?.length || 0,
                code_length: code.length,
                redirect_uri: 'https://www.picnic.fan/auth/callback/apple',
                client_id: 'fan.picnic.web',
                has_apikey: !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
            });
            
            const tokenResponse = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/auth/v1/token`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
                    'X-Client-Info': 'picnicweb',
                },
                body: JSON.stringify({
                    grant_type: 'authorization_code',
                    code_verifier: stateVerifier,
                    code: code,
                    redirect_uri: 'https://www.picnic.fan/auth/callback/apple',
                    client_id: 'fan.picnic.web'
                }),
            });
            
            if (!tokenResponse.ok) {
                // 토큰 획득 실패 로그
                console.error("Token response not OK:", {
                    status: tokenResponse.status,
                    statusText: tokenResponse.statusText,
                    headers: Object.fromEntries(tokenResponse.headers.entries()),
                });
                
                // 응답 내용 로깅 시도
                let errorJson;
                let responseText;
                try {
                    // 먼저 텍스트로 읽기 시도
                    responseText = await tokenResponse.text();
                    console.error("Raw response text:", responseText);
                    
                    // JSON 파싱 시도
                    try {
                        errorJson = JSON.parse(responseText);
                        console.error("Parsed error JSON:", errorJson);
                    } catch (parseError) {
                        console.error("Failed to parse response as JSON:", {
                            parseError,
                            responseText
                        });
                    }
                } catch (textError) {
                    console.error("Failed to read response as text:", textError);
                }
                
                // 직접 리다이렉트
                console.log("Token exchange failed, redirecting to homepage anyway (GET):", finalRedirectUrl);
                return NextResponse.redirect(
                    new URL(finalRedirectUrl, request.url),
                    302
                );
            }
            
            // 토큰 획득 성공
            const tokenData = await tokenResponse.json();
            console.log("Token exchange successful (GET):", {
                hasAccessToken: !!tokenData.access_token,
                hasRefreshToken: !!tokenData.refresh_token,
                expiresIn: tokenData.expires_in,
            });
            
            // 세션 정보를 쿠키에 저장
            const redirectResponse = NextResponse.redirect(
                new URL(finalRedirectUrl, request.url),
                302,
            );
            
            // 현재 요청의 호스트명 추출
            const hostName = new URL(request.url).hostname;
            const cookieDomain = process.env.NODE_ENV === "production" 
                ? hostName.includes("picnic.fan") ? "picnic.fan" : hostName
                : undefined;
                
            // 세션 쿠키 설정
            if (tokenData.access_token) {
                redirectResponse.cookies.set({
                    name: "sb-access-token",
                    value: tokenData.access_token,
                    path: "/",
                    domain: cookieDomain,
                    secure: process.env.NODE_ENV === "production",
                    sameSite: "lax",
                    httpOnly: true,
                });
                
                if (tokenData.refresh_token) {
                    redirectResponse.cookies.set({
                        name: "sb-refresh-token",
                        value: tokenData.refresh_token,
                        path: "/",
                        domain: cookieDomain,
                        secure: process.env.NODE_ENV === "production",
                        sameSite: "lax",
                        httpOnly: true,
                    });
                }
                
                console.log("Auth cookies set, redirecting to (GET):", finalRedirectUrl);
                return redirectResponse;
            } else {
                console.log("No access token received, redirecting without auth cookies (GET)");
                return NextResponse.redirect(
                    new URL(finalRedirectUrl, request.url),
                    302
                );
            }
        } catch (tokenError) {
            console.error("Error during token exchange (GET):", {
                error: tokenError,
                message: tokenError instanceof Error ? tokenError.message : "Unknown error",
            });
            
            // 오류 발생 시 홈페이지로 리다이렉트
            return NextResponse.redirect(
                new URL(finalRedirectUrl, request.url),
                302
            );
        }
    } catch (error) {
        console.error("Unexpected error during GET OAuth callback:", {
            error,
            message: error instanceof Error ? error.message : "Unknown error",
            stack: error instanceof Error ? error.stack : undefined,
            url: request.url,
        });
        return NextResponse.redirect(
            new URL("/login?error=callback_error", request.url),
            302,
        );
    }
}
