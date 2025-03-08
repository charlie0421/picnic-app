import React from 'react';
import Head from 'next/head';

export default function Home() {
  return (
    <div>
      <Head>
        <title>TTJA Next.js 사이드바</title>
        <meta name='description' content='TTJA 앱을 위한 Next.js 사이드바' />
        <link rel='icon' href='/favicon.ico' />
      </Head>

      <main>
        <h1>TTJA Next.js 사이드바</h1>
        <p>이 페이지는 독립적으로 실행될 때 보이는 페이지입니다.</p>
      </main>
    </div>
  );
}
