// app/global-error.tsx
'use client';

import * as Sentry from '@sentry/nextjs';
import { useEffect } from 'react';

export default function GlobalError({ error, reset }: { error: Error; reset: () => void }) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html>
      <body>
        <h2>⚠️ 오류가 발생했습니다</h2>
        <button onClick={() => reset()}>다시 시도</button>
      </body>
    </html>
  );
}