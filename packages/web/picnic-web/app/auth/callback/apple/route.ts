import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import crypto from "crypto";

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

        const supabase = createClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
            {
                auth: {
                    flowType: "pkce",
                    detectSessionInUrl: false,
                    persistSession: false,
                    autoRefreshToken: true,
                },
            },
        );

        console.log("Exchanging code for session:", {
            hasCode: !!code,
            hasCodeVerifier: !!codeVerifier,
        });

        // Apple 토큰 엔드포인트로 요청
        const tokenResponse = await fetch(
            "https://appleid.apple.com/auth/token",
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                body: new URLSearchParams({
                    grant_type: "authorization_code",
                    code,
                    client_id: process.env.APPLE_CLIENT_ID!,
                    client_secret: process.env.APPLE_CLIENT_SECRET!,
                    redirect_uri: process.env.APPLE_REDIRECT_URI!,
                }),
            },
        );

        if (!tokenResponse.ok) {
            console.error(
                "Apple token exchange failed:",
                await tokenResponse.text(),
            );
            return NextResponse.redirect(
                new URL(
                    "/login?error=apple_token_exchange_failed",
                    request.url,
                ),
            );
        }

        const tokenData = await tokenResponse.json();
        const { id_token, access_token } = tokenData;

        // Supabase로 세션 생성
        // @ts-ignore - Supabase 타입 정의가 최신 버전과 맞지 않음
        const { data, error } = await supabase.auth.signInWithIdToken({
            provider: "apple",
            token: id_token,
            access_token,
        });

        if (error || !data.session) {
            console.error("OAuth session exchange error:", {
                error,
                hasSession: !!data?.session,
                code: error?.code,
                message: error?.message,
            });
            return NextResponse.redirect(
                new URL("/login?error=oauth_error", request.url),
                302,
            );
        }

        console.log("Session exchange successful:", {
            userId: data.session?.user?.id,
            expiresAt: data.session?.expires_at,
        });

        // 세션 정보를 쿠키에 저장
        const redirectResponse = NextResponse.redirect(
            new URL(redirectUrl, request.url),
            302,
        );

        redirectResponse.cookies.set({
            name: "sb-access-token",
            value: data.session.access_token,
            path: "/",
            domain: "www.picnic.fan",
            secure: process.env.NODE_ENV === "production",
            sameSite: "lax",
            httpOnly: true,
        });

        redirectResponse.cookies.set({
            name: "sb-refresh-token",
            value: data.session.refresh_token!,
            path: "/",
            domain: "www.picnic.fan",
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
