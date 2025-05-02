import { NextRequest, NextResponse } from "next/server";

export async function POST(
    request: NextRequest,
    { params }: { params: { provider: string } },
) {
    const { provider } = params;

    const formData = await request.formData();
    const code = formData.get("code");
    const state = formData.get("state");

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
}
