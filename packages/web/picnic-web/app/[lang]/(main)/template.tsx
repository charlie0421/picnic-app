'use client';

import { NavigationProvider } from '@/contexts/NavigationContext';
import PortalLayout from '@/components/features/PortalLayout';
import { useLanguageStore } from '@/stores/languageStore';
import { useEffect } from 'react';
import { Analytics } from '@vercel/analytics/react';
import { injectSpeedInsights } from '@vercel/speed-insights';
import { usePathname } from 'next/navigation';

export default function MainTemplate({
    children,
}: {
    children: React.ReactNode;
}) {
    const { loadTranslations } = useLanguageStore();
    const pathname = usePathname();

    useEffect(() => {
        // URL에서 언어 파라미터 가져오기
        const pathSegments = pathname.split('/');
        const lang = pathSegments[1];

        if (lang) {
            loadTranslations(lang);
        }
        if (process.env.NODE_ENV === 'production') {
            injectSpeedInsights();
        }
    }, [pathname, loadTranslations]);

    return (
        <NavigationProvider>
            <PortalLayout>{children}</PortalLayout>
            {process.env.NODE_ENV === 'production' && <Analytics />}
        </NavigationProvider>
    );
} 