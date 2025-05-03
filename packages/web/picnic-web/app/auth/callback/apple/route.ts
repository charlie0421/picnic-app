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
        console.log("Final redirect URL:", { redirectUrl });

        // ngrok URL 처리 - 프로덕션 환경의 URL로 변환
        let finalRedirectUrl = redirectUrl;
        if (process.env.NODE_ENV === "production" && redirectUrl.includes("ngrok")) {
            // ngrok URL을 프로덕션 URL로 변환
            finalRedirectUrl = redirectUrl.replace(
                /https?:\/\/.*?ngrok(-free)?\.app/,
                "https://www.picnic.fan"
            );
            console.log("Modified redirect URL for production:", {
                original: redirectUrl,
                modified: finalRedirectUrl
            });
        }

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
                        'X-Custom-Redirect-Url': 'https://www.picnic.fan/auth/callback/apple'
                    }
                }
            },
        );

        console.log("Supabase client created with Apple OAuth config:", {
            url: process.env.NEXT_PUBLIC_SUPABASE_URL,
            requestOrigin: new URL(request.url).origin,
            flowType: "pkce",
            appleClientId: "fan.picnic.web",
            hasAppleSecret: !!process.env.APPLE_CLIENT_SECRET,
        });

        console.log("Exchanging code for session:", {
            hasCode: !!code,
            codeVerifier: !!codeVerifier,
            codeLength: code?.length,
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

        // Supabase의 PKCE 인증 흐름에 맞게 코드 교환
        const { data, error } = await supabase.auth.exchangeCodeForSession(
            code,
        );

        if (error || !data.session) {
            console.error("OAuth session exchange error:", {
                error,
                hasSession: !!data?.session,
                code: error?.code,
                message: error?.message,
                requestUrl: request.url,
                nextApiUrl: process.env.NEXT_PUBLIC_SITE_URL,
                allowedUrl: process.env.NEXT_PUBLIC_SUPABASE_URL,
                requestOrigin: new URL(request.url).origin,
                requestHost: new URL(request.url).hostname,
                hostMatches: new URL(request.url).hostname === new URL(process.env.NEXT_PUBLIC_SUPABASE_URL || '').hostname,
            });
            
            // 오류 유형에 따라 다른 에러 코드 사용
            const errorCode = error?.message?.includes("exchange") 
                ? "server_error" 
                : "oauth_error";
                
            const errorDesc = error?.message || "Unknown error";
            
            return NextResponse.redirect(
                new URL(`/login?error=${errorCode}&error_code=${error?.code || 'unknown'}&error_description=${encodeURIComponent(errorDesc)}`, request.url),
                302,
            );
        }

        console.log("Session exchange successful:", {
            userId: data.session?.user?.id,
            expiresAt: data.session?.expires_at,
        });

        // 세션 정보를 쿠키에 저장
        const redirectResponse = NextResponse.redirect(
            new URL(finalRedirectUrl, request.url),
            302,
        );

        // 현재 요청의 호스트명 추출
        const hostName = new URL(request.url).hostname;
        console.log("Cookie setup:", {
            hostName,
            redirectUrl,
            isDev: process.env.NODE_ENV !== "production",
        });

        // 개발 환경에서는 쿠키 도메인 설정을 생략 (localhost로 설정)
        const cookieDomain = process.env.NODE_ENV === "production" 
            ? hostName.includes("picnic.fan") ? "picnic.fan" : hostName
            : undefined;

        redirectResponse.cookies.set({
            name: "sb-access-token",
            value: data.session.access_token,
            path: "/",
            domain: cookieDomain,
            secure: process.env.NODE_ENV === "production",
            sameSite: "lax",
            httpOnly: true,
        });

        redirectResponse.cookies.set({
            name: "sb-refresh-token",
            value: data.session.refresh_token!,
            path: "/",
            domain: cookieDomain,
            secure: process.env.NODE_ENV === "production",
            sameSite: "lax",
            httpOnly: true,
        });

        return redirectResponse;
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
