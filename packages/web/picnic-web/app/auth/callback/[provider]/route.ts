import { NextRequest, NextResponse } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function POST(
    request: NextRequest,
    context: { params: Promise<Record<string, string | string[] | undefined>> },
): Promise<Response> {
    try {
        console.log("OAuth Callback Request:", {
            url: request.url,
            method: request.method,
            headers: Object.fromEntries(request.headers.entries()),
        });

        const params = await context.params;
        const provider = params.provider as string;
        console.log("Provider from params:", provider);

        const formData = await request.formData();
        const code = formData.get("code");
        const state = formData.get("state");

        console.log("OAuth Callback Data:", {
            hasCode: !!code,
            hasState: !!state,
            state: state ? "present" : "missing",
            provider,
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
            stateData = JSON.parse(atob(state as string));
            console.log("Parsed state data:", {
                redirectUrl: stateData.redirect_url,
                provider,
                codeVerifier: stateData.code_verifier,
            });
        } catch (error) {
            console.error("Failed to parse state data:", {
                error,
                state,
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

        const cookieStore = await cookies();
        console.log("Cookie store initialized");

        if (provider === "apple") {
            if (!stateData.code_verifier) {
                console.error("Missing code_verifier for Apple login");
                return NextResponse.redirect(
                    new URL("/login?error=missing_code_verifier", request.url),
                );
            }

            cookieStore.set({
                name: "sb-xtijtefcycoeqludlngc-auth-token-code-verifier",
                value: stateData.code_verifier,
                path: "/",
                secure: process.env.NODE_ENV === "production",
                sameSite: "lax",
                httpOnly: true,
            });

            const flowState = {
                provider: "apple",
                code_verifier: stateData.code_verifier,
                redirect_url: redirectUrl,
                created_at: new Date().toISOString(),
            };

            cookieStore.set({
                name: "sb-xtijtefcycoeqludlngc-auth-token-flow-state",
                value: JSON.stringify(flowState),
                path: "/",
                secure: process.env.NODE_ENV === "production",
                sameSite: "lax",
                httpOnly: true,
            });

            console.log("PKCE flow state set:", {
                provider,
                flowState,
            });
        }

        const supabase = createServerClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
            {
                cookies: {
                    get(name: string) {
                        const cookie = cookieStore.get(name);
                        console.log("Getting cookie:", {
                            name,
                            exists: !!cookie,
                            provider,
                        });
                        return cookie?.value;
                    },
                    set(name: string, value: string, options = {}) {
                        console.log("Setting cookie:", {
                            name,
                            options,
                            provider,
                        });
                        cookieStore.set({
                            name,
                            value,
                            path: "/",
                            secure: process.env.NODE_ENV === "production",
                            sameSite: "lax",
                            httpOnly: true,
                            ...options,
                        });
                    },
                    remove(name: string) {
                        console.log("Removing cookie:", {
                            name,
                            provider,
                        });
                        cookieStore.delete({ name, path: "/" });
                    },
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

        return NextResponse.redirect(new URL(redirectUrl, request.url), 302);
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
