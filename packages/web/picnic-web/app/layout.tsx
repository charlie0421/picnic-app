import { ReactNode } from 'react';

export const metadata = {
  title: 'Picnic',
  description: 'Picnic - Your Social Platform',
};

export default function RootLayout({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <html>
      <head>
        <link rel='manifest' href='/manifest.json' />
        <meta name='msapplication-TileColor' content='#4F46E5' />
        <meta name='theme-color' content='#ffffff' />
      </head>
      <body>{children}</body>
    </html>
  );
} 