import { NextRequest, NextResponse } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function POST(
    request: NextRequest,
    context: { params: Promise<Record<string, string | string[] | undefined>> },
): Promise<Response> {
    try {
        const params = await context.params;
        const provider = params.provider as string;
        const formData = await request.formData();
        const code = formData.get("code");
        const state = formData.get("state");

        if (!code || !state) {
            return NextResponse.redirect(
                new URL("/login?error=missing_params", request.url),
            );
        }

        if (!code) {
            return NextResponse.redirect(
                new URL("/login?error=no_code", request.url),
            );
        }

        const redirectUrl = `/auth/callback/${provider}?code=${
            encodeURIComponent(
                code as string,
            )
        }&state=${encodeURIComponent(state as string)}`;

        return NextResponse.redirect(new URL(redirectUrl, request.url));
    } catch (error) {
        console.error("Unexpected error during OAuth callback:", error);
        return NextResponse.redirect(
            new URL("/?error=callback_error", request.url),
            302,
        );
    }
}
