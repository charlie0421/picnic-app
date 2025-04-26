'use client';

import AuthWrapper from './providers/AuthWrapper';
import NavigationWrapper from './providers/NavigationWrapper';
import LanguageWrapper from './providers/LanguageWrapper';

export default function ClientProviders({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <LanguageWrapper>
      <AuthWrapper>
        <NavigationWrapper>{children}</NavigationWrapper>
      </AuthWrapper>
    </LanguageWrapper>
  );
} 