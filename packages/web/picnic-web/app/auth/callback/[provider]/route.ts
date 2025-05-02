import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";
import crypto from "crypto";

export const config = {
    runtime: "edge",
    api: {
        bodyParser: false,
    },
};

export const dynamic = "force-dynamic";
export const revalidate = 0;

async function handleOAuthCallback(
    request: NextRequest,
    context: { params: Promise<Record<string, string | string[] | undefined>> },
    getCodeAndState: (
        request: NextRequest,
    ) => Promise<{ code: string | null; state: string | null }>,
): Promise<Response> {
    try {
        const params = await context.params;
        const provider = params.provider as string;

        console.log(`OAuth Callback Request (POST):`, {
            url: request.url,
            method: request.method,
            headers: Object.fromEntries(request.headers.entries()),
            provider,
            contentType: request.headers.get("content-type"),
        });

        const { code, state } = await getCodeAndState(request);

        console.log("OAuth Callback Data:", {
            hasCode: !!code,
            hasState: !!state,
            state: state ? "present" : "missing",
            provider,
            rawState: state,
        });

        if (!code || !state) {
            console.error("Missing required parameters:", {
                hasCode: !!code,
                hasState: !!state,
                provider,
            });
            return NextResponse.redirect(
                new URL("/login?error=missing_params", request.url),
            );
        }

        let stateData;
        try {
            const decodedState = atob(state as string);
            console.log("Decoded state:", decodedState);
            stateData = JSON.parse(decodedState);
            console.log("Parsed state data:", {
                redirectUrl: stateData.redirect_url,
                provider,
                codeVerifier: stateData.code_verifier,
                codeChallenge: stateData.code_challenge,
                rawStateData: stateData,
            });
        } catch (error) {
            console.error("Failed to parse state data:", {
                error,
                state,
                decodedState: state ? atob(state as string) : null,
                provider,
            });
            return NextResponse.redirect(
                new URL("/login?error=invalid_state", request.url),
            );
        }

        const redirectUrl = stateData.redirect_url || "/";
        console.log("Final redirect URL:", {
            redirectUrl,
            provider,
        });

        if (provider === "apple") {
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
                    },
                },
            );

            console.log("Exchanging code for session:", {
                provider,
                hasCode: !!code,
                hasCodeVerifier: !!codeVerifier,
            });

            const { data, error } = await supabase.auth.exchangeCodeForSession(
                code as string,
            );

            if (error || !data.session) {
                console.error("OAuth session exchange error:", {
                    error,
                    hasSession: !!data?.session,
                    provider,
                    code: error?.code,
                    message: error?.message,
                });
                return NextResponse.redirect(
                    new URL(
                        `/login?error=oauth_error&provider=${provider}`,
                        request.url,
                    ),
                    302,
                );
            }

            console.log("Session exchange successful:", {
                provider,
                userId: data.session?.user?.id,
                expiresAt: data.session?.expires_at,
            });

            // 세션 정보를 쿠키에 저장
            const response = NextResponse.redirect(
                new URL(redirectUrl, request.url),
                302,
            );

            response.cookies.set({
                name: "sb-access-token",
                value: data.session.access_token,
                path: "/",
                domain: ".picnic.fan",
                secure: process.env.NODE_ENV === "production",
                sameSite: "lax",
                httpOnly: true,
            });

            response.cookies.set({
                name: "sb-refresh-token",
                value: data.session.refresh_token!,
                path: "/",
                domain: ".picnic.fan",
                secure: process.env.NODE_ENV === "production",
                sameSite: "lax",
                httpOnly: true,
            });

            return response;
        }

        const supabase = createClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
            {
                auth: {
                    flowType: "pkce",
                    detectSessionInUrl: false,
                    persistSession: false,
                },
            },
        );

        console.log("Exchanging code for session:", {
            provider,
            hasCode: !!code,
            hasCodeVerifier: !!stateData.code_verifier,
        });

        const { data, error } = await supabase.auth.exchangeCodeForSession(
            code as string,
        );

        if (error || !data.session) {
            console.error("OAuth session exchange error:", {
                error,
                hasSession: !!data?.session,
                provider,
                code: error?.code,
                message: error?.message,
            });
            return NextResponse.redirect(
                new URL(
                    `/login?error=oauth_error&provider=${provider}`,
                    request.url,
                ),
                302,
            );
        }

        console.log("Session exchange successful:", {
            provider,
            userId: data.session?.user?.id,
            expiresAt: data.session?.expires_at,
        });

        // 세션 정보를 쿠키에 저장
        const response = NextResponse.redirect(
            new URL(redirectUrl, request.url),
            302,
        );

        response.cookies.set({
            name: "sb-access-token",
            value: data.session.access_token,
            path: "/",
            domain: ".picnic.fan",
            secure: process.env.NODE_ENV === "production",
            sameSite: "lax",
            httpOnly: true,
        });

        response.cookies.set({
            name: "sb-refresh-token",
            value: data.session.refresh_token!,
            path: "/",
            domain: ".picnic.fan",
            secure: process.env.NODE_ENV === "production",
            sameSite: "lax",
            httpOnly: true,
        });

        return response;
    } catch (error) {
        console.error("Unexpected error during OAuth callback:", {
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

export async function POST(
    request: NextRequest,
    context: { params: Promise<Record<string, string | string[] | undefined>> },
): Promise<Response> {
    return handleOAuthCallback(request, context, async (request) => {
        const formData = await request.formData();
        console.log("Form Data:", {
            code: formData.get("code"),
            state: formData.get("state"),
            allFields: Object.fromEntries(formData.entries()),
        });
        return {
            code: formData.get("code") as string | null,
            state: formData.get("state") as string | null,
        };
    });
}
