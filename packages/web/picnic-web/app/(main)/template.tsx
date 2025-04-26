'use client';

import { NavigationProvider } from '@/contexts/NavigationContext';
import Portal from '@/components/features/Portal';
import { useLanguageStore } from '@/stores/languageStore';
import { useEffect } from 'react';
import { Analytics } from '@vercel/analytics/react';
import { injectSpeedInsights } from '@vercel/speed-insights';

export default function MainTemplate({
    children,
}: {
    children: React.ReactNode;
}) {
    const { loadTranslations } = useLanguageStore();

    useEffect(() => {
        loadTranslations();
        injectSpeedInsights();
    }, [loadTranslations]);

    return (
        <NavigationProvider>
            <Portal>{children}</Portal>
            <Analytics />
        </NavigationProvider>
    );
} 