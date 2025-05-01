import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const code = formData.get('code');
    const state = formData.get('state');

    if (!code || !state) {
      return NextResponse.redirect(new URL('/?error=missing_params', request.url), 302);
    }

    const stateData = JSON.parse(atob(state as string));
    const redirectUrl = stateData.redirect_url || '/';

    const cookieStore = await cookies();

    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          get(name: string) {
            return cookieStore.get(name)?.value;
          },
          set(name: string, value: string, options = {}) {
            cookieStore.set({
              name,
              value,
              path: '/',
              secure: process.env.NODE_ENV === 'production',
              sameSite: 'lax',
              httpOnly: true,
              ...options,
            });
          },
          remove(name: string) {
            cookieStore.delete({ name, path: '/' });
          },
        },
      }
    );

    const { data, error } = await supabase.auth.exchangeCodeForSession(code as string);

    if (error || !data.session) {
      console.error('OAuth session exchange error:', error);
      return NextResponse.redirect(new URL('/?error=oauth_error', request.url), 302);
    }

    return NextResponse.redirect(new URL(redirectUrl, request.url), 302);

  } catch (error) {
    console.error('Unexpected error during OAuth callback:', error);
    return NextResponse.redirect(new URL('/?error=callback_error', request.url), 302);
  }
}