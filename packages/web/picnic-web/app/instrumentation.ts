// app/instrumentation.ts
import * as Sentry from '@sentry/nextjs';
import { browserTracingIntegration, replayIntegration } from '@sentry/nextjs';

export function register() {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    release: process.env.SENTRY_RELEASE,
    environment: process.env.NODE_ENV,
    integrations: [
      browserTracingIntegration(),
      replayIntegration(),
    ],
    tracesSampleRate: parseFloat(process.env.NEXT_PUBLIC_SENTRY_TRACE_SAMPLE_RATE || '1.0'),
    replaysSessionSampleRate: parseFloat(process.env.NEXT_PUBLIC_SENTRY_SESSION_SAMPLE_RATE || '1.0'),
    replaysOnErrorSampleRate: parseFloat(process.env.NEXT_PUBLIC_SENTRY_ERROR_SAMPLE_RATE || '1.0'),
  });
}